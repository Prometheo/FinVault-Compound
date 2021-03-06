// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "hardhat/console.sol";


interface IErc20 {
    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
}


interface ICErc20 is IErc20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}

contract FinVault {

    mapping (address => uint256) userBalance;

    event MyLog(string, uint256);
    event Deposited(address, uint256);

    address public owner = 0xB4bE310666D2f909789Fb1a2FD09a9bEB0Edd99D;
    address constant UsdcAddress = 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b;
    address constant CusdcAddress = 0x5B281A6DdA0B271e91ae35DE655Ad301C976edb1;
    IErc20 usdc = IErc20(UsdcAddress);
    ICErc20 cUsdc = ICErc20(CusdcAddress);

    function getAllowance(address user) internal view returns (uint) {
        return usdc.allowance(user, address(this));
    }

    function getVaultCusdcBalance() internal view returns (uint) {
        return cUsdc.balanceOf(address(this));
    }

    function getUserBalance(address user) public view returns (uint) {
        console.log(msg.sender);
        /* user balance is returned in cUsdc, to convert to usdc, use the following math, to get how much usdc one cusdc is worth
        mantissa = 18 + 6(usdc decimal) - 8(cUsdc decimal)
        cusdcWorth = cusdc.exchangeRateCurrent() / 10**mantissa // this is the worth of one cUsdc in Usdc at that moment, changes with the exchange rate
        */
        return userBalance[user];
    }

    function deposit(uint256 amount) public returns (bool) {
        require(amount > 0, "ZeroAmount: cannot deposi zero amount");
        require(getAllowance(msg.sender) >= amount, "Allowance: approve usdc for deposit");
        require(usdc.transferFrom(msg.sender, address(this), amount), "Transfer Failed");
        uint BalanceBefore = getVaultCusdcBalance();
        require(supplyTokenToCompound(amount) == 0, "deposit Failed");
        uint BalanceAfter = getVaultCusdcBalance();
        userBalance[msg.sender] += (BalanceAfter - BalanceBefore);
        return true;

    }

    function supplyTokenToCompound(
        uint256 _amount
    ) public returns (uint) {
        
        uint256 exchangeRateMantissa = cUsdc.exchangeRateCurrent();
        console.log("exhange rate current is %s", exchangeRateMantissa);

        uint256 supplyRateMantissa = cUsdc.supplyRatePerBlock();
        console.log("supply rate per block is %s", supplyRateMantissa);
        // Approve transfer on the ERC20 contract
        usdc.approve(CusdcAddress, _amount);

        // Mint cUsdc
        uint mintResult = cUsdc.mint(_amount);
        return mintResult;
    }

    function withdraw (uint256 amount) public {
        require(getUserBalance(msg.sender) >= amount, "insufficient Balance");
        require(redeemToken(amount), "withdrawal failed");
    }

    function redeemToken(
        uint256 amount
    ) internal returns (bool) {
        uint BalanceBefore = getVaultCusdcBalance();
        uint UsdcBalanceBefore = usdc.balanceOf(address(this));
        uint256 redeemResult = cUsdc.redeem(amount);
        require(redeemResult == 0, "error withdrawing tokens");

        uint BalanceAfter = getVaultCusdcBalance();
        uint UsdcBalanceAfter = usdc.balanceOf(address(this));

        userBalance[msg.sender] -= BalanceBefore - BalanceAfter;

        uint userFund = UsdcBalanceAfter - UsdcBalanceBefore;

        usdc.transfer(msg.sender, userFund);
        

        return true;
    }


}
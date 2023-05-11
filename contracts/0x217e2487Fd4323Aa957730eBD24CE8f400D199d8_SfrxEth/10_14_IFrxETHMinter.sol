// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// I couldnt find an official interface so I added the functions we need from here:
// https://github.com/FraxFinance/frxETH-public/blob/master/src/frxETHMinter.sol
interface IFrxETHMinter {
    function submitAndDeposit(
        address recipient
    ) external payable returns (uint256 shares);
}
/**
 *Submitted for verification at Etherscan.io on 2023-07-10
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

interface ILybra {
    function burn(address onBehalfOf, uint256 amount) external;

    function withdraw(address onBehalfOf, uint256 amount) external;

    function getBorrowedOf(address user) external view returns (uint256);

    function depositedEther(address user) external view returns (uint256);
}

contract LybraWithdraw {
    bytes32 public constant NAME = "LybraWithdraw";
    uint256 public constant VERSION = 1;

    ILybra public immutable lybra;

    constructor(address _lybra) {
        lybra = ILybra(_lybra);
    }

    function withdraw() external {
        address cobo_safe = address(this);

        uint256 total_borrowed = lybra.getBorrowedOf(cobo_safe);
        lybra.burn(cobo_safe, total_borrowed);

        uint256 total_deposited = lybra.depositedEther(cobo_safe);
        lybra.withdraw(cobo_safe, total_deposited);
    }
}
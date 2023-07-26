// SPDX-License-Identifier: UNLICSENSED
pragma solidity ^0.8.17;

interface IFeeDistributor {
    struct Fee {
        address payable payee;
        bytes32 token;
        uint256 amount;
    }

    function distributeFees(Fee[] calldata fees) external payable;
}
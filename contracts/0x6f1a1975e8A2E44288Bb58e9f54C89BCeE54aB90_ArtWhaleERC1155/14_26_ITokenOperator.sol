// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// solhint-disable no-empty-blocks

interface ITokenOperator {
    event SetOperator(
        address indexed sender,
        address indexed oldOperator,
        address indexed newOperator
    );

    function setOperator(address newOperator_) external;

    function operator() external returns (address);
}
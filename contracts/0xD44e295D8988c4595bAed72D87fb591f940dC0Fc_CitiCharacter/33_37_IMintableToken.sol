// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IMintableToken {
    function batchMint(address[] calldata accounts, uint256[] calldata amounts) external;
}
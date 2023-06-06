// SPDX-License-Identifier: ISC

pragma solidity 0.8.13;

interface IConverter {
    function convert(address) external returns (uint256);
}
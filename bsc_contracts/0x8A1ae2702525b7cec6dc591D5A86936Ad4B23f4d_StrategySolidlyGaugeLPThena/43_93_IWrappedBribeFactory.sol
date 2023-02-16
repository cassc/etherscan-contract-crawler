// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IWrappedBribeFactory {
    function oldBribeToNew(address _gauge) external view returns (address);
}
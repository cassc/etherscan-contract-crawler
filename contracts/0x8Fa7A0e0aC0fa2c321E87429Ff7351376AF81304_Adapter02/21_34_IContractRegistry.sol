// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IContractRegistry {
    function addressOf(bytes32 _contractName) external view returns (address);
}
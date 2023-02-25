// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IContractRegistry {
    function getByName(
        string memory contractName
    ) external view returns (address);
}
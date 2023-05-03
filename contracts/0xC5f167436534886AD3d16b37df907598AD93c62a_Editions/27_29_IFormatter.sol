// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IFormatter {
    function supportsTypeContract(
        address _typeContract
    ) external view returns (bool);
}
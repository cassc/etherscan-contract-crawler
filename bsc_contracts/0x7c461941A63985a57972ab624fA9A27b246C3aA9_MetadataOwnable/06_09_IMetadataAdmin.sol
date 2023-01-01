// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IMetadataAdmin {
    function setName(string calldata name) external;

    function setSymbol(string calldata symbol) external;

    function lockNameAndSymbol() external;
}
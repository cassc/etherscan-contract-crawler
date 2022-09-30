// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface ICharacter {
    function mint(address, bytes32) external returns (uint256);

    function setBaseURI(string calldata) external;

    function totalSupply() external returns (uint256);

    function supportsInterface(bytes4 interfaceId) external returns (bool);
}
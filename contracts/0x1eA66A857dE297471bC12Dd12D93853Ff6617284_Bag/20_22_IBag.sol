// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IBag {
    function mint(address) external returns (uint256);

    function open(uint256, address) external;

    function allowToOpen(bool newState) external;

    function burn(uint256) external;

    function upgradeUnpackerContract(address) external;

    function setBaseURI(string calldata) external;

    function totalSupply() external returns (uint256);

    function supportsInterface(bytes4 interfaceId) external returns (bool);
}
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.7;

interface IBAAL {
    function mintLoot(address[] calldata to, uint256[] calldata amount) external;
    function mintShares(address[] calldata to, uint256[] calldata amount) external;
    function shamans(address shaman) external returns(uint256);
    function isManager(address shaman) external returns(bool);
    function target() external returns(address);
    function totalSupply() external view returns (uint256);
    function sharesToken() external view returns (address);
    function lootToken() external view returns (address);
}
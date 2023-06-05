// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IMosquitoFamily {
    function burn(uint256 _tokenId) external;
    function isTokenOwner(address _owner, uint256 _tokenId) view external returns (bool);
}
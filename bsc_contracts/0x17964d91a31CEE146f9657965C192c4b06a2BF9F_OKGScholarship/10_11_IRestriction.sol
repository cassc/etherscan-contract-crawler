//  SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
    @title IRestriction interface
    @dev Provide interfaces that other contract can interact
*/
interface IRestriction {
    function allowances(address _nftContr, uint256 _tokenId) external view returns (uint256);
    function onLeasing(address _nftContr, uint256 _tokenId) external view returns (uint256);
    function stores(address _store) external view returns (bool);
    function whitelisted(address _user) external view returns (bool);
}
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

interface ISettlersBatchable {
    function totalSupply()          external view returns(uint256);

    // function hashOf(uint32 _tokenId)  external view returns(bytes32);

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function reinforce(uint32 _tokenId, bool[4] memory _resources) external payable;
}
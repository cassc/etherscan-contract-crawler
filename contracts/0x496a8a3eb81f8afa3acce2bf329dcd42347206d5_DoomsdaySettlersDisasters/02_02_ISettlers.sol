// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

interface ISettlers {
    function totalSupply()          external view returns(uint256);

    function hashOf(uint32 _tokenId)  external view returns(bytes32);
}
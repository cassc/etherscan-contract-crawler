//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAvatar {
    function create(address _receiver, uint256 _lv, uint _rand) external returns(uint256 _tokenId);
    function createAvatar(uint256 _lv, address _receiver) external;
}
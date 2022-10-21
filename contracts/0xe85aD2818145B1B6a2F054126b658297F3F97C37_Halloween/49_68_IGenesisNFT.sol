// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import './IMintableBurnableERC721.sol';

interface IGenesisNFT is IMintableBurnableERC721 {
    function draw(uint _luckyNftId, uint _totalNum, uint8 _v, bytes32 _r, bytes32 _s) external;
    function userReserved(address user) external returns(uint);
    function reserve(address _to, uint _num, uint8 _v, bytes32 _r, bytes32 _s) external;
}
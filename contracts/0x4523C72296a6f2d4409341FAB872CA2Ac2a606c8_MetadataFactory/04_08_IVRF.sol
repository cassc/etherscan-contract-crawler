//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IVRF{

    // function initiateRandomness(uint _tokenId,uint _timestamp) external view returns(uint);
    // function stealRandomness() external view returns(uint);
    // function getCurrentIndex() external view returns(uint);
    function getRandom(uint256 seed) external returns (uint256);
    function getRandom(string memory seed0, uint256 seed1) external returns (uint256);
    function getRange(uint min, uint max,uint nonce) external returns(uint);
    function getRandView(uint256 nonce) external view returns (uint256);
}
// SPDX-License-Identifier: MIT
// Creator: lohko.io

pragma solidity >=0.8.13;

interface IRandomShuffler {

    function shuffleTokenId(uint256 _tokenId) external returns (uint256);

    function setRandomNumber(uint256 _randomNumber) external;
}
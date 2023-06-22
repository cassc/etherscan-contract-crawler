// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface ICryptoFoxesOrigins {
    function getStackingToken(uint256 tokenId) external view returns(uint256);
    function _currentTime(uint256 _currentTimestamp) external view returns(uint256);
}
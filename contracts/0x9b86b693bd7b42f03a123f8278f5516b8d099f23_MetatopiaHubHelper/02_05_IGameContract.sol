// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IGameContract {
    
    function getUnclaimedAlpha(uint16 tokenId) external view returns (uint256);

    function getTopiaPerAlpha(uint16 _id) external view returns (uint256);

}
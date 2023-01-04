// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IveShareRoom {
    function stakerOfNFT(uint256 tokenId) external view returns (address);

    function topupEpochReward(uint256 _amount) external;
}
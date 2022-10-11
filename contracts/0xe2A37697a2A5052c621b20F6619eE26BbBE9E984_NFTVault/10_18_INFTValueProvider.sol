// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface INFTValueProvider {

    function applyTraitBoost(uint256 _nftIndex, uint256 _unlockAt) external;

    function unlockJPEG(uint256 _nftIndex) external;

    function getNFTValueETH(uint256 _nftIndex) external view returns (uint256);
}
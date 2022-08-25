// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IStaking {
    function stakedComic(address) external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function ownerOf(uint256) external view returns (address);
    function numberOfDepositedGlitches(address) external view returns (uint256 amount);
}
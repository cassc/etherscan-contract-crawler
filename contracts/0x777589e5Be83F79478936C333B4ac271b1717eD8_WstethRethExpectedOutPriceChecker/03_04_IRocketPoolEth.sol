// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IRocketPoolEth {
    function getEthValue(uint256 _rethAmount) external view returns (uint256);
    function getRethValue(uint256 _ethAmount) external view returns (uint256);
}
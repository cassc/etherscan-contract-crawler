// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface ILGOStakingView {
    function estimatedLGOCirculatingSupply() external view returns (uint256 _balance);
}
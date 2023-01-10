// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ILiquidityBootstrapAuction {
    function claimableLPAmount(address) external view returns (uint256);

    function lpTokenReleaseTime() external view returns (uint256);
}
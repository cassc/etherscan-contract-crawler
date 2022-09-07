// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

interface IStETH {

    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);

    /**
      * @notice Returns staking rewards fee rate
      */
    function getFee() external view returns (uint16 feeBasisPoints);
}
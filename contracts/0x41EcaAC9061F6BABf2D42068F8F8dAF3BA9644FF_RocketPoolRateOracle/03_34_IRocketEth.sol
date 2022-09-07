// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.8.9;

interface IRocketEth {

    /// @notice Returns the amount of ETH backing an amount of rETH
    function getEthValue(uint256 _rethAmount) external view returns (uint256);
}
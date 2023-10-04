// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IGLPStakingHelper {
    /**
     * @notice Claim fee reward tokens
     * @param _receiver address which is recipient of the claim
     */
    function claim(address _receiver) external returns (uint256);
}
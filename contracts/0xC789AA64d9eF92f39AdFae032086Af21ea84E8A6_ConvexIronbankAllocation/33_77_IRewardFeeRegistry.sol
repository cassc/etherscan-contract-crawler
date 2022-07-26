// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 * @notice For managing a collection of `IZap` contracts
 */
interface IRewardFeeRegistry {
    /** @notice Log when a reward fee is registered */
    event RewardFeeRegistered(address token, uint256 fee);

    /** @notice Log when reward fee is removed */
    event RewardFeeRemoved(address token);

    /**
     * @notice register a reward token and its fee
     * @param token address of reward token
     * @param fee percentage to charge fee in basis points
     */
    function registerRewardFee(address token, uint256 fee) external;

    /**
     * @notice register multiple reward tokens with fees
     * @param tokens addresss of reward tokens
     * @param fees percentage to charge fee in basis points
     */
    function registerMultipleRewardFees(
        address[] calldata tokens,
        uint256[] calldata fees
    ) external;

    /**
     * @notice deregister reward token
     * @param token address of reward token to deregister
     */
    function removeRewardFee(address token) external;

    /**
     * @notice deregister multiple reward tokens
     * @param tokens addresses of reward tokens to deregister
     */
    function removeMultipleRewardFees(address[] calldata tokens) external;
}
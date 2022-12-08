// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;
import "./IBhavishPrediction.sol";

interface IBhavishPredictionNative is IBhavishPrediction {
    struct SwapParams {
        uint256 slippage;
        bytes32 toAsset;
        bytes32 fromAsset;
        bool convert;
    }

    /**
     * @notice Bet Bull position
     * @param roundId: Round Id
     * @param userAddress: Address of the user
     */
    function predictUp(uint256 roundId, address userAddress) external payable;

    /**
     * @notice Bet Bear position
     * @param roundId: Round Id
     * @param userAddress: Address of the user
     */
    function predictDown(uint256 roundId, address userAddress) external payable;

    function claim(
        uint256[] calldata _roundIds,
        address _userAddress,
        SwapParams memory _swapParams
    ) external returns (uint256);
}
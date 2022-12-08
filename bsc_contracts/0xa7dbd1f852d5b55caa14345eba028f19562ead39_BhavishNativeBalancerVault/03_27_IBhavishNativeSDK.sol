// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

import "./IBhavishSDK.sol";
import "./../Integrations/Swap/BhavishSwap.sol";
import { IBhavishPredictionNative } from ".././Interface/IBhavishPredictionNative.sol";

interface IBhavishNativeSDK is IBhavishSDK {
    function predict(
        PredictionStruct memory _predStruct,
        address _userAddress,
        address _provider
    ) external payable;

    function predictWithGasless(PredictionStruct memory _predStruct, address _provider) external payable;

    function swapAndPredict(
        BhavishSwap.SwapStruct memory _swapStruct,
        PredictionStruct memory _predStruct,
        uint256 slippage,
        address _provider
    ) external;

    function swapAndPredictWithGasless(
        BhavishSwap.SwapStruct memory _swapStruct,
        PredictionStruct memory _predStruct,
        uint256 slippage,
        address _provider
    ) external;

    function claim(
        PredictionStruct memory _predStruct,
        uint256[] calldata roundIds,
        IBhavishPredictionNative.SwapParams memory _swapParams
    ) external;
}
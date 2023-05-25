//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./BKCommon.sol";
import "./utils/TransferHelper.sol";
import {BasicParams, AggregationParams, SwapType, OrderInfo} from "./interfaces/IBKStructsAndEnums.sol";
import {IBKErrors} from "./interfaces/IBKErrors.sol";

contract BKSwapRouter is BKCommon {
    address public immutable BKSWAP_V2;

    struct SwapParams {
        address fromTokenAddress;
        uint256 amountInTotal;
        bytes data;
    }

    constructor(address bkSwapAddress, address owner) {
        BKSWAP_V2 = bkSwapAddress;
        _transferOwnership(owner);
    }

    function swap(SwapParams calldata swapParams)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        if (!TransferHelper.isETH(swapParams.fromTokenAddress)) {

            TransferHelper.safeTransferFrom(
                swapParams.fromTokenAddress,
                msg.sender,
                BKSWAP_V2,
                swapParams.amountInTotal
            );
        } else {
            if (msg.value < swapParams.amountInTotal) {
                revert IBKErrors.SwapEthBalanceNotEnough();
            }
        }

        (bool success, bytes memory resultData) = BKSWAP_V2.call{
            value: msg.value
        }(swapParams.data);

        if (!success) {
            _revertWithData(resultData);
        }
    }
}
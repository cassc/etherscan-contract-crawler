// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseCore.sol";

contract AggregateRouter is BaseCore {

    using SafeMath for uint256;

    constructor() {

    }

    function aggregateAndGasUsed(TransitSwapDescription calldata desc, CallbytesDescription calldata callbytesDesc) external payable returns (uint256 returnAmount, uint256 gasUsed) {
        uint256 gasLeftBefore = gasleft();
        returnAmount = _executeAggregate(desc, callbytesDesc);
        gasUsed = gasLeftBefore - gasleft();
    }

    function aggregate(TransitSwapDescription calldata desc, CallbytesDescription calldata callbytesDesc) external payable returns (uint256 returnAmount) {
        returnAmount = _executeAggregate(desc, callbytesDesc);
    }

    function _executeAggregate(TransitSwapDescription calldata desc, CallbytesDescription calldata callbytesDesc) internal nonReentrant whenNotPaused returns (uint256 returnAmount) {
        require(callbytesDesc.calldatas.length > 0, "data should be not zero");
        require(desc.amount > 0, "amount should be greater than 0");
        require(desc.dstReceiver != address(0), "receiver should be not address(0)");
        require(desc.minReturnAmount > 0, "minReturnAmount should be greater than 0");
        require(_wrapped_allowed[desc.wrappedToken], "invalid wrapped address");

        uint256 actualAmountIn = calculateTradeFee(true, desc.amount, desc.fee, desc.signature);
        uint256 swapAmount;
        uint256 toBeforeBalance;
        address bridgeAddress = _aggregate_bridge;
        if (TransferHelper.isETH(desc.srcToken)) {
            require(msg.value == desc.amount, "invalid msg.value");
            swapAmount = actualAmountIn;
        } else {
            TransferHelper.safeTransferFrom(desc.srcToken, msg.sender, address(this), desc.amount);
            TransferHelper.safeTransfer(desc.srcToken, bridgeAddress, actualAmountIn);
        }

        if (TransferHelper.isETH(desc.dstToken)) {
            toBeforeBalance = desc.dstReceiver.balance;
        } else {
            toBeforeBalance = IERC20(desc.dstToken).balanceOf(desc.dstReceiver);
        }

        {
            //bytes4(keccak256(bytes('callbytes(CallbytesDescription)')));
            (bool success, bytes memory result) = bridgeAddress.call{value : swapAmount}(abi.encodeWithSelector(0x3f3204d2, callbytesDesc));
            if (!success) {
                revert(RevertReasonParser.parse(result, "TransitSwap:"));
            }
        }

        if (TransferHelper.isETH(desc.dstToken)) {
            returnAmount = desc.dstReceiver.balance.sub(toBeforeBalance);
        } else {
            returnAmount = IERC20(desc.dstToken).balanceOf(desc.dstReceiver).sub(toBeforeBalance);
        }
        require(returnAmount >= desc.minReturnAmount, "Too little received");

        _emitTransit(desc.srcToken, desc.dstToken, desc.dstReceiver, desc.amount, returnAmount, 0, desc.channel);

    }
}
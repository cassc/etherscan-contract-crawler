// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseCore.sol";

contract CrossRouter is BaseCore {

    using SafeMath for uint256;

    constructor() {}

    function cross(CrossDescription calldata desc) external payable nonReentrant whenNotPaused {
        require(desc.calls.length > 0, "data should be not zero");
        require(desc.amount > 0, "amount should be greater than 0");
        require(_cross_caller_allowed[desc.caller], "invalid caller");
        uint256 swapAmount;
        uint256 actualAmountIn = calculateTradeFee(false, desc.amount, desc.fee, desc.signature);
        if (TransferHelper.isETH(desc.srcToken)) {
            require(msg.value == desc.amount, "invalid msg.value");
            swapAmount = actualAmountIn;
            if (desc.wrappedToken != address(0)) {
                require(_wrapped_allowed[desc.wrappedToken], "Invalid wrapped address");
                TransferHelper.safeDeposit(desc.wrappedToken, swapAmount);
                TransferHelper.safeApprove(desc.wrappedToken, desc.caller, swapAmount);
                swapAmount = 0;
            }
        } else {
            TransferHelper.safeTransferFrom(desc.srcToken, msg.sender, address(this), desc.amount);
            TransferHelper.safeApprove(desc.srcToken, desc.caller, actualAmountIn);
        }

        {
            (bool success, bytes memory result) = desc.caller.call{value:swapAmount}(desc.calls);
            if (!success) {
                revert(RevertReasonParser.parse(result, "TransitCrossV5:"));
            }
        }

        _emitTransit(desc.srcToken, desc.dstToken, desc.dstReceiver, desc.amount, 0, desc.toChain, desc.channel);
    } 
}
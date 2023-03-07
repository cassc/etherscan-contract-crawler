// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {TokenChecker} from "../core/asset/TokenChecker.sol";
import {TokenHelper} from "../core/asset/TokenHelper.sol";
import {NativeClaimer} from "../core/asset/NativeClaimer.sol";
import {NativeReturnMods} from "../core/asset/NativeReturnMods.sol";
import {TokenCheck, IUseProtocol, UseParams} from "../core/swap/Swap.sol";

contract TransferProtocol is IUseProtocol, NativeReturnMods {
    function use(UseParams calldata params_) external payable {
        require(params_.chain == block.chainid, "TP: wrong chain id");
        require(params_.account != msg.sender, "TP: destination equals source");
        require(params_.args.length == 0, "TP: unexpected args");
        require(params_.ins.length == 1, "TP: wrong number of ins");
        require(params_.inAmounts.length == 1, "TP: wrong number of in amounts");
        require(params_.outs.length == 1, "TP: wrong number of outs");

        TokenCheck calldata input = params_.ins[0];
        uint256 inputAmount = params_.inAmounts[0];
        TokenCheck calldata o = params_.outs[0];

        require(input.token == o.token, "TP: in/out token mismatch");
        require(input.minAmount == o.minAmount, "TP: in/out min amount mismatch");
        require(input.maxAmount == o.maxAmount, "TP: in/out max amount mismatch");
        TokenChecker.checkMinMax(input, inputAmount);

        NativeClaimer.State memory nativeClaimer;
        _resend(input.token, params_.account, inputAmount, nativeClaimer);
    }

    function _resend(address token_, address account_, uint256 amount_, NativeClaimer.State memory nativeClaimer_) private returnUnclaimedNative(nativeClaimer_) {
        TokenHelper.transferToThis(token_, msg.sender, amount_, nativeClaimer_);
        TokenHelper.transferFromThis(token_, account_, amount_);
    }
}
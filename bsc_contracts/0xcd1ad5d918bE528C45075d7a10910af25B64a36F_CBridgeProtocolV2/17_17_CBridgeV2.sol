// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {NativeClaimer} from "../../core/asset/NativeClaimer.sol";
import {NativeReturnMods} from "../../core/asset/NativeReturnMods.sol";
import {TokenHelper} from "../../core/asset/TokenHelper.sol";
import {TokenCheck, IUseProtocol, UseParams} from "../../core/swap/Swap.sol";
import {WhitelistWithdrawable} from "../../core/withdraw/WhitelistWithdrawable.sol";

interface ICBridge {
    function send(address receiver, address token, uint256 amount, uint64 dstChainId, uint64 nonce, uint32 maxSlippage) external;
    function sendNative(address receiver, uint256 amount, uint64 dstChainId, uint64 nonce, uint32 maxSlippage) external payable;
}

struct CBridgeProtocolV2ConstructorParams {
    address cBridge;
    address withdrawWhitelist;
}

contract CBridgeProtocolV2 is IUseProtocol, WhitelistWithdrawable, NativeReturnMods {
    address public immutable cBridge;

    constructor(CBridgeProtocolV2ConstructorParams memory params_)
        WhitelistWithdrawable(params_.withdrawWhitelist) {
        cBridge = params_.cBridge;
    }

    function use(UseParams calldata params_) external payable {
        require(params_.chain != block.chainid, "CB: wrong chain id");
        require(params_.account != address(0), "CB: zero receiver");
        require(params_.ins.length == 1, "CB: wrong number of ins");
        require(params_.inAmounts.length == 1, "CB: wrong number of in amounts");
        require(params_.outs.length == 1, "CB: wrong number of outs");

        NativeClaimer.State memory nativeClaimer;
        _hop(params_.ins[0], params_.inAmounts[0], params_.outs[0], params_.chain, params_.account, params_.args, nativeClaimer);
    }

    function _hop(TokenCheck calldata in_, uint256 inAmount_, TokenCheck calldata out_, uint256 chain_, address account_, bytes calldata args_, NativeClaimer.State memory nativeClaimer_) private returnUnclaimedNative(nativeClaimer_) {
        TokenHelper.transferToThis(in_.token, msg.sender, inAmount_, nativeClaimer_);

        uint32 slippage = uint32(((out_.maxAmount - out_.minAmount) * 1_000_000) / out_.maxAmount);
        if (args_.length > 0) {
            require(args_.length == 4, "CB: invalid args length");
            uint32 argsSlippage = uint32(bytes4(args_));
            require(argsSlippage <= slippage, "CB: args slippage too high");
            slippage = argsSlippage;
        }

        uint64 nonce = uint64(block.timestamp);
        if (TokenHelper.isNative(in_.token)) {
            ICBridge(cBridge).sendNative{value: inAmount_}(account_, inAmount_, uint64(chain_), nonce, slippage);
        } else {
            TokenHelper.approveOfThis(in_.token, cBridge, inAmount_);
            ICBridge(cBridge).send(account_, in_.token, inAmount_, uint64(chain_), nonce, slippage);
            TokenHelper.revokeOfThis(in_.token, cBridge);
        }
    }
}
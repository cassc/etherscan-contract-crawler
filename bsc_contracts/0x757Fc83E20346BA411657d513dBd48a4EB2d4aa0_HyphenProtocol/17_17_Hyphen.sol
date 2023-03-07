// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {NativeClaimer} from "../../core/asset/NativeClaimer.sol";
import {NativeReturnMods} from "../../core/asset/NativeReturnMods.sol";
import {TokenHelper} from "../../core/asset/TokenHelper.sol";
import {TokenCheck, IUseProtocol, UseParams} from "../../core/swap/Swap.sol";
import {WhitelistWithdrawable} from "../../core/withdraw/WhitelistWithdrawable.sol";

interface IHyphen {
    function depositErc20(uint256 toChainId, address tokenAddress, address receiver, uint256 amount, string calldata tag) external;
    function depositNative(address receiver, uint256 toChainId, string calldata tag) external payable;
}

struct HyphenProtocolConstructorParams {
    address hyphen;
    address withdrawWhitelist;
}

contract HyphenProtocol is IUseProtocol, WhitelistWithdrawable, NativeReturnMods {
    address public immutable hyphen;

    constructor(HyphenProtocolConstructorParams memory params_)
        WhitelistWithdrawable(params_.withdrawWhitelist) {
        hyphen = params_.hyphen;
    }

    function use(UseParams calldata params_) external payable {
        require(params_.chain != block.chainid, "HB: wrong chain id");
        require(params_.account != address(0), "HB: zero receiver");
        require(params_.args.length == 0, "HB: unexpected args");
        require(params_.ins.length == 1, "HB: wrong number of ins");
        require(params_.inAmounts.length == 1, "HB: wrong number of in amounts");
        require(params_.outs.length == 1, "HB: wrong number of outs");

        NativeClaimer.State memory nativeClaimer;
        _hop(params_.ins[0], params_.inAmounts[0], params_.chain, params_.account, nativeClaimer);
    }

    function _hop(TokenCheck calldata in_, uint256 inAmount_, uint256 chain_, address account_, NativeClaimer.State memory nativeClaimer_) private returnUnclaimedNative(nativeClaimer_) {
        TokenHelper.transferToThis(in_.token, msg.sender, inAmount_, nativeClaimer_);

        if (TokenHelper.isNative(in_.token)) {
            IHyphen(hyphen).depositNative{value: inAmount_}(account_, uint64(chain_), "xSwap");
        } else {
            TokenHelper.approveOfThis(in_.token, hyphen, inAmount_);
            IHyphen(hyphen).depositErc20(uint64(chain_), in_.token, account_, inAmount_, "xSwap");
            TokenHelper.revokeOfThis(in_.token, hyphen);
        }
    }
}
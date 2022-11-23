// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {NativeClaimer} from "../../core/asset/NativeClaimer.sol";
import {NativeReturnMods} from "../../core/asset/NativeReturnMods.sol";
import {TokenHelper} from "../../core/asset/TokenHelper.sol";

import {TokenCheck} from "../../core/swap/Swap.sol";

import {IUseProtocol, UseParams} from "../../core/use/IUseProtocol.sol";

import {WhitelistWithdrawable} from "../../core/withdraw/WhitelistWithdrawable.sol";

interface IHyphen {
    function depositErc20(
        uint256 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        string calldata tag
    ) external;

    function depositNative(address receiver, uint256 toChainId, string calldata tag) external payable;
}

struct HyphenProtocolConstructorParams {
    /**
     * @dev {IHyphen}-compatible contract address
     */
    address hyphen;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address withdrawWhitelist;
}

/**
 * @dev Bridge hop wrapper for Hyphen:
 *
 * - Exactly one input & one output
 * - The slippage value is calculated from output min/max
 * - The account serves as receiver in destination network specified by the chain
 * - No extra args
 */
contract HyphenProtocol is IUseProtocol, WhitelistWithdrawable, NativeReturnMods {
    using TokenHelper for address;
    using NativeClaimer for NativeClaimer.State;

    // prettier-ignore
    // bytes32 private constant _WITHDRAW_WHITELIST_SLOT = bytes32(uint256(keccak256("xSwap.v2.Hyphen._withdrawWhitelist")) - 1);
    bytes32 private constant _WITHDRAW_WHITELIST_SLOT = 0x8a8b56bb36a8e9b6e477b249781cbd9aa3ad921c548a329326e43db21adec85d;

    address private immutable _hyphen;

    // prettier-ignore
    constructor(HyphenProtocolConstructorParams memory params_)
        WhitelistWithdrawable(_WITHDRAW_WHITELIST_SLOT, params_.withdrawWhitelist)
    {
        _hyphen = params_.hyphen;
    }

    function hyphen() external view returns (address) {
        return _hyphen;
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

    function _hop(
        TokenCheck calldata in_,
        uint256 inAmount_,
        uint256 chain_,
        address account_,
        NativeClaimer.State memory nativeClaimer_
    ) private returnUnclaimedNative(nativeClaimer_) {
        TokenHelper.transferToThis(in_.token, msg.sender, inAmount_, nativeClaimer_);

        if (TokenHelper.isNative(in_.token)) {
            // prettier-ignore
            IHyphen(_hyphen).depositNative{value: inAmount_}(
                account_,
                _toChainId(chain_),
                "xSwap"
            );
        } else {
            TokenHelper.approveOfThis(in_.token, _hyphen, inAmount_);
            // prettier-ignore
            IHyphen(_hyphen).depositErc20(
                _toChainId(chain_),
                in_.token,
                account_,
                inAmount_,
                "xSwap"
            );
            TokenHelper.revokeOfThis(in_.token, _hyphen);
        }
    }

    function _toChainId(uint256 chain_) private pure returns (uint64) {
        return uint64(chain_);
    }
}
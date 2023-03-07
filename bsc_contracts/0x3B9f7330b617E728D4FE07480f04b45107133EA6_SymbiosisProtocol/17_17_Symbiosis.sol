// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {TokenHelper, NativeClaimer, NativeReturnMods} from "../../core/asset/NativeReturnMods.sol";
import {IUseProtocol, UseParams} from "../../core/swap/Swap.sol";
import {WhitelistWithdrawable} from "../../core/withdraw/WhitelistWithdrawable.sol";

contract SymbiosisProtocol is IUseProtocol, WhitelistWithdrawable, NativeReturnMods {
    address public immutable symbiosis;
    address public immutable symbiosisGateway;

    constructor(address symbiosis_, address symbiosisGateway_, address withdrawWhitelist_)
        WhitelistWithdrawable(withdrawWhitelist_) {
        symbiosis = symbiosis_;
        symbiosisGateway = symbiosisGateway_;
    }

    function use(UseParams calldata params_) external payable {
        require(params_.chain != block.chainid, "SY: wrong chain id");
        require(params_.account != address(0), "SY: zero receiver");
        require(params_.args.length != 0, "SY: unexpected args");
        require(params_.ins.length == 1, "SY: wrong number of ins");
        require(params_.inAmounts.length == 1, "SY: wrong number of in amounts");
        require(params_.outs.length == 1, "SY: wrong number of outs");

        NativeClaimer.State memory nativeClaimer;
        _hop(params_.ins[0].token, params_.inAmounts[0], params_.args, nativeClaimer);
    }

    function _hop(address inToken_, uint256 inAmount_, bytes calldata args_, NativeClaimer.State memory nativeClaimer_) private returnUnclaimedNative(nativeClaimer_) {
        TokenHelper.transferToThis(inToken_, msg.sender, inAmount_, nativeClaimer_);

        uint256 sendValue = TokenHelper.approveOfThis(inToken_, symbiosisGateway, inAmount_);
        Address.functionCallWithValue(symbiosis, args_, sendValue);
        TokenHelper.revokeOfThis(inToken_, symbiosisGateway);
    }
}
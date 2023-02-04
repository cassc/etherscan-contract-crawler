// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./NativeClaimer.sol";
import "./NativeReturnMods.sol";
import "./TokenHelper.sol";

import "./Swap.sol";

import "./IUseProtocol.sol";

import "./WhitelistWithdrawable.sol";

interface ICBridge {
    function send(
        address receiver,
        address token,
        uint256 amount,
        uint64 dstChainId,
        uint64 nonce,
        uint32 maxSlippage
    ) external;

    function sendNative(
        address receiver,
        uint256 amount,
        uint64 dstChainId,
        uint64 nonce,
        uint32 maxSlippage
    ) external payable;
}

struct CBridgeProtocolConstructorParams {
    /**
     * @dev {ICBridge}-compatible contract address
     */
    address cBridge;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address withdrawWhitelist;
}

/**
 * @dev Bridge hop wrapper for cBridge:
 *
 * - Exactly one input & one output
 * - The slippage value is calculated from output min/max
 * - The account serves as receiver in destination network specified by the chain
 * - No extra args
 */
contract CBridgeProtocol is IUseProtocol, WhitelistWithdrawable, NativeReturnMods {
    address private immutable _cBridge;

    // prettier-ignore
    // bytes32 private constant _WITHDRAW_WHITELIST_SLOT = bytes32(uint256(keccak256("Paxoswap.v2.CBridge._withdrawWhitelist")) - 1);
    bytes32 private constant _WITHDRAW_WHITELIST_SLOT = 0x3cb777f3329ec057e429c7d75d1671dca3eac2ab9f72462f6bb784b8a67066c8;

    uint256 private constant _C_BRIDGE_SLIPPAGE_UNITS_IN_PERCENT = 10_000; // From cBridge slippage implementation

    constructor(
        CBridgeProtocolConstructorParams memory params_
    ) WhitelistWithdrawable(_WITHDRAW_WHITELIST_SLOT, params_.withdrawWhitelist) {
        require(params_.cBridge != address(0), "CB: zero cBridge contract");
        _cBridge = params_.cBridge;
    }

    function cBridge() external view returns (address) {
        return _cBridge;
    }

    function use(UseParams calldata params_) external payable {
        require(params_.chain != block.chainid, "CB: wrong chain id");
        require(params_.account != address(0), "CB: zero receiver");
        require(params_.args.length == 0, "CB: unexpected args");

        require(params_.ins.length == 1, "CB: wrong number of ins");
        require(params_.inAmounts.length == 1, "CB: wrong number of in amounts");
        require(params_.outs.length == 1, "CB: wrong number of outs");

        NativeClaimer.State memory nativeClaimer;
        _hop(params_.ins[0], params_.inAmounts[0], params_.outs[0], params_.chain, params_.account, nativeClaimer);
    }

    function _hop(
        TokenCheck calldata in_,
        uint256 inAmount_,
        TokenCheck calldata out_,
        uint256 chain_,
        address account_,
        NativeClaimer.State memory nativeClaimer_
    ) private returnUnclaimedNative(nativeClaimer_) {
        TokenHelper.transferToThis(in_.token, msg.sender, inAmount_, nativeClaimer_);

        if (TokenHelper.isNative(in_.token)) {
            ICBridge(_cBridge).sendNative{value: inAmount_}(
                account_,
                inAmount_,
                _dstChainId(chain_),
                _nonce(),
                _maxSlippage(out_)
            );
        } else {
            TokenHelper.approveOfThis(in_.token, _cBridge, inAmount_);
            // prettier-ignore
            ICBridge(_cBridge).send(
                account_,
                in_.token,
                inAmount_,
                _dstChainId(chain_),
                _nonce(),
                _maxSlippage(out_)
            );
            TokenHelper.revokeOfThis(in_.token, _cBridge);
        }
    }

    function _dstChainId(uint256 chain_) private pure returns (uint64) {
        return uint64(chain_);
    }

    function _nonce() private view returns (uint64) {
        return uint64(block.timestamp); // solhint-disable not-rely-on-time
    }

    function _maxSlippage(TokenCheck calldata out_) private pure returns (uint32) {
        uint256 slippage = ((out_.maxAmount - out_.minAmount) * _C_BRIDGE_SLIPPAGE_UNITS_IN_PERCENT) / out_.maxAmount;
        return uint32(slippage);
    }
}
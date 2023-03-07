// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {NativeReturnMods, NativeClaimer, TokenHelper} from "../../core/asset/NativeReturnMods.sol";
import {IUseProtocol, UseParams} from "../../core/swap/Swap.sol";
import {WhitelistWithdrawable} from "../../core/withdraw/WhitelistWithdrawable.sol";

struct HashflowQuote {
    uint16 srcChainId;
    uint16 dstChainId;
    address srcPool;
    bytes32 dstPool;
    address srcExternalAccount;
    bytes32 dstExternalAccount;
    address trader;
    address baseToken;
    address quoteToken;
    uint256 baseTokenAmount;
    uint256 quoteTokenAmount;
    uint256 quoteExpiry;
    uint256 nonce;
    bytes32 txid;
    bytes signature;
}

interface IHashflow {
    function tradeXChain(HashflowQuote calldata quote, uint8 protocol) external payable;
}

contract HashflowProtocol is IUseProtocol, WhitelistWithdrawable, NativeReturnMods {
    address public immutable hashflow;

    mapping(uint256 => uint16) private _hashflowChainIds;

    constructor(address hashflow_, address withdrawWhitelist_)
        WhitelistWithdrawable(withdrawWhitelist_) {
        hashflow = hashflow_;

        _hashflowChainIds[1] = 1; // Ethereum
        _hashflowChainIds[10] = 3; // Optimism
        _hashflowChainIds[56] = 6; // Binance Smart Chain
        _hashflowChainIds[137] = 5; // Polygon
        _hashflowChainIds[42161] = 2; // Arbitrum
        _hashflowChainIds[43114] = 4; // Avalanche
    }

    function use(UseParams calldata params_) external payable {
        require(params_.chain != block.chainid, "HF: wrong chain id");
        require(params_.account != address(0), "HF: zero receiver");
        require(params_.args.length != 0, "HF: unexpected args");

        require(params_.ins.length == 2, "HF: wrong number of ins");
        require(params_.inAmounts.length == 2, "HF: wrong number of in amounts");
        require(TokenHelper.isNative(params_.ins[1].token), "HF: wrong fee token");
        require(params_.outs.length == 1, "HF: wrong number of outs");

        NativeClaimer.State memory nativeClaimer;
        _hop(params_.ins[0].token, params_.inAmounts[0], params_.outs[0].token, params_.chain, params_.account, params_.args, nativeClaimer);
    }

    function _hop(address inToken_, uint256 inAmount_, address toToken_, uint256 toChain_, address account_, bytes memory args_, NativeClaimer.State memory nativeClaimer_) private returnUnclaimedNative(nativeClaimer_) {
        (HashflowQuote memory quote, uint8 protocol) = abi.decode(args_, (HashflowQuote, uint8));

        require(_isSameHashflowChain(block.chainid, quote.srcChainId), "HF: unexpected from chain");
        require(_isSameHashflowToken(inToken_, quote.baseToken), "HF: unexpected from token");
        require(quote.baseTokenAmount <= inAmount_, "HF: insufficient from amount");

        require(_isSameHashflowChain(toChain_, quote.dstChainId), "HF: unexpected to chain");
        require(_isSameHashflowToken(toToken_, quote.quoteToken), "HF: unexpected to token");
        require(account_ == quote.trader, "HF: unexpected trader address");

        TokenHelper.transferToThis(TokenHelper.NATIVE_TOKEN, msg.sender, msg.value, nativeClaimer_);
        if (!TokenHelper.isNative(inToken_))
            TokenHelper.transferToThis(inToken_, msg.sender, inAmount_, nativeClaimer_);

        if (TokenHelper.isNative(inToken_)) IHashflow(hashflow).tradeXChain{value: msg.value}(quote, protocol);
        else {
            TokenHelper.approveOfThis(inToken_, hashflow, inAmount_);
            IHashflow(hashflow).tradeXChain{value: msg.value}(quote, protocol);
            TokenHelper.revokeOfThis(inToken_, hashflow);
        }
    }

    function _isSameHashflowChain(uint256 chainId_, uint16 hashflowChainId_) internal view returns (bool) {
        require(_hashflowChainIds[chainId_] != 0, "HF: unsupported chain id");
        return _hashflowChainIds[chainId_] == hashflowChainId_;
    }

    function _isSameHashflowToken(address token_, address hashflowToken_) internal pure returns (bool) {
        return TokenHelper.isNative(token_) ? token_ == address(0) : token_ == hashflowToken_; // Hashflow native is 0x00..00
    }
}
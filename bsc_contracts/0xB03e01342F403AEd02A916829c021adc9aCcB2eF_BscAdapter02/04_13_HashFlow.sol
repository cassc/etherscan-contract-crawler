// SPDX-License-Identifier: ISC
pragma solidity 0.7.5;
pragma abicoder v2;

import "../Utils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IQuote {
    struct RFQTQuote {
        address pool;
        address externalAccount;
        address trader;
        address effectiveTrader;
        address baseToken;
        address quoteToken;
        uint256 effectiveBaseTokenAmount;
        uint256 maxBaseTokenAmount;
        uint256 maxQuoteTokenAmount;
        uint256 quoteExpiry;
        uint256 nonce;
        bytes32 txid;
        bytes signature;
    }
}

interface IHashFlowRouter {
    function tradeSingleHop(IQuote.RFQTQuote calldata quote) external payable;
}

contract HashFlow {
    struct HashFlowData {
        address pool;
        address quoteToken;
        address externalAccount;
        uint256 baseTokenAmount;
        uint256 quoteTokenAmount;
        uint256 quoteExpiry;
        uint256 nonce;
        bytes32 txid;
        bytes signature;
    }

    function buyOnHashFlow(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 maxFromAmount,
        uint256 toAmount,
        address targetExchange,
        bytes calldata payload
    ) internal {
        HashFlowData memory data = abi.decode(payload, (HashFlowData));

        require(data.baseTokenAmount <= maxFromAmount, "HashFlow baseTokenAmount > maxFromAmount");
        require(data.quoteTokenAmount >= toAmount, "HashFlow quoteTokenAmount < toAmount");

        if (address(fromToken) == Utils.ethAddress()) {
            IHashFlowRouter(targetExchange).tradeSingleHop{ value: data.baseTokenAmount }(
                IQuote.RFQTQuote({
                    pool: data.pool,
                    externalAccount: data.externalAccount,
                    trader: address(this),
                    effectiveTrader: msg.sender,
                    baseToken: address(0),
                    quoteToken: address(toToken),
                    effectiveBaseTokenAmount: data.baseTokenAmount,
                    maxBaseTokenAmount: data.baseTokenAmount,
                    maxQuoteTokenAmount: data.quoteTokenAmount,
                    quoteExpiry: data.quoteExpiry,
                    nonce: data.nonce,
                    txid: data.txid,
                    signature: data.signature
                })
            );
        } else {
            Utils.approve(targetExchange, address(fromToken), data.baseTokenAmount);

            IHashFlowRouter(targetExchange).tradeSingleHop(
                IQuote.RFQTQuote({
                    pool: data.pool,
                    externalAccount: data.externalAccount,
                    trader: address(this),
                    effectiveTrader: msg.sender,
                    baseToken: address(fromToken),
                    quoteToken: data.quoteToken,
                    effectiveBaseTokenAmount: data.baseTokenAmount,
                    maxBaseTokenAmount: data.baseTokenAmount,
                    maxQuoteTokenAmount: data.quoteTokenAmount,
                    quoteExpiry: data.quoteExpiry,
                    nonce: data.nonce,
                    txid: data.txid,
                    signature: data.signature
                })
            );
        }
    }

    function swapOnHashFlow(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        HashFlowData memory data = abi.decode(payload, (HashFlowData));

        require(data.baseTokenAmount <= fromAmount, "HashFlow baseTokenAmount > fromAmount");

        if (address(fromToken) == Utils.ethAddress()) {
            IHashFlowRouter(exchange).tradeSingleHop{ value: data.baseTokenAmount }(
                IQuote.RFQTQuote({
                    pool: data.pool,
                    externalAccount: data.externalAccount,
                    trader: address(this),
                    effectiveTrader: msg.sender,
                    baseToken: address(0),
                    quoteToken: address(toToken),
                    effectiveBaseTokenAmount: data.baseTokenAmount,
                    maxBaseTokenAmount: data.baseTokenAmount,
                    maxQuoteTokenAmount: data.quoteTokenAmount,
                    quoteExpiry: data.quoteExpiry,
                    nonce: data.nonce,
                    txid: data.txid,
                    signature: data.signature
                })
            );
        } else {
            Utils.approve(exchange, address(fromToken), data.baseTokenAmount);

            IHashFlowRouter(exchange).tradeSingleHop(
                IQuote.RFQTQuote({
                    pool: data.pool,
                    externalAccount: data.externalAccount,
                    trader: address(this),
                    effectiveTrader: msg.sender,
                    baseToken: address(fromToken),
                    quoteToken: data.quoteToken,
                    effectiveBaseTokenAmount: data.baseTokenAmount,
                    maxBaseTokenAmount: data.baseTokenAmount,
                    maxQuoteTokenAmount: data.quoteTokenAmount,
                    quoteExpiry: data.quoteExpiry,
                    nonce: data.nonce,
                    txid: data.txid,
                    signature: data.signature
                })
            );
        }
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
interface IHashflowQuote {
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

	struct XChainRFQTQuote {
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

	enum XChainMessageProtocol {
		layerZero,
		wormhole
	}

	function tradeSingleHop (RFQTQuote calldata quote) external payable;

	function tradeXChain (
		XChainRFQTQuote calldata quote,
		XChainMessageProtocol protocol
	) external payable;
}
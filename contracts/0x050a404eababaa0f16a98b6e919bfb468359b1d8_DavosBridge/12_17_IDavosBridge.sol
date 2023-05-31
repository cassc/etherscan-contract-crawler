// // SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.16;

import "./IERC20.sol";

interface IDavosBridge {

    // --- Structs ---
    struct Metadata {
        bytes32 symbol;
        bytes32 name;
        uint256 originChain;
        address originAddress;
    }

    // --- Events ---
    event BridgeAdded(address bridge, uint256 toChain);
    event BridgeRemoved(address bridge, uint256 toChain);
    event WarpDestinationAdded(address indexed fromToken, uint256 indexed toChain, address indexed toToken);
    event ConsensusChanged(address consensusAddress);
    event DepositWarped(uint256 chainId, address indexed fromAddress, address indexed toAddress, address fromToken, address toToken, uint256 totalAmount, uint256 nonce, Metadata metadata);
    event WithdrawMinted(bytes32 receiptHash, address indexed fromAddress, address indexed toAddress, address fromToken, address toToken, uint256 totalAmount);

    // --- Functions ---
    function depositToken(address fromToken, uint256 toChain, address toAddress, uint256 amount) external;
    function withdraw(bytes calldata encodedProof, bytes calldata rawReceipt, bytes memory receiptRootSignature) external;
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IBridge, MessengerProtocol} from "./interfaces/IBridge.sol";
import {Router} from "./Router.sol";
import {Messenger} from "./Messenger.sol";
import {MessengerGateway} from "./MessengerGateway.sol";
import {IGasOracle} from "./interfaces/IGasOracle.sol";
import {GasUsage} from "./GasUsage.sol";
import {WormholeMessenger} from "./WormholeMessenger.sol";
import {HashUtils} from "./libraries/HashUtils.sol";

/**
 * @title Bridge
 * @dev A contract with functions to facilitate bridging tokens across different blockchains.
 */
contract Bridge is GasUsage, Router, MessengerGateway, IBridge {
    using SafeERC20 for IERC20;
    using HashUtils for bytes32;

    uint public immutable override chainId;
    mapping(bytes32 messageHash => uint isProcessed) public override processedMessages;
    mapping(bytes32 messageHash => uint isSent) public override sentMessages;
    // Info about bridges on other chains
    mapping(uint chainId => bytes32 bridgeAddress) public override otherBridges;
    // Info about tokens on other chains
    mapping(uint chainId => mapping(bytes32 tokenAddress => bool isSupported)) public override otherBridgeTokens;

    /**
     * @dev Emitted when tokens are sent on the source blockchain.
     */
    event TokensSent(
        uint amount,
        bytes32 recipient,
        uint destinationChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger
    );

    /**
     * @dev Emitted when the tokens are received on the destination blockchain.
     */
    event TokensReceived(uint amount, bytes32 recipient, uint nonce, MessengerProtocol messenger, bytes32 message);

    /**
     * @dev Emitted when this contract receives the bridging fee.
     */
    event ReceiveFee(uint bridgeTransactionCost, uint messageTransactionCost);

    /**
     * @dev Emitted when this contract charged the sender with the tokens for the bridging fee.
     */
    event BridgingFeeFromTokens(uint gas);

    /**
     * @dev Emitted when the contract receives native tokens (e.g. Ether on the Ethereum network) from the admin to
     * supply the gas for bridging.
     */
    event Received(address sender, uint amount);

    constructor(
        uint chainId_,
        uint chainPrecision_,
        Messenger allbridgeMessenger_,
        WormholeMessenger wormholeMessenger_,
        IGasOracle gasOracle_
    ) Router(chainPrecision_) MessengerGateway(allbridgeMessenger_, wormholeMessenger_) GasUsage(gasOracle_) {
        chainId = chainId_;
    }

    /**
     * @notice Initiates a swap and bridge process of a given token for a token on another blockchain.
     * @dev This function is used to initiate a cross-chain transfer. The specified amount of token is first transferred
     * to the pool on the current chain, and then an event `TokensSent` is emitted to signal that tokens have been sent
     * on the source chain. See the function `receiveTokens`.
     * The bridging fee required for the cross-chain transfer can be paid in two ways:
     * - by sending the required amount of native gas token along with the transaction
     *   (See `getTransactionCost` in the `GasUsage` contract and `getMessageCost` in the `MessengerGateway` contract).
     * - by setting the parameter `feeTokenAmount` with the bridging fee amount in the source tokens
     *   (See the function `getBridgingCostInTokens`).
     * @param token The token to be swapped.
     * @param amount The amount of tokens to be swapped (including `feeTokenAmount`).
     * @param destinationChainId The ID of the destination chain.
     * @param receiveToken The token to receive in exchange for the swapped token.
     * @param nonce An identifier that is used to ensure that each transfer is unique and can only be processed once.
     * @param messenger The chosen way of delivering the message across chains.
     * @param feeTokenAmount The amount of tokens to be deducted from the transferred amount as a bridging fee.
     *
     */
    function swapAndBridge(
        bytes32 token,
        uint amount,
        bytes32 recipient,
        uint destinationChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger,
        uint feeTokenAmount
    ) external payable override whenCanSwap {
        require(amount > feeTokenAmount, "Bridge: amount too low for fee");
        require(recipient != 0, "Bridge: bridge to the zero address");
        uint bridgingFee = msg.value + _convertBridgingFeeInTokensToNativeToken(msg.sender, token, feeTokenAmount);
        uint amountAfterFee = amount - feeTokenAmount;

        uint vUsdAmount = _sendAndSwapToVUsd(token, msg.sender, amountAfterFee);
        _sendTokens(vUsdAmount, recipient, destinationChainId, receiveToken, nonce, messenger, bridgingFee);
    }

    /**
     * @notice Completes the bridging process by sending the tokens on the destination chain to the recipient.
     * @dev This function is called only after a bridging has been initiated by a user
     *      through the `swapAndBridge` function on the source chain.
     * @param amount The amount of tokens being bridged.
     * @param recipient The recipient address for the bridged tokens.
     * @param sourceChainId The ID of the source chain.
     * @param receiveToken The address of the token being received.
     * @param nonce A unique nonce for the bridging transaction.
     * @param messenger The protocol used to relay the message.
     * @param receiveAmountMin The minimum amount of receiveToken required to be received.
     */
    function receiveTokens(
        uint amount,
        bytes32 recipient,
        uint sourceChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger,
        uint receiveAmountMin
    ) external payable override whenCanSwap {
        require(otherBridges[sourceChainId] != bytes32(0), "Bridge: source not registered");
        bytes32 messageWithSender = this
            .hashMessage(amount, recipient, sourceChainId, chainId, receiveToken, nonce, messenger)
            .hashWithSender(otherBridges[sourceChainId]);

        require(processedMessages[messageWithSender] == 0, "Bridge: message processed");
        // mark the transfer as received on the destination chain
        processedMessages[messageWithSender] = 1;

        // check if tokens has been sent on the source chain
        require(this.hasReceivedMessage(messageWithSender, messenger), "Bridge: no message");

        uint receiveAmount = _receiveAndSwapFromVUsd(
            receiveToken,
            address(uint160(uint(recipient))),
            amount,
            receiveAmountMin
        );
        // pass extra gas to the recipient
        if (msg.value > 0) {
            // ignore if passing extra gas failed
            // solc-ignore-next-line unused-call-retval
            payable(address(uint160(uint(recipient)))).call{value: msg.value}("");
        }
        emit TokensReceived(receiveAmount, recipient, nonce, messenger, messageWithSender);
    }

    /**
     * @notice Allows the admin to add new supported chain destination.
     * @dev Registers the address of a bridge deployed on a different chain.
     * @param chainId_ The chain ID of the bridge to register.
     * @param bridgeAddress The address of the bridge contract to register.
     */
    function registerBridge(uint chainId_, bytes32 bridgeAddress) external override onlyOwner {
        otherBridges[chainId_] = bridgeAddress;
    }

    /**
     * @notice Allows the admin to add a new supported destination token.
     * @dev Adds the address of a token on another chain to the list of supported tokens for the specified chain.
     * @param chainId_ The chain ID where the token is deployed.
     * @param tokenAddress The address of the token to add as a supported token.
     */
    function addBridgeToken(uint chainId_, bytes32 tokenAddress) external override onlyOwner {
        otherBridgeTokens[chainId_][tokenAddress] = true;
    }

    /**
     * @notice Allows the admin to remove support for a destination token.
     * @dev Removes the address of a token on another chain from the list of supported tokens for the specified chain.
     * @param chainId_ The chain ID where the token is deployed.
     * @param tokenAddress The address of the token to remove from the list of supported tokens.
     */
    function removeBridgeToken(uint chainId_, bytes32 tokenAddress) external override onlyOwner {
        otherBridgeTokens[chainId_][tokenAddress] = false;
    }

    /**
     * @notice Allows the admin to withdraw the bridging fee collected in native tokens.
     */
    function withdrawGasTokens(uint amount) external override onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    /**
     * @notice Allows the admin to withdraw the bridging fee collected in tokens.
     * @param token The address of the token contract.
     */
    function withdrawBridgingFeeInTokens(IERC20 token) external onlyOwner {
        uint toWithdraw = token.balanceOf(address(this));
        if (toWithdraw > 0) {
            token.safeTransfer(msg.sender, toWithdraw);
        }
    }

    /**
     * @dev Calculates the amount of bridging fee nominated in a given token, which includes:
     * - the gas cost of making the receive transaction on the destination chain,
     * - the gas cost of sending the message to the destination chain using the specified messenger protocol.
     * @param destinationChainId The ID of the destination chain.
     * @param messenger The chosen way of delivering the message across chains.
     * @param tokenAddress The address of the token contract on the source chain.
     * @return The total price of bridging, with the precision according to the token's `decimals()` value.
     */
    function getBridgingCostInTokens(
        uint destinationChainId,
        MessengerProtocol messenger,
        address tokenAddress
    ) external view override returns (uint) {
        return
            gasOracle.getTransactionGasCostInUSD(
                destinationChainId,
                gasUsage[destinationChainId] + getMessageGasUsage(destinationChainId, messenger)
            ) / fromGasOracleScalingFactor[tokenAddress];
    }

    /**
     * @dev Produces a hash of transfer parameters, which is used as a message to the bridge on the destination chain
     *      to notify that the tokens on the source chain has been sent.
     * @param amount The amount of tokens being transferred.
     * @param recipient The address of the recipient on the destination chain.
     * @param sourceChainId The ID of the source chain.
     * @param destinationChainId The ID of the destination chain.
     * @param receiveToken The token being received on the destination chain.
     * @param nonce The unique nonce.
     * @param messenger The chosen way of delivering the message across chains.
     */
    function hashMessage(
        uint amount,
        bytes32 recipient,
        uint sourceChainId,
        uint destinationChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger
    ) external pure override returns (bytes32) {
        return
            keccak256(abi.encodePacked(amount, recipient, sourceChainId, receiveToken, nonce, messenger))
                .replaceChainBytes(uint8(sourceChainId), uint8(destinationChainId));
    }

    function _sendTokens(
        uint amount,
        bytes32 recipient,
        uint destinationChainId,
        bytes32 receiveToken,
        uint nonce,
        MessengerProtocol messenger,
        uint bridgingFee
    ) internal {
        require(destinationChainId != chainId, "Bridge: wrong destination chain");
        require(otherBridgeTokens[destinationChainId][receiveToken], "Bridge: unknown chain or token");
        bytes32 message = this.hashMessage(
            amount,
            recipient,
            chainId,
            destinationChainId,
            receiveToken,
            nonce,
            messenger
        );

        require(sentMessages[message] == 0, "Bridge: tokens already sent");
        // mark the transfer as sent on the source chain
        sentMessages[message] = 1;

        uint bridgeTransactionCost = this.getTransactionCost(destinationChainId);
        uint messageTransactionCost = _sendMessage(message, messenger);
        emit ReceiveFee(bridgeTransactionCost, messageTransactionCost);
        unchecked {
            require(bridgingFee >= bridgeTransactionCost + messageTransactionCost, "Bridge: not enough fee");
        }
        emit TokensSent(amount, recipient, destinationChainId, receiveToken, nonce, messenger);
    }

    /**
     * @dev Charges the bridging fee in tokens and calculates the amount of native tokens that correspond
     *      to the charged fee using the current exchange rate.
     * @param user The address of the user who is paying the bridging fee
     * @param tokenAddress The address of the token used to pay the bridging fee
     * @param feeTokenAmount The amount of tokens to pay as the bridging fee
     * @return bridging fee amount in the native tokens (e.g. in wei for Ethereum)
     */
    function _convertBridgingFeeInTokensToNativeToken(
        address user,
        bytes32 tokenAddress,
        uint feeTokenAmount
    ) internal returns (uint) {
        if (feeTokenAmount == 0) return 0;
        address tokenAddress_ = address(uint160(uint(tokenAddress)));

        IERC20 token = IERC20(tokenAddress_);
        token.safeTransferFrom(user, address(this), feeTokenAmount);

        uint fee = (bridgingFeeConversionScalingFactor[tokenAddress_] * feeTokenAmount) / gasOracle.price(chainId);

        emit BridgingFeeFromTokens(fee);
        return fee;
    }

    fallback() external payable {
        revert("Unsupported");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
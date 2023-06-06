// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import {IWormhole} from "../interfaces/IWormhole.sol";
import {ITokenBridge} from "../interfaces/ITokenBridge.sol";

import "../libraries/BytesLib.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./TokenBridgeRelayerGovernance.sol";
import "./TokenBridgeRelayerMessages.sol";

/**
 * @title Wormhole Token Bridge Relayer
 * @notice This contract composes on Wormhole's Token Bridge contracts to faciliate
 * one-click transfers of Token Bridge supported assets cross chain.
 */
contract TokenBridgeRelayer is TokenBridgeRelayerGovernance, TokenBridgeRelayerMessages, ReentrancyGuard {
    using BytesLib for bytes;

    // contract version
    string public constant VERSION = "0.2.0";

    constructor(
        address tokenBridge_,
        address wethAddress,
        address feeRecipient_,
        address ownerAssistant_,
        bool unwrapWeth_
    ) {
        require(tokenBridge_ != address(0), "invalid token bridge address");
        require(wethAddress != address(0), "invalid weth address");
        require(feeRecipient_ != address(0), "invalid fee recipient");
        require(ownerAssistant_ != address(0), "invalid owner assistant");

        // set initial state
        setOwner(msg.sender);
        setFeeRecipient(feeRecipient_);
        setTokenBridge(tokenBridge_);
        setWethAddress(wethAddress);
        setOwnerAssistant(ownerAssistant_);
        setUnwrapWethFlag(unwrapWeth_);

        // fetch wormhole info from token bridge
        ITokenBridge bridge = ITokenBridge(tokenBridge_);
        setChainId(bridge.chainId());
        setWormhole(address(bridge.wormhole()));

        // set the initial swapRate/relayer precisions to 1e8
        setSwapRatePrecision(1e8);
        setRelayerFeePrecision(1e8);
    }

    /**
     * @notice Emitted when a transfer is completed by the Wormhole token bridge
     * @param emitterChainId Wormhole chain ID of emitter contract on the source chain
     * @param emitterAddress Address (bytes32 zero-left-padded) of emitter on the source chain
     * @param sequence Sequence of the Wormhole message
     */
    event TransferRedeemed(
        uint16 indexed emitterChainId,
        bytes32 indexed emitterAddress,
        uint64 indexed sequence
    );

    /**
     * @notice Emitted when a swap is executed with an off-chain relayer
     * @param recipient Address of the recipient of the native assets
     * @param relayer Address of the relayer that performed the swap
     * @param token Address of the token being swapped
     * @param tokenAmount Amount of token being swapped
     * @param nativeAmount Amount of native assets swapped for tokens
     */
    event SwapExecuted(
        address indexed recipient,
        address indexed relayer,
        address indexed token,
        uint256 tokenAmount,
        uint256 nativeAmount
    );

    /**
     * @notice Calls Wormhole's Token Bridge contract to emit a contract-controlled
     * transfer. The transfer message includes an arbitrary payload with instructions
     * for how to handle relayer payments on the target contract and the quantity of
     * tokens to convert into native assets for the user.
     * @param token ERC20 token address to transfer cross chain.
     * @param amount Quantity of tokens to be transferred.
     * @param toNativeTokenAmount Amount of tokens to swap into native assets on
     * the target chain.
     * @param targetChain Wormhole chain ID of the target blockchain.
     * @param targetRecipient User's wallet address on the target blockchain in bytes32 format
     * (zero-left-padded).
     * @param batchId ID for Wormhole message batching
     * @return messageSequence Wormhole sequence for emitted TransferTokensWithRelay message.
     */
    function transferTokensWithRelay(
        address token,
        uint256 amount,
        uint256 toNativeTokenAmount,
        uint16 targetChain,
        bytes32 targetRecipient,
        uint32 batchId
    ) public payable nonReentrant notPaused returns (uint64 messageSequence) {
        // Cache wormhole fee and confirm that the user has passed enough
        // value to cover the wormhole protocol fee.
        uint256 wormholeFee = wormhole().messageFee();
        require(msg.value == wormholeFee, "insufficient value");

        // Cache token decimals, and remove dust from the amount argument. This
        // ensures that the dust is never transferred to this contract.
        uint8 tokenDecimals = getDecimals(token);
        amount = denormalizeAmount(
            normalizeAmount(amount, tokenDecimals),
            tokenDecimals
        );

        // Transfer tokens from user to the this contract, and
        // override amount with actual amount received.
        amount = custodyTokens(token, amount);

        // call the internal _transferTokensWithRelay function
        messageSequence = _transferTokensWithRelay(
            InternalTransferParams({
                token: token,
                amount: amount,
                tokenDecimals: tokenDecimals,
                toNativeTokenAmount: toNativeTokenAmount,
                targetChain: targetChain,
                targetRecipient: targetRecipient
            }),
            batchId,
            wormholeFee
        );
    }

    /**
     * @notice Wraps Ether and calls Wormhole's Token Bridge contract to emit
     * a contract-controlled transfer. The transfer message includes an arbitrary
     * payload with instructions for how to handle relayer payments on the target
     * contract and the quantity of tokens to convert into native assets for the user.
     * @param toNativeTokenAmount Amount of tokens to swap into native assets on
     * the target chain.
     * @param targetChain Wormhole chain ID of the target blockchain.
     * @param targetRecipient User's wallet address on the target blockchain in bytes32 format
     * (zero-left-padded).
     * @param batchId ID for Wormhole message batching
     * @return messageSequence Wormhole sequence for emitted TransferTokensWithRelay message.
     */
    function wrapAndTransferEthWithRelay(
        uint256 toNativeTokenAmount,
        uint16 targetChain,
        bytes32 targetRecipient,
        uint32 batchId
    ) public payable notPaused returns (uint64 messageSequence) {
        require(unwrapWeth(), "WETH functionality not supported");

        // Cache wormhole fee and confirm that the user has passed enough
        // value to cover the wormhole protocol fee.
        uint256 wormholeFee = wormhole().messageFee();
        require(msg.value > wormholeFee, "insufficient value");

        // remove the wormhole protocol fee from the amount
        uint256 amount = msg.value - wormholeFee;

        // refund dust
        uint256 dust = amount - denormalizeAmount(normalizeAmount(amount, 18), 18);
        if (dust > 0) {
            payable(msg.sender).transfer(dust);
        }

        // remove dust from amount and cache WETH
        uint256 amountLessDust = amount - dust;
        IWETH weth = WETH();

        // deposit into the WETH contract
        weth.deposit{
            value : amountLessDust
        }();

        // call the internal _transferTokensWithRelay function
        messageSequence = _transferTokensWithRelay(
            InternalTransferParams({
                token: address(weth),
                tokenDecimals: 18,
                amount: amountLessDust,
                toNativeTokenAmount: toNativeTokenAmount,
                targetChain: targetChain,
                targetRecipient: targetRecipient
            }),
            batchId,
            wormholeFee
        );
    }

    function _transferTokensWithRelay(
        InternalTransferParams memory params,
        uint32 batchId,
        uint256 wormholeFee
    ) internal returns (uint64 messageSequence) {
        // sanity check function arguments
        require(isAcceptedToken(params.token), "token not accepted");
        require(
            params.targetRecipient != bytes32(0),
            "targetRecipient cannot be bytes32(0)"
        );

        /**
         * Cache the normalized amount and verify that it's nonzero.
         * The token bridge peforms the same operation before encoding
         * the amount in the `TransferWithPayload` message.
         */
        uint256 normalizedAmount = normalizeAmount(
            params.amount,
            params.tokenDecimals
        );
        require(normalizedAmount > 0, "normalized amount must be > 0");

        // normalized toNativeTokenAmount should be nonzero
        uint256 normalizedToNativeTokenAmount = normalizeAmount(
            params.toNativeTokenAmount,
            params.tokenDecimals
        );
        require(
            params.toNativeTokenAmount == 0 || normalizedToNativeTokenAmount > 0,
            "invalid toNativeTokenAmount"
        );

        // Cache the target contract address and verify that there
        // is a registered contract for the specified targetChain.
        bytes32 targetContract = getRegisteredContract(params.targetChain);
        require(targetContract != bytes32(0), "target not registered");

        // Confirm that the user has sent enough tokens to cover the native swap
        // on the target chain and to pay the relayer fee.
        uint256 normalizedRelayerFee = normalizeAmount(
            calculateRelayerFee(
                params.targetChain,
                params.token,
                params.tokenDecimals
            ),
            params.tokenDecimals
        );
        require(
            normalizedAmount > normalizedRelayerFee + normalizedToNativeTokenAmount,
            "insufficient amount"
        );

        /**
         * Encode instructions (TransferWithRelay) to send with the token transfer.
         * The `targetRecipient` address is in bytes32 format (zero-left-padded) to
         * support non-evm smart contracts that have addresses that are longer
         * than 20 bytes.
         *
         * We normalize the relayerFee and toNativeTokenAmount to support
         * non-evm smart contracts that can only handle uint64.max values.
         */
        bytes memory messagePayload = encodeTransferWithRelay(
            TransferWithRelay({
                payloadId: 1,
                targetRelayerFee: normalizedRelayerFee,
                toNativeTokenAmount: normalizedToNativeTokenAmount,
                targetRecipient: params.targetRecipient
            })
        );

        // cache TokenBridge instance
        ITokenBridge bridge = tokenBridge();

        // approve the token bridge to spend the specified tokens
        SafeERC20.safeApprove(
            IERC20(params.token),
            address(bridge),
            params.amount
        );

        /**
         * Call `transferTokensWithPayload` method on the token bridge and pay
         * the Wormhole network fee. The token bridge will emit a Wormhole
         * message with an encoded `TransferWithPayload` struct (see the
         * ITokenBridge.sol interface file in this repo).
         */
        messageSequence = bridge.transferTokensWithPayload{value: wormholeFee}(
            params.token,
            params.amount,
            params.targetChain,
            targetContract,
            batchId,
            messagePayload
        );
    }

    /**
     * @notice Calls Wormhole's Token Bridge contract to complete token transfers. Takes
     * custody of the wrapped (or released) tokens and sends the tokens to the target recipient.
     * It pays the fee recipient in the minted token denomination. If requested by the user,
     * it will perform a swap with the off-chain relayer to provide the user with native assets.
     * If the `token` being transferred is WETH, the contract will unwrap native assets and send
     * the transferred amount to the recipient and pay the fee recipient in native assets.
     * @dev reverts if:
     * - the transferred token is not accepted by this contract
     * - the transffered token is not attested on this blockchain's Token Bridge contract
     * - the emitter of the transfer message is not registered with this contract
     * - the relayer fails to provide enough native assets to faciliate a native swap
     * - the recipient attempts to swap native assets when performing a self redemption
     * @param encodedTransferMessage Attested `TransferWithPayload` wormhole message.
     */
    function completeTransferWithRelay(bytes calldata encodedTransferMessage) public payable {
        // complete the transfer by calling the token bridge
        (bytes memory payload, uint256 amount, address token) =
             _completeTransfer(encodedTransferMessage);

        // parse the payload into the `TransferWithRelay` struct
        TransferWithRelay memory transferWithRelay = decodeTransferWithRelay(
            payload
        );

        // cache the recipient address and unwrap weth flag
        address recipient = bytes32ToAddress(transferWithRelay.targetRecipient);
        bool unwrapWeth = unwrapWeth();

        // handle self redemptions
        if (msg.sender == recipient) {
            _completeSelfRedemption(
                token,
                recipient,
                amount,
                unwrapWeth
            );

            // bail out
            return;
        }

        // cache token decimals
        uint8 tokenDecimals = getDecimals(token);

        // denormalize the encoded relayerFee
        transferWithRelay.targetRelayerFee = denormalizeAmount(
            transferWithRelay.targetRelayerFee,
            tokenDecimals
        );

        // unwrap and transfer ETH
        if (token == address(WETH())) {
            _completeWethTransfer(
                amount,
                recipient,
                transferWithRelay.targetRelayerFee,
                unwrapWeth
            );

            // bail out
            return;
        }

        // handle native asset payments and refunds
        if (transferWithRelay.toNativeTokenAmount > 0) {
            // denormalize the toNativeTokenAmount
            transferWithRelay.toNativeTokenAmount = denormalizeAmount(
                transferWithRelay.toNativeTokenAmount,
                tokenDecimals
            );

            /**
             * Compute the maximum amount of tokens that the user is allowed
             * to swap for native assets.
             *
             * Override the toNativeTokenAmount in transferWithRelay if the
             * toNativeTokenAmount is greater than the maxToNativeAllowed.
             *
             * Compute the amount of native assets to send the recipient.
             */
            uint256 maxToNativeAllowed = calculateMaxSwapAmountIn(token);
            if (transferWithRelay.toNativeTokenAmount > maxToNativeAllowed) {
                transferWithRelay.toNativeTokenAmount = maxToNativeAllowed;
            }
            // compute amount of native asset to pay the recipient
            uint256 nativeAmountForRecipient = calculateNativeSwapAmountOut(
                token,
                transferWithRelay.toNativeTokenAmount
            );

            /**
             * The nativeAmountForRecipient can be zero if the user specifed
             * a toNativeTokenAmount that is too little to convert to native
             * asset. We need to override the toNativeTokenAmount to be zero
             * if that is the case, that way the user receives the full amount
             * of transferred tokens.
             */
            if (nativeAmountForRecipient > 0) {
                // check to see if the relayer sent enough value
                require(
                    msg.value >= nativeAmountForRecipient,
                    "insufficient native asset amount"
                );

                // refund excess native asset to relayer if applicable
                uint256 relayerRefund = msg.value - nativeAmountForRecipient;
                if (relayerRefund > 0) {
                    payable(msg.sender).transfer(relayerRefund);
                }

                // send requested native asset to target recipient
                payable(recipient).transfer(nativeAmountForRecipient);

                // emit swap event
                emit SwapExecuted(
                    recipient,
                    msg.sender,
                    token,
                    transferWithRelay.toNativeTokenAmount,
                    nativeAmountForRecipient
                );
            } else {
                // override the toNativeTokenAmount in transferWithRelay
                transferWithRelay.toNativeTokenAmount = 0;

                // refund the relayer any native asset sent to this contract
                if (msg.value > 0) {
                    payable(msg.sender).transfer(msg.value);
                }
            }
        }

        // add the token swap amount to the relayer fee
        uint256 amountForRelayer =
            transferWithRelay.targetRelayerFee + transferWithRelay.toNativeTokenAmount;

        // pay the fee recipient if amountForRelayer > 0
        if (amountForRelayer > 0) {
            SafeERC20.safeTransfer(
                IERC20(token),
                feeRecipient(),
                amountForRelayer
            );
        }

        // pay the target recipient the remaining tokens
        SafeERC20.safeTransfer(
            IERC20(token),
            recipient,
            amount - amountForRelayer
        );
    }

    function _completeTransfer(
        bytes memory encodedTransferMessage
    ) internal returns (bytes memory, uint256, address) {
        /**
         * parse the encoded Wormhole message
         *
         * SECURITY: This message not been verified by the Wormhole core layer yet.
         * The encoded payload can only be trusted once the message has been verified
         * by the Wormhole core contract. In this case, the message will be verified
         * by a call to the token bridge contract in subsequent actions.
         */
        IWormhole.VM memory parsedMessage = wormhole().parseVM(
            encodedTransferMessage
        );

        /**
         * The amount encoded in the payload could be incorrect,
         * since fee-on-transfer tokens are supported by the token bridge.
         *
         * NOTE: The token bridge truncates the encoded amount for any token
         * with decimals greater than 8. This is to support blockchains that
         * cannot handle transfer amounts exceeding max(uint64).
         */
        address localTokenAddress = fetchLocalAddressFromTransferMessage(
            parsedMessage.payload
        );
        require(isAcceptedToken(localTokenAddress), "token not registered");

        // check balance before completing the transfer
        uint256 balanceBefore = getBalance(localTokenAddress);

        // cache the token bridge instance
        ITokenBridge bridge = tokenBridge();

        /**
         * Call `completeTransferWithPayload` on the token bridge. This
         * method acts as a reentrancy protection since it does not allow
         * transfers to be redeemed more than once.
         */
        bytes memory transferPayload = bridge.completeTransferWithPayload(
            encodedTransferMessage
        );

        // compute and save the balance difference after completing the transfer
        uint256 amountReceived = getBalance(localTokenAddress) - balanceBefore;

        // parse the wormhole message payload into the `TransferWithPayload` struct
        ITokenBridge.TransferWithPayload memory transfer =
            bridge.parseTransferWithPayload(transferPayload);

        // confirm that the message sender is a registered TokenBridgeRelayer contract
        require(
            transfer.fromAddress == getRegisteredContract(parsedMessage.emitterChainId),
            "contract not registered"
        );

        // emit event with information about the TransferWithPayload message
        emit TransferRedeemed(
            parsedMessage.emitterChainId,
            parsedMessage.emitterAddress,
            parsedMessage.sequence
        );

        return (
            transfer.payload,
            amountReceived,
            localTokenAddress
        );
    }

    function _completeSelfRedemption(
        address token,
        address recipient,
        uint256 amount,
        bool unwrapWeth
    ) internal {
        // revert if the caller sends ether to this contract
        require(msg.value == 0, "recipient cannot swap native assets");

        // cache WETH instance
        IWETH weth = WETH();

        // transfer the full amount to the recipient
        if (token == address(weth) && unwrapWeth) {
            // withdraw weth and send to the recipient
            weth.withdraw(amount);
            payable(recipient).transfer(amount);
        } else {
            SafeERC20.safeTransfer(
                IERC20(token),
                recipient,
                amount
            );
        }
    }

    function _completeWethTransfer(
        uint256 amount,
        address recipient,
        uint256 relayerFee,
        bool unwrapWeth
    ) internal {
        // revert if the relayer sends ether to this contract
        require(msg.value == 0, "value must be zero");

        /**
         * Check if the weth is unwrappable. Some wrapped native assets
         * are not unwrappable (e.g. CELO) and must be transferred via
         * the ERC20 interface.
         */
        if (unwrapWeth) {
            // withdraw eth
            WETH().withdraw(amount);

            // transfer eth to recipient
            payable(recipient).transfer(amount - relayerFee);

            // transfer relayer fee to the fee recipient
            if (relayerFee > 0) {
                payable(feeRecipient()).transfer(relayerFee);
            }
        } else {
            // cache WETH instance
            IWETH weth = WETH();

            // transfer the native asset to the caller
            SafeERC20.safeTransfer(
                IERC20(address(weth)),
                recipient,
                amount - relayerFee
            );

            // transfer relayer fee to the fee recipient
            if (relayerFee > 0) {
                SafeERC20.safeTransfer(
                    IERC20(address(weth)),
                    feeRecipient(),
                    relayerFee
                );
            }
        }
    }

    /**
     * @notice Parses the encoded address and chainId from a `TransferWithPayload`
     * message. Finds the address of the wrapped token contract if the token is not
     * native to this chain.
     * @param payload Encoded `TransferWithPayload` message
     * @return localAddress Address of the encoded (bytes32 format) token address on
     * this chain.
     */
    function fetchLocalAddressFromTransferMessage(
        bytes memory payload
    ) public view returns (address localAddress) {
        // parse the source token address and chainId
        bytes32 sourceAddress = payload.toBytes32(33);
        uint16 tokenChain = payload.toUint16(65);

        // Fetch the wrapped address from the token bridge if the token
        // is not from this chain.
        if (tokenChain != chainId()) {
            // identify wormhole token bridge wrapper
            localAddress = tokenBridge().wrappedAsset(tokenChain, sourceAddress);
            require(localAddress != address(0), "token not attested");
        } else {
            // return the encoded address if the token is native to this chain
            localAddress = bytes32ToAddress(sourceAddress);
        }
    }

    /**
     * @notice Calculates the max amount of tokens the user can convert to
     * native assets on this chain.
     * @dev The max amount of native assets the contract will swap with the user
     * is governed by the `maxNativeSwapAmount` state variable.
     * @param token Address of token being transferred.
     * @return maxAllowed The maximum number of tokens the user is allowed to
     * swap for native assets.
     */
    function calculateMaxSwapAmountIn(
        address token
    ) public view returns (uint256 maxAllowed) {
        // fetch the decimals for the token and native token
        uint8 tokenDecimals = getDecimals(token);
        uint8 nativeDecimals = getDecimals(address(WETH()));

        if (tokenDecimals > nativeDecimals) {
            maxAllowed =
                maxNativeSwapAmount(token) * nativeSwapRate(token) *
                10 ** (tokenDecimals - nativeDecimals) / swapRatePrecision();
        } else {
            maxAllowed =
                (maxNativeSwapAmount(token) * nativeSwapRate(token)) /
                (10 ** (nativeDecimals - tokenDecimals) * swapRatePrecision());
        }
    }

    /**
     * @notice Calculates the amount of native assets that a user will receive
     * when swapping transferred tokens for native assets.
     * @param token Address of token being transferred.
     * @param toNativeAmount Quantity of tokens to be converted to native assets.
     * @return nativeAmount The exchange rate between native assets and the `toNativeAmount`
     * of transferred tokens.
     */
    function calculateNativeSwapAmountOut(
        address token,
        uint256 toNativeAmount
    ) public view returns (uint256 nativeAmount) {
        // fetch the decimals for the token and native token
        uint8 tokenDecimals = getDecimals(token);
        uint8 nativeDecimals = getDecimals(address(WETH()));

        if (tokenDecimals > nativeDecimals) {
            nativeAmount =
                swapRatePrecision() * toNativeAmount /
                (nativeSwapRate(token) * 10 ** (tokenDecimals - nativeDecimals));
        } else {
            nativeAmount =
                swapRatePrecision() * toNativeAmount *
                10 ** (nativeDecimals - tokenDecimals) /
                nativeSwapRate(token);
        }
    }

    /**
     * @notice Converts the USD denominated relayer fee into the specified token
     * denomination.
     * @param targetChainId Wormhole chain ID of the target blockchain.
     * @param token Address of token being transferred.
     * @param decimals Token decimals of token being transferred.
     * @return feeInTokenDenomination Relayer fee denominated in tokens.
     */
    function calculateRelayerFee(
        uint16 targetChainId,
        address token,
        uint8 decimals
    ) public view returns (uint256 feeInTokenDenomination) {
        // cache swap rate
        uint256 tokenSwapRate = swapRate(token);
        require(tokenSwapRate != 0, "swap rate not set");
        feeInTokenDenomination =
            10 ** decimals * relayerFee(targetChainId) * swapRatePrecision() /
            (tokenSwapRate * relayerFeePrecision());
    }

    function custodyTokens(
        address token,
        uint256 amount
    ) internal returns (uint256) {
        // query own token balance before transfer
        uint256 balanceBefore = getBalance(token);

        // deposit tokens
        SafeERC20.safeTransferFrom(
            IERC20(token),
            msg.sender,
            address(this),
            amount
        );

        // return the balance difference
        return getBalance(token) - balanceBefore;
    }

    function bytes32ToAddress(bytes32 address_) internal pure returns (address) {
        require(bytes12(address_) == 0, "invalid EVM address");
        return address(uint160(uint256(address_)));
    }

    // necessary for receiving native assets
    receive() external payable {}
}
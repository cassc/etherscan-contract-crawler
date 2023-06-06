// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import {IWormhole} from "../interfaces/IWormhole.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./TokenBridgeRelayerGetters.sol";
import "./TokenBridgeRelayerStructs.sol";

abstract contract TokenBridgeRelayerGovernance is TokenBridgeRelayerGetters {
    event OwnershipTransfered(address indexed oldOwner, address indexed newOwner);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event SwapRateUpdated(TokenBridgeRelayerStructs.SwapRateUpdate[] indexed swapRates);

    /**
     * @notice Starts the ownership transfer process of the contracts. It saves
     * an address in the pending owner state variable.
     * @param chainId_ Wormhole chain ID.
     * @param newOwner Address of the pending owner.
     */
    function submitOwnershipTransferRequest(
        uint16 chainId_,
        address newOwner
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(newOwner != address(0), "newOwner cannot equal address(0)");

        setPendingOwner(newOwner);
    }

    /**
     * @notice Cancels the ownership transfer process.
     * @dev Sets the pending owner state variable to the zero address.
     */
    function cancelOwnershipTransferRequest(
        uint16 chainId_
    ) public onlyOwner onlyCurrentChain(chainId_) {
        setPendingOwner(address(0));
    }

    /**
     * @notice Finalizes the ownership transfer to the pending owner.
     * @dev It checks that the caller is the pendingOwner to validate the wallet
     * address. It updates the owner state variable with the pendingOwner state
     * variable.
     */
    function confirmOwnershipTransferRequest() public {
        // cache the new owner address
        address newOwner = pendingOwner();

        require(msg.sender == newOwner, "caller must be pendingOwner");

        // cache currentOwner for Event
        address currentOwner = owner();

        // update the owner in the contract state and reset the pending owner
        setOwner(newOwner);
        setPendingOwner(address(0));

        emit OwnershipTransfered(currentOwner, newOwner);
    }

    /**
     * @notice Updates the `ownerAssistant` state variable. This method can
     * only be executed by the owner.
     * @param chainId_ Wormhole chain ID.
     * @param newAssistant Address of the new `ownerAssistant`.
     */
    function updateOwnerAssistant(
        uint16 chainId_,
        address newAssistant
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(
            newAssistant != address(0),
            "newAssistant cannot equal address(0)"
        );

        // update the owner assistant
        setOwnerAssistant(newAssistant);
    }

    /**
     * @notice Updates the `feeRecipient` state variable. This method can
     * only be executed by the owner.
     * @param chainId_ Wormhole chain ID.
     * @param newFeeRecipient Address of the new `feeRecipient`.
     */
    function updateFeeRecipient(
        uint16 chainId_,
        address newFeeRecipient
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(
            newFeeRecipient != address(0),
            "newFeeRecipient cannot equal address(0)"
        );

        // cache current fee recipient
        address currentFeeRecipient = feeRecipient();

        // update the fee recipient
        setFeeRecipient(newFeeRecipient);

        emit FeeRecipientUpdated(currentFeeRecipient, newFeeRecipient);
    }

    /**
     * @notice Updates the unwrapWeth state variable.
     * @dev This variable should only be set to true for chains that
     * support a WETH contract. Some chains (e.g. Celo, Karura, Acala)
     * do not support a WETH contract, and the address is set as a placeholder
     * for the native asset address for swapRate lookups.
     * @param chainId_ Wormhole chain ID.
     * @param unwrapWeth_ Boolean that determines if WETH is unwrapped
     * when transferred back to its native blockchain.
     */
    function updateUnwrapWethFlag(
        uint16 chainId_,
        bool unwrapWeth_
    ) public onlyOwner onlyCurrentChain(chainId_) {
        setUnwrapWethFlag(unwrapWeth_);
    }

    /**
     * @notice Registers foreign Token Bridge Relayer contracts.
     * @param chainId_ Wormhole chain ID of the foreign contract.
     * @param contractAddress Address of the foreign contract in bytes32 format
     * (zero-left-padded address).
     */
    function registerContract(
        uint16 chainId_,
        bytes32 contractAddress
    ) public onlyOwner {
        // sanity check both input arguments
        require(
            contractAddress != bytes32(0),
            "contractAddress cannot equal bytes32(0)"
        );
        require(
            chainId_ != 0 && chainId_ != chainId(),
            "chainId_ cannot equal 0 or this chainId"
        );

        // update the registeredContracts state variable
        _registerContract(chainId_, contractAddress);
    }

    /**
     * @notice Register tokens accepted by this contract.
     * @param chainId_ Wormhole chain ID.
     * @param token Address of the token.
     */
    function registerToken(
        uint16 chainId_,
        address token
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(token != address(0), "invalid token");

        addAcceptedToken(token);
    }

    /**
     * @notice Deregister tokens accepted by this contract.
     * @dev The `removeAcceptedToken` function will revert
     * if the token is not registered.
     * @param chainId_ Wormhole chain ID.
     * @param token Address of the token.
     */
    function deregisterToken(
        uint16 chainId_,
        address token
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(token != address(0), "invalid token");

        removeAcceptedToken(token);
    }

    /**
     * @notice Updates the fee for relaying transfers to foreign contracts.
     * @param chainId_ Wormhole chain ID.
     * @param amount Amount of USD to pay the relayer upon redemption.
     * @dev The relayerFee is scaled by the relayerFeePrecision. For example,
     * if the relayerFee is $15 and the relayerFeePrecision is 1000000, the
     * relayerFee should be set to 15000000.
     */
    function updateRelayerFee(
        uint16 chainId_,
        uint256 amount
    ) public onlyOwnerOrAssistant {
        require(chainId_ != chainId(), "invalid chain");
        require(
            getRegisteredContract(chainId_) != bytes32(0),
            "contract doesn't exist"
        );

        setRelayerFee(chainId_, amount);
    }

    /**
     * @notice Updates the precision of the relayer fee.
     * @param chainId_ Wormhole chain ID.
     * @param relayerFeePrecision_ Precision of relayer fee.
     */
    function updateRelayerFeePrecision(
        uint16 chainId_,
        uint256 relayerFeePrecision_
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(relayerFeePrecision_ > 0, "precision must be > 0");

        setRelayerFeePrecision(relayerFeePrecision_);
    }

    /**
     * @notice Updates the swap rates for a batch of tokens.
     * @param chainId_ Wormhole chain ID.
     * @param swapRateUpdate Array of structs with token -> swap rate pairs.
     * @dev The swapRate is the conversion rate using asset prices denominated in
     * USD multiplied by the swapRatePrecision. For example, if the conversion
     * rate is $15 and the swapRatePrecision is 1000000, the swapRate should be set
     * to 15000000.
     *
     * NOTE: This function does NOT check if a token is specified twice. It is up to the
     * owner to correctly construct the `SwapRateUpdate` struct.
     */
    function updateSwapRate(
        uint16 chainId_,
        TokenBridgeRelayerStructs.SwapRateUpdate[] calldata swapRateUpdate
    ) public onlyOwnerOrAssistant onlyCurrentChain(chainId_) {
        // cache length of swapRateUpdate array
        uint256 numTokens = swapRateUpdate.length;
        require(numTokens > 0, "invalid array size");

        // set the swap rate for each token
        for (uint256 i = 0; i < numTokens;) {
            require(
                isAcceptedToken(swapRateUpdate[i].token),
                "token not accepted"
            );
            require(
                swapRateUpdate[i].value > 0,
                "swap rate must be nonzero"
            );

            setSwapRate(swapRateUpdate[i].token, swapRateUpdate[i].value);

            unchecked { i += 1; }
        }

        emit SwapRateUpdated(swapRateUpdate);
    }

    /**
     * @notice Updates the precision of the swap rate.
     * @param chainId_ Wormhole chain ID.
     * @param swapRatePrecision_ Precision of swap rate.
     */
    function updateSwapRatePrecision(
        uint16 chainId_,
        uint256 swapRatePrecision_
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(swapRatePrecision_ > 0, "precision must be > 0");

        setSwapRatePrecision(swapRatePrecision_);
    }

    /**
     * @notice Updates the max amount of native assets the contract will pay
     * to the target recipient.
     * @param chainId_ Wormhole chain ID.
     * @param token Address of the token to update the max native swap amount for.
     * @param maxAmount Max amount of native assets.
     */
    function updateMaxNativeSwapAmount(
        uint16 chainId_,
        address token,
        uint256 maxAmount
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(isAcceptedToken(token), "token not accepted");

        setMaxNativeSwapAmount(token, maxAmount);
    }

    /**
     * @notice Sets the pause state of the relayer. If paused, token transfer
     * requests are blocked. In flight transfers, i.e. those that have a VAA
     * emitted, can still be processed if paused.
     * @param chainId_ Wormhole chain ID
     * @param paused If true, requests for token transfers will be blocked
     * and no VAAs will be generated.
     */
    function setPauseForTransfers(
        uint16 chainId_,
        bool paused
    ) public onlyOwner onlyCurrentChain(chainId_) {
        setPaused(paused);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "caller not the owner");
        _;
    }

    modifier onlyOwnerOrAssistant() {
        require(
            owner() == msg.sender ||
            ownerAssistant() == msg.sender,
            "caller not the owner or assistant"
        );
        _;
    }

    modifier onlyCurrentChain(uint16 chainId_) {
        require(chainId() == chainId_, "wrong chain");
        _;
    }

    modifier notPaused() {
        require(!getPaused(), "relayer is paused");
        _;
    }
}
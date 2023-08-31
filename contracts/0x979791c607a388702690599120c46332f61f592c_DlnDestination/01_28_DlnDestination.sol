// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IERC20Permit.sol";
import "../libraries/BytesLib.sol";
import "../libraries/EncodeSolanaDlnMessage.sol";
import "./DlnBase.sol";
import "./DlnSource.sol";
import "@debridge-finance/debridge-contracts-v1/contracts/libraries/Flags.sol";
import "../interfaces/IDlnDestination.sol";

contract DlnDestination is DlnBase, ReentrancyGuardUpgradeable, IDlnDestination {

    /* ========== CONSTANTS ========== */

    /// @dev Amount divider to transfer native assets to the Solana network. (evm 18 decimals => solana 8 decimals)
    /// As Solana only supports u64, and doesn't support u256, amounts must be adjusted when a transfer from EVM chain to Sonana
    /// is being made, for that amount value must me "shifted" on k decimals to get max solana decimals = 8
    uint256 public constant NATIVE_AMOUNT_DIVIDER_FOR_TRANSFER_TO_SOLANA = 1e10;

    /* ========== STATE VARIABLES ========== */

    /// @dev Maps chainId to  address of dlnSource contract on that chain
    mapping(uint256 => bytes) public dlnSourceAddresses;

    // @dev Maps orderId (see getOrderId) => state of order.
    mapping(bytes32 => OrderTakeState) public takeOrders;

    /// Storage for take patches
    /// Values here is subtrahend from [`Order::take::amount`] in [`fulfill_order`] moment
    mapping(bytes32 => uint256) public takePatches;

    uint256 public maxOrderCountPerBatchEvmUnlock;
    uint256 public maxOrderCountPerBatchSolanaUnlock;

    /* ========== ENUMS ========== */

    enum OrderTakeStatus {
        NotSet, //0
        /// Order full filled
        Fulfilled, // 1
        /// Order full filled and unlock command sent in give.chain_id by taker
        SentUnlock, // 2
        /// Order canceled
        SentCancel // 3
    }

    /* ========== STRUCTS ========== */

    struct OrderTakeState {
        OrderTakeStatus status;
        address takerAddress;
        uint256 giveChainId;
    }

    /* ========== EVENTS ========== */

    event FulfilledOrder(DlnOrderLib.Order order, bytes32 orderId, address sender, address unlockAuthority);

    event DecreasedTakeAmount(bytes32 orderId, uint256 orderTakeFinalAmount);

    event SentOrderCancel(DlnOrderLib.Order order, bytes32 orderId, bytes cancelBeneficiary, bytes32 submissionId);

    event SentOrderUnlock(bytes32 orderId, bytes beneficiary, bytes32 submissionId);

    event SetDlnSourceAddress(uint256 chainIdFrom, bytes dlnSourceAddress, ChainEngine chainEngine);

    event MaxOrderCountPerBatchEvmUnlockChanged(uint256 oldValue, uint256 newValue);
    event MaxOrderCountPerBatchSolanaUnlockChanged(uint256 oldValue, uint256 newValue);

    /* ========== ERRORS ========== */

    error MismatchTakerAmount();
    error MismatchNativeTakerAmount();
    error WrongToken();
    error ExternalCallIsBlocked();
    error AllowOnlyForBeneficiary(bytes expectedBeneficiary);
    error UnexpectedBatchSize();
    error MismatchGiveChainId();
    error TransferAmountNotCoverFees();

    /* ========== CONSTRUCTOR  ========== */

    /// @dev Constructor that initializes the most important configurations.

    function initialize(IDeBridgeGate _deBridgeGate) public initializer {
        __DlnBase_init(_deBridgeGate);
        __ReentrancyGuard_init();
    }

    /* ========== PUBLIC METHODS ========== */

    /**
     * @inheritdoc IDlnDestination
     */
    function fulfillOrder(
        DlnOrderLib.Order memory _order,
        uint256 _fulFillAmount,
        bytes32 _orderId,
        bytes calldata _permitEnvelope,
        address _unlockAuthority
    ) external payable nonReentrant whenNotPaused {
        if (_order.externalCall.length > 0) revert ExternalCallIsBlocked();

        if (_order.takeChainId != getChainId()) revert WrongChain();
        bytes32 orderId = getOrderId(_order);
        if (orderId != _orderId) revert MismatchedOrderId();
        OrderTakeState storage orderState = takeOrders[orderId];
        // in dst chain order will start from 0-NotSet
        if (orderState.status != OrderTakeStatus.NotSet) revert IncorrectOrderStatus();
        // Check that the given unlock authority equals allowedTakerDst if allowedTakerDst was set
        if (
            _order.allowedTakerDst.length > 0 &&
            BytesLib.toAddress(_order.allowedTakerDst, 0) != _unlockAuthority
        ) revert Unauthorized();
        // amount that taker need to pay to fulfill order
        uint256 takerAmount = takePatches[orderId] == 0
            ? _order.takeAmount
            : _order.takeAmount - takePatches[orderId];
        // extra check that taker paid correct amount;
        if (takerAmount != _fulFillAmount) revert MismatchTakerAmount();

        address takeTokenAddress = BytesLib.toAddress(_order.takeTokenAddress, 0);

        if (takeTokenAddress == address(0)) {
            if (msg.value != takerAmount) revert MismatchNativeTakerAmount();
            _safeTransferETH(BytesLib.toAddress(_order.receiverDst, 0), takerAmount);
        }
        else
        {
            _executePermit(takeTokenAddress, _permitEnvelope);
            _safeTransferFrom(
                takeTokenAddress,
                msg.sender,
                BytesLib.toAddress(_order.receiverDst, 0),
                takerAmount
            );
        }
        //change order state to FulFilled
        orderState.status = OrderTakeStatus.Fulfilled;
        orderState.takerAddress = _unlockAuthority;
        orderState.giveChainId = _order.giveChainId;

        emit FulfilledOrder(_order, orderId, msg.sender, _unlockAuthority);
    }

    /// @dev Send unlock order in [`Order::give::chain_id`]
    ///
    /// If the order was filled and not unlocked yet, taker from [`TakeState::FulFilled { taker }`] can unlock it and get the give part in [`Order::give::chain_id`] chain
    /// In the receive chain, the [`dln::source::claim_unlock`] will be called
    ///
    /// @param _orderId Order id for unlock
    /// @param _beneficiary address that will receive give amount in give chain
    /// @param _executionFee execution fee for auto claim by keepers
    /// # Allowed
    /// By taker of order only
    function sendEvmUnlock(
        bytes32 _orderId,
        address _beneficiary,
        uint256 _executionFee
    ) external payable nonReentrant whenNotPaused {
        uint256 giveChainId = _prepareOrderStateForUnlock(_orderId, ChainEngine.EVM);
        // encode function that will be called in target chain
        bytes memory claimUnlockMethod = _encodeClaimUnlock(_orderId, _beneficiary);
        //send crosschain message through deBridgeGate
        bytes32 submissionId = _sendCrossChainMessage(
            giveChainId, // _chainIdTo
            abi.encodePacked(_beneficiary),
            _executionFee,
            claimUnlockMethod
        );

        emit SentOrderUnlock(_orderId, abi.encodePacked(_beneficiary), submissionId);
    }


    /// @dev Send batch unlock order in [`Order::give::chain_id`]
    ///
    /// If the order was filled and not unlocked yet, taker from [`TakeState::FulFilled { taker }`] can unlock it and get the give part in [`Order::give::chain_id`] chain
    /// In the receive chain, the [`dln::source::claim_unlock`] will be called
    ///
    /// @param _orderIds Order ids for unlock. Orders must have the same giveChainId
    /// @param _beneficiary address that will receive give amount in give chain
    /// @param _executionFee execution fee for auto claim by keepers
    /// # Allowed
    /// By taker of order only
    function sendBatchEvmUnlock(
        bytes32[] memory _orderIds,
        address _beneficiary,
        uint256 _executionFee
    ) external payable nonReentrant whenNotPaused {
        if (_orderIds.length == 0) revert UnexpectedBatchSize();
        if (_orderIds.length > maxOrderCountPerBatchEvmUnlock) revert UnexpectedBatchSize();

        uint256 giveChainId;
        uint256 length = _orderIds.length;
        for (uint256 i; i < length; ++i) {
            uint256 currentGiveChainId = _prepareOrderStateForUnlock(_orderIds[i], ChainEngine.EVM);
            if (i == 0) {
                giveChainId = currentGiveChainId;
            }
            else {
                // giveChainId must be the same for all orders
                if (giveChainId != currentGiveChainId) revert MismatchGiveChainId();
            }
        }
        // encode function that will be called in target chain
        bytes memory claimUnlockMethod = _encodeBatchClaimUnlock(_orderIds, _beneficiary);

        //send crosschain message through deBridgeGate
        bytes32 submissionId = _sendCrossChainMessage(
            giveChainId, // _chainIdTo
            abi.encodePacked(_beneficiary),
            _executionFee,
            claimUnlockMethod
        );

        for (uint256 i; i < length; ++i) {
            emit SentOrderUnlock(_orderIds[i], abi.encodePacked(_beneficiary), submissionId);
        }
    }

    /// @dev Send multiple claim_unlock instructions to unlock several orders in [`Order::give::chain_id`].
    /// @notice It is implied that all orders share the same giveChainId, giveTokenAddress and beneficiary, so that only one
    ///         init_wallet_if_needed instruction is used
    ///
    /// @param _orders Array of orders to unlock
    /// @param _beneficiary address that will receive give amount in give chain
    /// @param _executionFee execution fee for auto claim by keepers. This fee must cover a single _initWalletIfNeededInstructionReward
    ///                     and _claimUnlockInstructionReward * number of orders in this batch
    /// @param _initWalletIfNeededInstructionReward reward for executing init_wallet_if_needed instruction on Solana
    /// @param _claimUnlockInstructionReward reward for executing a single claim_unlock instruction on Solana. This method
    //                      sends as many claim_unlock instructions as the number of orders in this batch
    function sendBatchSolanaUnlock(
        DlnOrderLib.Order[] memory _orders,
        bytes32 _beneficiary,
        uint256 _executionFee,
        uint64 _initWalletIfNeededInstructionReward,
        uint64 _claimUnlockInstructionReward
    ) external payable nonReentrant whenNotPaused {
        if (_orders.length == 0) revert UnexpectedBatchSize();
        if (_orders.length > maxOrderCountPerBatchSolanaUnlock) revert UnexpectedBatchSize();
        // make sure execution fee covers rewards for single account initialisation instruction + claim_unlock for every order
        _validateSolanaRewards(msg.value, _executionFee, _initWalletIfNeededInstructionReward, uint64(_claimUnlockInstructionReward * _orders.length));

        uint256 giveChainId;
        bytes32 giveTokenAddress;
        bytes32 solanaSrcProgramId;
        bytes memory instructionsData;
        bytes32[] memory orderIds = new bytes32[](_orders.length);
        for (uint256 i; i < _orders.length; ++i) {
            DlnOrderLib.Order memory order = _orders[i];
            bytes32 orderId = getOrderId(order);
            orderIds[i] = orderId;
            _prepareOrderStateForUnlock(orderId, ChainEngine.SOLANA);

            if (i == 0) {
                // pre-cache giveChainId of the first order in a batch to ensure all other orders have the same giveChainId
                giveChainId = order.giveChainId;

                // pre-cache giveTokenAddress of the first order in a batch to ensure all other orders have the same giveTokenAddress
                // also, this value is used heavily when encoding instructions
                giveTokenAddress = BytesLib.toBytes32(order.giveTokenAddress, 0);

                // pre-cache solanaSrcProgramId because this value is used when encoding instructions
                solanaSrcProgramId = BytesLib.toBytes32(dlnSourceAddresses[order.giveChainId], 0);

                // first instruction must be account initializer.
                // actually by design, we must initialize account for every giveTokenAddress+beneficiary pair,
                // but right for simplicity reasons we assume that batches may contain orders with the same giveTokenAddress,
                // so only a single initialization is required
                instructionsData = EncodeSolanaDlnMessage.encodeInitWalletIfNeededInstruction(
                    _beneficiary,
                    giveTokenAddress,
                    _initWalletIfNeededInstructionReward
                );
            }
            else {
                // ensure every order is from the same chain
                if (order.giveChainId != giveChainId) revert WrongChain();

                // ensure every order has the same giveTokenAddress (otherwise, we may need to ensure this account is initalized)
                if (BytesLib.toBytes32(order.giveTokenAddress, 0) != giveTokenAddress) revert WrongToken();
            }

            // finally, add claim_unlock instruction for this order
            instructionsData = abi.encodePacked(
                instructionsData,
                EncodeSolanaDlnMessage.encodeClaimUnlockInstruction(
                    getChainId(), //_takeChainId,
                    solanaSrcProgramId, //_srcProgramId,
                    _beneficiary, //_actionBeneficiary,
                    giveTokenAddress, //_orderGiveTokenAddress,
                    orderId,
                    _claimUnlockInstructionReward
                )
            );
        }

        // send crosschain message through deBridgeGate
        bytes32 submissionId = _sendCrossChainMessage(
            giveChainId, // _chainIdTo
            abi.encodePacked(_beneficiary),
            _executionFee,
            instructionsData
        );

        // emit event for every order
        for (uint256 i; i < _orders.length; ++i) {
            emit SentOrderUnlock(orderIds[i], abi.encodePacked(_beneficiary), submissionId);
        }
    }


    /// @dev Send unlock order in [`Order::give::chain_id`]
    ///
    /// If the order was filled and not unlocked yet, taker from [`TakeState::FulFilled { taker }`] can unlock it and get the give part in [`Order::give::chain_id`] chain
    /// In the receive chain, the [`dln::source::claim_unlock`] will be called
    ///
    /// @param _order Order for unlock
    /// @param _beneficiary address that will receive give amount in give chain
    /// @param _executionFee execution fee for auto claim by keepers
    /// @param _initWalletIfNeededInstructionReward reward for executing init_wallet_if_needed instruction on Solana
    /// @param _claimUnlockInstructionReward reward for executing a single claim_unlock instruction on Solana
    /// # Allowed
    /// By taker of order only
    function sendSolanaUnlock(
        DlnOrderLib.Order memory _order,
        bytes32 _beneficiary,
        uint256 _executionFee,
        uint64 _initWalletIfNeededInstructionReward,
        uint64 _claimUnlockInstructionReward
    ) external payable nonReentrant whenNotPaused {
        _validateSolanaRewards(msg.value, _executionFee, _initWalletIfNeededInstructionReward, _claimUnlockInstructionReward);

        bytes32 orderId = getOrderId(_order);
        uint256 giveChainId = _prepareOrderStateForUnlock(orderId, ChainEngine.SOLANA);

        // encode function that will be called in target chain
        bytes32 giveTokenAddress = BytesLib.toBytes32(_order.giveTokenAddress, 0);
        bytes memory instructionsData = abi.encodePacked(
            EncodeSolanaDlnMessage.encodeInitWalletIfNeededInstruction(
                    _beneficiary,
                    giveTokenAddress,
                    _initWalletIfNeededInstructionReward
            ),
            EncodeSolanaDlnMessage.encodeClaimUnlockInstruction(
                getChainId(), //_takeChainId,
                BytesLib.toBytes32(dlnSourceAddresses[giveChainId], 0), //_srcProgramId,
                _beneficiary, //_actionBeneficiary,
                giveTokenAddress, //_orderGiveTokenAddress,
                orderId,
                _claimUnlockInstructionReward
            )
        );
        //send crosschain message through deBridgeGate
        bytes32 submissionId = _sendCrossChainMessage(
            giveChainId, // _chainIdTo
            abi.encodePacked(_beneficiary),
            _executionFee,
            instructionsData
        );

        emit SentOrderUnlock(orderId, abi.encodePacked(_beneficiary), submissionId);
    }


    /// @dev Send cancel order in [`Order::give::chain_id`]
    ///
    /// If the order was not filled or canceled earlier, [`Order::order_authority_address_dst`] can cancel it and get back the give part in [`Order::give::chain_id`] chain
    /// In the receive chain, the [`dln::source::claim_order_cancel`] will be called
    ///
    /// @param _order Full order for patch
    /// @param _cancelBeneficiary address that will receive refund in give chain chain
    ///     * If [`Order::allowed_cancel_beneficiary`] is None then any [`Address`]
    ///     * If [`Order::allowed_cancel_beneficiary`] is Some then only itself
    /// @param _executionFee execution fee for auto claim by keepers
    /// # Allowed
    /// By [`Order::order_authority_address_dst`] only
    function sendEvmOrderCancel(
        DlnOrderLib.Order memory _order,
        address _cancelBeneficiary,
        uint256 _executionFee
    ) external payable nonReentrant whenNotPaused {
        if (_order.takeChainId != getChainId()) revert WrongChain();
        if (chainEngines[_order.giveChainId]  != ChainEngine.EVM) revert WrongChain();
        bytes32 orderId = getOrderId(_order);
        if (BytesLib.toAddress(_order.orderAuthorityAddressDst, 0) != msg.sender)
            revert Unauthorized();

        if (_order.allowedCancelBeneficiarySrc.length > 0
            && BytesLib.toAddress(_order.allowedCancelBeneficiarySrc, 0) != _cancelBeneficiary) {
            revert AllowOnlyForBeneficiary(_order.allowedCancelBeneficiarySrc);
        }

        OrderTakeState storage orderState = takeOrders[orderId];
        //In dst chain order will start from 0-NotSet
        if (orderState.status != OrderTakeStatus.NotSet) revert IncorrectOrderStatus();
        orderState.status = OrderTakeStatus.SentCancel;

        // encode function that will be called in target chain
        bytes memory claimCancelMethod = _encodeClaimCancel(orderId, _cancelBeneficiary);
        //send crosschain message through deBridgeGate
        bytes32 submissionId = _sendCrossChainMessage(
            _order.giveChainId, // _chainIdTo
            abi.encodePacked(_cancelBeneficiary),
            _executionFee,
            claimCancelMethod
        );
        emit SentOrderCancel(_order, orderId, abi.encodePacked(_cancelBeneficiary), submissionId);
    }

    /// @dev Send cancel order in [`Order::give::chain_id`]
    ///
    /// If the order was not filled or canceled earlier, [`Order::order_authority_address_dst`] can cancel it and get back the give part in [`Order::give::chain_id`] chain
    /// In the receive chain, the [`dln::source::claim_order_cancel`] will be called
    ///
    /// @param _order Full order for patch
    /// @param _cancelBeneficiary address that will receive refund in give chain chain
    ///     * If [`Order::allowed_cancel_beneficiary`] is None then any [`Address`]
    ///     * If [`Order::allowed_cancel_beneficiary`] is Some then only itself
    /// @param _executionFee execution fee for auto claim by keepers
    /// # Allowed
    /// By [`Order::order_authority_address_dst`] only
    function sendSolanaOrderCancel(
        DlnOrderLib.Order memory _order,
        bytes32 _cancelBeneficiary,
        uint256 _executionFee,
        uint64 _reward1,
        uint64 _reward2
    ) external payable nonReentrant whenNotPaused {
        _validateSolanaRewards(msg.value, _executionFee, _reward1, _reward2);

        if (chainEngines[_order.giveChainId]  != ChainEngine.SOLANA) revert WrongChain();
        if (_order.takeChainId != getChainId()) revert WrongChain();
        bytes memory solanaSrcProgramId = dlnSourceAddresses[_order.giveChainId];
        if (solanaSrcProgramId.length != SOLANA_ADDRESS_LENGTH) revert WrongChain();

        bytes32 orderId = getOrderId(_order);
        if (BytesLib.toAddress(_order.orderAuthorityAddressDst, 0) != msg.sender)
            revert Unauthorized();

        if (_order.allowedCancelBeneficiarySrc.length > 0
            && BytesLib.toBytes32(_order.allowedCancelBeneficiarySrc, 0) != _cancelBeneficiary) {
            revert AllowOnlyForBeneficiary(_order.allowedCancelBeneficiarySrc);
        }

        OrderTakeState storage orderState = takeOrders[orderId];
        //In dst chain order will start from 0-NotSet
        if (orderState.status != OrderTakeStatus.NotSet) revert IncorrectOrderStatus();
        orderState.status = OrderTakeStatus.SentCancel;

        // encode function that will be called in target chain
        bytes32 _orderGiveTokenAddress = BytesLib.toBytes32(_order.giveTokenAddress, 0);
        bytes memory claimCancelMethod = abi.encodePacked(
            EncodeSolanaDlnMessage.encodeInitWalletIfNeededInstruction(
                    _cancelBeneficiary,
                    _orderGiveTokenAddress,
                    _reward1
            ),
            EncodeSolanaDlnMessage.encodeClaimCancelInstruction(
                getChainId(), //_takeChainId,
                BytesLib.toBytes32(solanaSrcProgramId, 0), //_srcProgramId,
                _cancelBeneficiary, //_actionBeneficiary,
                _orderGiveTokenAddress, //_orderGiveTokenAddress,
                orderId,
                _reward2
            )
        );
        //send crosschain message through deBridgeGate
        bytes32 submissionId = _sendCrossChainMessage(
            _order.giveChainId, // _chainIdTo
            abi.encodePacked(_cancelBeneficiary),
            _executionFee,
            claimCancelMethod
        );

        emit SentOrderCancel(_order, orderId, abi.encodePacked(_cancelBeneficiary), submissionId);
    }

    /// @dev Patch take offer of order
    ///
    /// To increase the profitability of the order, subtraction amount from the take part
    /// If a patch was previously made, then the new patch can only increase the subtraction
    ///
    /// @param _order Full order for patch
    /// @param _newSubtrahend Amount to remove from [`Order::take::amount`] for use in [`fulfill_order`] methods
    /// # Allowed
    /// Only [`Order::order_authority_address_dst`]
    function patchOrderTake(DlnOrderLib.Order memory _order, uint256 _newSubtrahend)
        external
        nonReentrant
        whenNotPaused
    {
        if (_order.takeChainId != getChainId()) revert WrongChain();
        bytes32 orderId = getOrderId(_order);
        if (BytesLib.toAddress(_order.orderAuthorityAddressDst, 0) != msg.sender)
            revert Unauthorized();
        if (takePatches[orderId] >= _newSubtrahend) revert WrongArgument();
        if (_order.takeAmount <= _newSubtrahend) revert WrongArgument();
        //In dst chain order will start from 0-NotSet
        if (takeOrders[orderId].status != OrderTakeStatus.NotSet) revert IncorrectOrderStatus();

        takePatches[orderId] = _newSubtrahend;
        emit DecreasedTakeAmount(orderId, _order.takeAmount - takePatches[orderId]);
    }

    /* ========== ADMIN METHODS ========== */

    function setDlnSourceAddress(uint256 _chainIdFrom, bytes memory _dlnSourceAddress, ChainEngine _chainEngine)
        external
        onlyAdmin
    {
        if(_chainEngine == ChainEngine.UNDEFINED) revert WrongArgument();
        dlnSourceAddresses[_chainIdFrom] = _dlnSourceAddress;
        chainEngines[_chainIdFrom] = _chainEngine;
        emit SetDlnSourceAddress(_chainIdFrom, _dlnSourceAddress, _chainEngine);
    }


    function setMaxOrderCountsPerBatch(uint256 _newEvmCount, uint256 _newSolanaCount) external onlyAdmin {
        // Setting and emitting for EVM count
        uint256 oldEvmValue = maxOrderCountPerBatchEvmUnlock;
        maxOrderCountPerBatchEvmUnlock = _newEvmCount;
        if(oldEvmValue != _newEvmCount) {
            emit MaxOrderCountPerBatchEvmUnlockChanged(oldEvmValue, _newEvmCount);
        }

        // Setting and emitting for Solana count
        uint256 oldSolanaValue = maxOrderCountPerBatchSolanaUnlock;
        maxOrderCountPerBatchSolanaUnlock = _newSolanaCount;
        if(oldSolanaValue != _newSolanaCount) {
            emit MaxOrderCountPerBatchSolanaUnlockChanged(oldSolanaValue, _newSolanaCount);
        }
    }
    
    /* ==========  Private methods ========== */

    /// @dev Change order status from Fulfilled to SentUnlock
    /// @notice Allowed by taker of order only
    /// @notice Works only for evm giveChainId
    /// @param _orderId orderId
    /// @return giveChainId
    function _prepareOrderStateForUnlock(bytes32 _orderId, ChainEngine _chainEngine) internal
        returns (uint256) {
        OrderTakeState storage orderState = takeOrders[_orderId];
        if (orderState.status != OrderTakeStatus.Fulfilled) revert IncorrectOrderStatus();
        if (orderState.takerAddress != msg.sender) revert Unauthorized();
        if (chainEngines[orderState.giveChainId] != _chainEngine) revert WrongChain();
        orderState.status = OrderTakeStatus.SentUnlock;
        return orderState.giveChainId;
    }

    function _encodeClaimUnlock(bytes32 _orderId, address _beneficiary)
        internal
        pure
        returns (bytes memory)
    {
        //claimUnlock(bytes32 _orderId, address _beneficiary)
        return abi.encodeWithSelector(DlnSource.claimUnlock.selector, _orderId, _beneficiary);
    }

    function _encodeBatchClaimUnlock(bytes32[] memory _orderIds, address _beneficiary)
        internal
        pure
        returns (bytes memory)
    {
        //claimBatchUnlock(bytes32[] memory _orderIds, address _beneficiary)
        return abi.encodeWithSelector(DlnSource.claimBatchUnlock.selector, _orderIds, _beneficiary);
    }


    function _encodeClaimCancel(bytes32 _orderId, address _beneficiary)
        internal
        pure
        returns (bytes memory)
    {
        //claimCancel(bytes32 _orderId, address _beneficiary)
        return abi.encodeWithSelector(DlnSource.claimCancel.selector, _orderId, _beneficiary);
    }

    function _encodeAutoParamsTo(
        bytes memory _data,
        uint256 _executionFee,
        bytes memory _fallbackAddress
    ) internal pure returns (bytes memory) {
        IDeBridgeGate.SubmissionAutoParamsTo memory autoParams;
        autoParams.flags = Flags.setFlag(autoParams.flags, Flags.REVERT_IF_EXTERNAL_FAIL, true);
        autoParams.flags = Flags.setFlag(autoParams.flags, Flags.PROXY_WITH_SENDER, true);

        // fallbackAddress won't be used because of REVERT_IF_EXTERNAL_FAIL flag
        // also it make no sense to use it because it's only for ERC20 tokens
        // autoParams.fallbackAddress = abi.encodePacked(address(0));
        autoParams.fallbackAddress = _fallbackAddress;
        autoParams.data = _data;
        autoParams.executionFee = _executionFee;
        return abi.encode(autoParams);
    }

    /// @dev Validate that the amount will suffice to cover all execution rewards.
    /// @param _inputAmount Transferring an amount sufficient to cover the execution fee and all rewards.
    /// @param _executionFee execution fee for claim
    /// @param _solanaExternalCallReward1 Fee for executing external call 1
    /// @param _solanaExternalCallReward2 Fee for executing external call 2
    function _validateSolanaRewards (
        uint256 _inputAmount,
        uint256 _executionFee,
        uint64 _solanaExternalCallReward1,
        uint64 _solanaExternalCallReward2
    ) internal view {
        uint256 transferFeeBPS = deBridgeGate.globalTransferFeeBps();
        uint256 fixFee = deBridgeGate.globalFixedNativeFee();
        if (_inputAmount < fixFee) revert TransferAmountNotCoverFees();
        uint256 transferFee = transferFeeBPS * (_inputAmount - fixFee) / BPS_DENOMINATOR;
        if (_inputAmount / NATIVE_AMOUNT_DIVIDER_FOR_TRANSFER_TO_SOLANA < (fixFee + transferFee + _executionFee) / NATIVE_AMOUNT_DIVIDER_FOR_TRANSFER_TO_SOLANA
                                                        + _solanaExternalCallReward1 + _solanaExternalCallReward2) {
            revert TransferAmountNotCoverFees();
        }
    }

    function _sendCrossChainMessage(
        uint256 _chainIdTo,
        bytes memory _fallbackAddress,
        uint256 _executionFee,
        bytes memory _data
    ) internal returns (bytes32) {
        bytes memory srcAddress = dlnSourceAddresses[_chainIdTo];
        bytes memory autoParams = _encodeAutoParamsTo(_data, _executionFee, _fallbackAddress);
        {
            ChainEngine _targetEngine = chainEngines[_chainIdTo];

            if (_targetEngine == ChainEngine.EVM ) {
                if (srcAddress.length != EVM_ADDRESS_LENGTH) revert WrongAddressLength();
                if (_fallbackAddress.length != EVM_ADDRESS_LENGTH) revert WrongAddressLength();
            }
            else if (_targetEngine == ChainEngine.SOLANA ) {
                if (srcAddress.length != SOLANA_ADDRESS_LENGTH) revert WrongAddressLength();
                if (_fallbackAddress.length != SOLANA_ADDRESS_LENGTH) revert WrongAddressLength();
            }
            else {
                revert UnknownEngine();
            }
        }

        return deBridgeGate.send{value: msg.value}(
            address(0), // _tokenAddress
            msg.value, // _amount
            _chainIdTo, // _chainIdTo
            srcAddress, // _receiver
            "", // _permit
            false, // _useAssetFee
            0, // _referralCode
            autoParams // _autoParams
        );
    }

    /* ========== Version Control ========== */

    /// @dev Get this contract's version
    function version() external pure returns (string memory) {
        return "1.2.0";
    }
}
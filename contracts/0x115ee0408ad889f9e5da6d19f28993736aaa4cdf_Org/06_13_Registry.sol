//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import { Math } from "./lib/Math.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { Auth, Authority } from "./lib/auth/Auth.sol"; 
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";

import { RegistryAuth } from "./RegistryAuth.sol";
import { Entity } from "./Entity.sol";
import { ISwapWrapper } from "./interfaces/ISwapWrapper.sol";
import { Portfolio } from "./Portfolio.sol";

// --- Errors ---
error Unauthorized();
error UnsupportedSwapper();

/**
 * @notice Registry entity - manages Factory and Entity state info.
 */
contract Registry is RegistryAuth {

    // --- Storage ---

    /// @notice Treasury address can receives fees.
    address public treasury;

    /// @notice Base Token address is the stable coin contract used throughout the system.
    ERC20 public immutable baseToken;

    /// @notice Mapping of approved factory contracts that are allowed to register new Entities.
    mapping (address => bool) public isApprovedFactory;
    /// @notice Mapping of active status of entities.
    mapping (Entity => bool) public isActiveEntity;

    /// @notice Maps entity type to donation fee percentage stored as a zoc, where type(uint32).max represents 0.
    mapping (uint8 => uint32) defaultDonationFee;
    /// @notice Maps specific entity receiver to donation fee percentage stored as a zoc.
    mapping (Entity => uint32) donationFeeReceiverOverride;

    /// @notice Maps entity type to payout fee percentage stored as a zoc, where type(uint32).max represents 0.
    mapping (uint8 => uint32) defaultPayoutFee;
    /// @notice Maps specific entity sender to payout fee percentage stored as a zoc.
    mapping (Entity => uint32) payoutFeeOverride;

    /// @notice Maps sender entity type to receiver entity type to fee percentage as a zoc.
    mapping (uint8 => mapping(uint8 => uint32)) defaultTransferFee;
    /// @notice Maps specific entity sender to receiver entity type to fee percentage as a zoc.
    mapping (Entity => mapping(uint8 => uint32)) transferFeeSenderOverride;
    /// @notice Maps sender entity type to specific entity receiver to fee percentage as a zoc.
    mapping (uint8 => mapping(Entity => uint32)) transferFeeReceiverOverride;
    /// @notice Maps swap wrappers to their enabled/disabled status.

    mapping (ISwapWrapper => bool) public isSwapperSupported;
    /// @notice Maps portfolios to their enabled/disabled status.
    mapping (Portfolio => bool) public isActivePortfolio;

    // --- Events ---

    /// @notice The event emitted when a factory is approved (whitelisted) or has it's approval removed.
    event FactoryApprovalSet(address indexed factory, bool isApproved);

    /// @notice The event emitted when an entity is set active or inactive.
    event EntityStatusSet(address indexed entity, bool isActive);

    /// @notice The event emitted when a swap wrapper is set active or inactive.
    event SwapWrapperStatusSet(address indexed swapWrapper, bool isSupported);

    /// @notice The event emitted when a portfolio is set active or inactive.
    event PortfolioStatusSet(address indexed portfolio, bool isActive);

    /// @notice Emitted when a default donation fee is set for an entity type.
    event DefaultDonationFeeSet(uint8 indexed entityType, uint32 fee);

    /// @notice Emitted when a donation fee override is set for a specific receiving entity.
    event DonationFeeReceiverOverrideSet(address indexed entity, uint32 fee);

    /// @notice Emitted when a default payout fee is set for an entity type.
    event DefaultPayoutFeeSet(uint8 indexed entityType, uint32 fee);

    /// @notice Emitted when a payout fee override is set for a specific sender entity.
    event PayoutFeeOverrideSet(address indexed entity, uint32 fee);

    /// @notice Emitted when a default transfer fee is set for transfers between entity types.
    event DefaultTransferFeeSet(uint8 indexed fromEntityType, uint8 indexed toEntityType, uint32 fee);

    /// @notice Emitted when a transfer fee override is set for transfers from an entity to a specific entityType.
    event TransferFeeSenderOverrideSet(address indexed fromEntity, uint8 indexed toEntityType, uint32 fee);

    /// @notice Emitted when a transfer fee override is set for transfers from an entityType to an entity.
    event TransferFeeReceiverOverrideSet(uint8 indexed fromEntityType, address indexed toEntity, uint32 fee);

    /// @notice Emitted when the registry treasury contract is changed
    event TreasuryChanged(address oldTreasury, address indexed newTreasury);

    /**
     * @notice Modifier for methods that require auth and that the manager cannot access.
     * @dev Overridden from Auth.sol. Reason: use custom error.
     */
    modifier requiresAuth override {
        if(!isAuthorized(msg.sender, msg.sig)) revert Unauthorized();

        _;
    }

    // --- Constructor ---
    constructor(address _admin, address _treasury, ERC20 _baseToken) RegistryAuth(_admin, Authority(address(this))) {
        treasury = _treasury;
        emit TreasuryChanged(address(0), _treasury);
        baseToken = _baseToken;
    }

    // --- Internal fns ---

    /**
     * @notice Fee parsing to convert the special "type(uint32).max" value to zero, and zero to the "max".
     * @dev After converting, "type(uint32).max" will cause overflow/revert when used as a fee percentage multiplier and zero will mean no fee.
     * @param _value The value to be converted.
     * @return The parsed fee to use.
     */
    function _parseFeeWithFlip(uint32 _value) private pure returns (uint32) {
        if (_value == 0) {
            return type(uint32).max;
        } else if (_value == type(uint32).max) {
            return 0;
        } else {
            return _value;
        }
    }

    // --- External fns ---

    /**
     * @notice Sets a new Endaoment treasury address.
     * @param _newTreasury The new treasury.
     */
     function setTreasury(address _newTreasury) external requiresAuth {
         emit TreasuryChanged(treasury, _newTreasury);
         treasury = _newTreasury;
     }

    /**
     * @notice Sets the approval state of a factory. Grants the factory permissions to set entity status.
     * @param _factory The factory whose approval state is to be updated.
     * @param _isApproved True if the factory should be approved, false otherwise.
     */
    function setFactoryApproval(address _factory, bool _isApproved) external requiresAuth {
        isApprovedFactory[_factory] = _isApproved;
        emit FactoryApprovalSet(address(_factory), _isApproved);
    }

    /**
     * @notice Sets the enable/disable state of an Entity.
     * @param _entity The entity whose active state is to be updated.
     * @param _isActive True if the entity should be active, false otherwise.
     */
    function setEntityStatus(Entity _entity, bool _isActive) external requiresAuth {
        isActiveEntity[_entity] = _isActive;
        emit EntityStatusSet(address(_entity), _isActive);
    }

    /**
     * @notice Sets Entity as active. This is a special method to be called only by approved factories.
     * Other callers should use `setEntityStatus` instead.
     * @param _entity The entity.
     */
    function setEntityActive(Entity _entity) external {
        if(!isApprovedFactory[msg.sender]) revert Unauthorized();
        isActiveEntity[_entity] = true;
        emit EntityStatusSet(address(_entity), true);
    }

    /**
     * @notice Sets the enable/disable state of a Portfolio.
     * @param _portfolio Portfolio.
     * @param _isActive True if setting portfolio to active, false otherwise.
     */
    function setPortfolioStatus(Portfolio _portfolio, bool _isActive) external requiresAuth {
        isActivePortfolio[_portfolio] = _isActive;
        emit PortfolioStatusSet(address(_portfolio), _isActive);
    }

    /**
     * @notice Gets default donation fee pct (as a zoc) for an Entity.
     * @param _entity The receiving entity of the donation for which the fee is being fetched.
     * @return uint32 The default donation fee for the entity's type.
     * @dev Makes use of _parseFeeWithFlip, so if no default exists, "max" will be returned.
     */
    function getDonationFee(Entity _entity) external view returns (uint32) {
       return _parseFeeWithFlip(defaultDonationFee[_entity.entityType()]);
    }

    /**
     * @notice Gets lowest possible donation fee pct (as a zoc) for an Entity, among default and override.
     * @param _entity The receiving entity of the donation for which the fee is being fetched.
     * @return uint32 The minimum of the default donation fee and the receiver's fee override.
     * @dev Makes use of _parseFeeWithFlip, so if no default or override exists, "max" will be returned.
     */
    function getDonationFeeWithOverrides(Entity _entity) external view returns (uint32) {
        uint32 _default = _parseFeeWithFlip(defaultDonationFee[_entity.entityType()]);
        uint32 _receiverOverride = _parseFeeWithFlip(donationFeeReceiverOverride[_entity]);
        return _receiverOverride < _default ? _receiverOverride : _default;
    }

    /**
     * @notice Gets default payout fee pct (as a zoc) for an Entity.
     * @param _entity The sender entity of the payout for which the fee is being fetched.
     * @return uint32 The default payout fee for the entity's type.
     * @dev Makes use of _parseFeeWithFlip, so if no default exists, "max" will be returned.
     */
    function getPayoutFee(Entity _entity) external view returns (uint32) {
       return _parseFeeWithFlip(defaultPayoutFee[_entity.entityType()]);
    }

    /**
     * @notice Gets lowest possible payout fee pct (as a zoc) for an Entity, among default and override.
     * @param _entity The sender entity of the payout for which the fee is being fetched.
     * @return uint32 The minimum of the default payout fee and the sender's fee override.
     * @dev Makes use of _parseFeeWithFlip, so if no default or override exists, "max" will be returned.
     */
    function getPayoutFeeWithOverrides(Entity _entity) external view returns (uint32) {
        uint32 _default = _parseFeeWithFlip(defaultPayoutFee[_entity.entityType()]);
        uint32 _senderOverride = _parseFeeWithFlip(payoutFeeOverride[_entity]);
        return _senderOverride < _default ? _senderOverride : _default;
    }

    /**
     * @notice Gets default transfer fee pct (as a zoc) between sender & receiver Entities.
     * @param _sender The sending entity of the transfer for which the fee is being fetched.
     * @param _receiver The receiving entity of the transfer for which the fee is being fetched.
     * @return uint32 The default transfer fee.
     * @dev Makes use of _parseFeeWithFlip, so if no default exists, "type(uint32).max" will be returned.
     */
    function getTransferFee(Entity _sender, Entity _receiver) external view returns (uint32) {
        return _parseFeeWithFlip(defaultTransferFee[_sender.entityType()][_receiver.entityType()]);
    }

    /**
     * @notice Gets lowest possible transfer fee pct (as a zoc) between sender & receiver Entities, among default and overrides.
     * @param _sender The sending entity of the transfer for which the fee is being fetched.
     * @param _receiver The receiving entity of the transfer for which the fee is being fetched.
     * @return uint32 The minimum of the default transfer fee, and sender and receiver overrides.
     * @dev Makes use of _parseFeeWithFlip, so if no default or overrides exist, "type(uint32).max" will be returned.
     */
    function getTransferFeeWithOverrides(Entity _sender, Entity _receiver) external view returns (uint32) {
        uint32 _default = _parseFeeWithFlip(defaultTransferFee[_sender.entityType()][_receiver.entityType()]);
        uint32 _senderOverride = _parseFeeWithFlip(transferFeeSenderOverride[_sender][_receiver.entityType()]);
        uint32 _receiverOverride = _parseFeeWithFlip(transferFeeReceiverOverride[_sender.entityType()][_receiver]);

        uint32 _lowestFee = _default;
        _lowestFee = _senderOverride < _lowestFee ? _senderOverride : _lowestFee;
        _lowestFee = _receiverOverride < _lowestFee ? _receiverOverride : _lowestFee;
        return _lowestFee;
    }

    /**
     * @notice Sets the default donation fee for an entity type.
     * @param _entityType Entity type.
     * @param _fee The fee percentage to be set (a zoc).
     */
    function setDefaultDonationFee(uint8 _entityType, uint32 _fee) external requiresAuth {
        defaultDonationFee[_entityType] = _parseFeeWithFlip(_fee);
        emit DefaultDonationFeeSet(_entityType, _fee);
    }

    /**
     * @notice Sets the donation fee receiver override for a specific entity.
     * @param _entity Entity.
     * @param _fee The overriding fee (a zoc).
     */
    function setDonationFeeReceiverOverride(Entity _entity, uint32 _fee) external requiresAuth {
        donationFeeReceiverOverride[_entity] = _parseFeeWithFlip(_fee);
        emit DonationFeeReceiverOverrideSet(address(_entity), _fee);
    }

    /**
     * @notice Sets the default payout fee for an entity type.
     * @param _entityType Entity type.
     * @param _fee The fee percentage to be set (a zoc).
     */
    function setDefaultPayoutFee(uint8 _entityType, uint32 _fee) external requiresAuth {
        defaultPayoutFee[_entityType] = _parseFeeWithFlip(_fee);
        emit DefaultPayoutFeeSet(_entityType, _fee);
    }

    /**
     * @notice Sets the payout fee override for a specific entity.
     * @param _entity Entity.
     * @param _fee The overriding fee (a zoc).
     */
    function setPayoutFeeOverride(Entity _entity, uint32 _fee) external requiresAuth {
        payoutFeeOverride[_entity] = _parseFeeWithFlip(_fee);
        emit PayoutFeeOverrideSet(address(_entity), _fee);
    }

    /**
     * @notice Sets the default transfer fee for transfers from one specific entity type to another.
     * @param _fromEntityType The entityType making the transfer.
     * @param _toEntityType The receiving entityType.
     * @param _fee The transfer fee percentage (a zoc).
     */
    function setDefaultTransferFee(uint8 _fromEntityType, uint8 _toEntityType, uint32 _fee) external requiresAuth {
        defaultTransferFee[_fromEntityType][_toEntityType] = _parseFeeWithFlip(_fee);
        emit DefaultTransferFeeSet(_fromEntityType, _toEntityType, _fee);
    }

    /**
     * @notice Sets the transfer fee override for transfers from one specific entity to entities of a given type.
     * @param _fromEntity The entity making the transfer.
     * @param _toEntityType The receiving entityType.
     * @param _fee The overriding fee percentage (a zoc).
     */
    function setTransferFeeSenderOverride(Entity _fromEntity, uint8 _toEntityType, uint32 _fee) external requiresAuth {
        transferFeeSenderOverride[_fromEntity][_toEntityType] = _parseFeeWithFlip(_fee);
        emit TransferFeeSenderOverrideSet(address(_fromEntity), _toEntityType, _fee);
    }

    /**
     * @notice Sets the transfer fee override for transfers from entities of a given type to a specific entity.
     * @param _fromEntityType The entityType making the transfer.
     * @param _toEntity The receiving entity.
     * @param _fee The overriding fee percentage (a zoc).
     */
    function setTransferFeeReceiverOverride(uint8 _fromEntityType, Entity _toEntity, uint32 _fee) external requiresAuth {
        transferFeeReceiverOverride[_fromEntityType][_toEntity] = _parseFeeWithFlip(_fee);
        emit TransferFeeReceiverOverrideSet(_fromEntityType, address(_toEntity), _fee);
    }

    /**
     * @notice Sets the enable/disable state of a SwapWrapper. System owners must ensure meticulous review of SwapWrappers before approving them.
     * @param _swapWrapper A contract that implements ISwapWrapper.
     * @param _supported `true` if supported, `false` if unsupported.
     */
    function setSwapWrapperStatus(ISwapWrapper _swapWrapper, bool _supported) external requiresAuth {
        isSwapperSupported[_swapWrapper] = _supported;
        emit SwapWrapperStatusSet(address(_swapWrapper), _supported);
    }
}
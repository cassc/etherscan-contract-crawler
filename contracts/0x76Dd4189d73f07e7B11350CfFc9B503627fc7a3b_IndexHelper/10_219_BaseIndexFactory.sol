// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./libraries/BP.sol";
import "./libraries/AUMCalculationLibrary.sol";

import "./interfaces/IIndexFactory.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/IvTokenFactory.sol";

/// @title Base index factory
/// @notice Contains logic for initial fee management for indexes which will be created by this factory
/// @dev Specified fee is minted to factory address and could be withdrawn through withdrawToFeePool method
abstract contract BaseIndexFactory is IIndexFactory, ERC165 {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    /// @notice 10% in base point format
    uint public constant MAX_FEE_IN_BP = 1000;

    /// @notice 10% in AUM Scaled units
    uint public constant MAX_AUM_FEE = 1000000003340960040392850629;

    /// @notice Role allows configure index related data/components
    bytes32 internal immutable INDEX_MANAGER_ROLE;
    /// @notice Role allows configure fee related data/components
    bytes32 internal immutable FEE_MANAGER_ROLE;
    /// @notice Asset role
    bytes32 internal immutable ASSET_ROLE;
    /// @notice Role allows index creation
    bytes32 internal immutable INDEX_CREATOR_ROLE;

    /// @inheritdoc IIndexFactory
    uint public override defaultAUMScaledPerSecondsRate;
    /// @inheritdoc IIndexFactory
    uint16 public override defaultMintingFeeInBP;
    /// @inheritdoc IIndexFactory
    uint16 public override defaultBurningFeeInBP;

    /// @inheritdoc IIndexFactory
    address public override reweightingLogic;
    /// @inheritdoc IIndexFactory
    address public immutable override registry;
    /// @inheritdoc IIndexFactory
    address public immutable override vTokenFactory;

    /// @notice Checks if provided value is lower than 10% in base point format
    modifier isValidFee(uint16 _value) {
        require(_value <= MAX_FEE_IN_BP, "IndexFactory: INVALID");
        _;
    }

    /// @notice Checks if msg.sender has administrator's permissions
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "IndexFactory: FORBIDDEN");
        _;
    }

    constructor(
        address _registry,
        address _vTokenFactory,
        address _reweightingLogic,
        uint16 _defaultMintingFeeInBP,
        uint16 _defaultBurningFeeInBP,
        uint _defaultAUMScaledPerSecondsRate
    ) {
        require(
            _defaultMintingFeeInBP <= MAX_FEE_IN_BP &&
                _defaultBurningFeeInBP <= MAX_FEE_IN_BP &&
                _defaultAUMScaledPerSecondsRate <= MAX_AUM_FEE &&
                _defaultAUMScaledPerSecondsRate >= AUMCalculationLibrary.RATE_SCALE_BASE,
            "IndexFactory: INVALID"
        );

        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(
            _vTokenFactory.supportsInterface(type(IvTokenFactory).interfaceId) &&
                _registry.supportsAllInterfaces(interfaceIds),
            "IndexFactory: INTERFACE"
        );

        INDEX_MANAGER_ROLE = keccak256("INDEX_MANAGER_ROLE");
        FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
        ASSET_ROLE = keccak256("ASSET_ROLE");
        INDEX_CREATOR_ROLE = keccak256("INDEX_CREATOR_ROLE");

        registry = _registry;
        vTokenFactory = _vTokenFactory;
        defaultMintingFeeInBP = _defaultMintingFeeInBP;
        defaultBurningFeeInBP = _defaultBurningFeeInBP;
        defaultAUMScaledPerSecondsRate = _defaultAUMScaledPerSecondsRate;
        reweightingLogic = _reweightingLogic;

        emit SetVTokenFactory(_vTokenFactory);
    }

    /// @inheritdoc IIndexFactory
    function setDefaultMintingFeeInBP(uint16 _mintingFeeInBP)
        external
        override
        onlyRole(FEE_MANAGER_ROLE)
        isValidFee(_mintingFeeInBP)
    {
        defaultMintingFeeInBP = _mintingFeeInBP;
        emit SetDefaultMintingFeeInBP(msg.sender, _mintingFeeInBP);
    }

    /// @inheritdoc IIndexFactory
    function setDefaultBurningFeeInBP(uint16 _burningFeeInBP)
        external
        override
        onlyRole(FEE_MANAGER_ROLE)
        isValidFee(_burningFeeInBP)
    {
        defaultBurningFeeInBP = _burningFeeInBP;
        emit SetDefaultBurningFeeInBP(msg.sender, _burningFeeInBP);
    }

    /// @inheritdoc IIndexFactory
    function setDefaultAUMScaledPerSecondsRate(uint _AUMScaledPerSecondsRate)
        external
        override
        onlyRole(FEE_MANAGER_ROLE)
    {
        require(
            _AUMScaledPerSecondsRate <= MAX_AUM_FEE &&
                _AUMScaledPerSecondsRate >= AUMCalculationLibrary.RATE_SCALE_BASE,
            "IndexFactory: INVALID"
        );

        defaultAUMScaledPerSecondsRate = _AUMScaledPerSecondsRate;
        emit SetDefaultAUMScaledPerSecondsRate(msg.sender, _AUMScaledPerSecondsRate);
    }

    /// @inheritdoc IIndexFactory
    function withdrawToFeePool(address _index) external override {
        require(msg.sender == IIndexRegistry(registry).feePool(), "IndexFactory: FORBIDDEN");

        uint amount = IERC20(_index).balanceOf(address(this));
        if (amount != 0) {
            IERC20(_index).safeTransfer(msg.sender, amount);
        }
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IIndexFactory).interfaceId || super.supportsInterface(_interfaceId);
    }
}
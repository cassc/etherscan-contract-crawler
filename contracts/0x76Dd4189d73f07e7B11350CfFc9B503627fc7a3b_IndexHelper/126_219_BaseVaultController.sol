// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "./libraries/BP.sol";

import "./interfaces/IvToken.sol";
import "./interfaces/IVaultController.sol";

/// @title Base vault controller
/// @notice Contains common logic for VaultControllers
abstract contract BaseVaultController is
    IVaultController,
    UUPSUpgradeable,
    ERC165Upgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;
    using ERC165CheckerUpgradeable for address;

    /// @notice Role allows configure reserve related data/components
    bytes32 internal constant RESERVE_MANAGER_ROLE = keccak256("RESERVE_MANAGER_ROLE");

    /// @inheritdoc IVaultController
    address public override asset;

    /// @inheritdoc IVaultController
    address public override vToken;

    /// @inheritdoc IVaultController
    address public override registry;

    /// @notice Timestamp of last deposit
    uint32 private lastDepositUpdateTimestamp;

    /// @inheritdoc IVaultController
    uint32 public override stepDuration;

    /// @inheritdoc IVaultController
    uint16 public override targetDepositPercentageInBP;
    /// @inheritdoc IVaultController
    uint16 public override percentageInBPPerStep;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "VaultController: FORBIDDEN");
        _;
    }

    /// @notice Requires msg.sender to be a vToken
    modifier onlyVToken() {
        require(msg.sender == vToken, "VaultController: FORBIDDEN");
        _;
    }

    /// @inheritdoc IVaultController
    function setDepositInfo(
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) external override onlyRole(RESERVE_MANAGER_ROLE) {
        require(
            _stepDuration > 0 &&
                _targetDepositPercentageInBP > 0 &&
                _targetDepositPercentageInBP <= BP.DECIMAL_FACTOR &&
                _percentageInBPPerStep > 0 &&
                _percentageInBPPerStep <= BP.DECIMAL_FACTOR,
            "VaultController: INVALID_DEPOSIT_INFO"
        );

        targetDepositPercentageInBP = _targetDepositPercentageInBP;
        percentageInBPPerStep = _percentageInBPPerStep;
        stepDuration = _stepDuration;

        emit SetDepositInfo(_targetDepositPercentageInBP, _percentageInBPPerStep, _stepDuration);
    }

    /// @inheritdoc IVaultController
    function deposit() external override nonReentrant onlyVToken {
        uint balance = IERC20(asset).balanceOf(address(this));
        if (balance != 0) {
            _deposit(balance);
            lastDepositUpdateTimestamp = uint32(block.timestamp);
        }

        emit Deposit(balance);
    }

    /// @inheritdoc IVaultController
    function withdraw() external override nonReentrant onlyVToken {
        _withdraw();

        IERC20 _asset = IERC20(asset);
        uint balance = _asset.balanceOf(address(this));
        if (balance != 0) {
            _asset.safeTransfer(vToken, balance);
        }

        emit Withdraw(balance);
    }

    /// @inheritdoc IVaultController
    function calculatedDepositAmount(uint _currentDepositedPercentageInBP) external view override returns (uint) {
        uint newPercentageInBP = _calculateNewPercentageInBP(_currentDepositedPercentageInBP);

        return newPercentageInBP != 0 ? (IERC20(asset).balanceOf(vToken) * newPercentageInBP) / BP.DECIMAL_FACTOR : 0;
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IVaultController).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Initializes vault controller with the given parameters
    /// @dev Initialization method used in upgradeable contracts instead of constructor function
    /// @param _vToken vToken contract address
    /// @param _targetDepositPercentageInBP total percentage of asset to be deposited
    /// @param _percentageInBPPerStep percentage to deposit per step
    /// @param _stepDuration timestamp between deposit steps
    function __BaseVaultController_init(
        address _vToken,
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) internal onlyInitializing {
        require(_vToken.supportsInterface(type(IvToken).interfaceId), "VaultController: INTERFACE");

        __ERC165_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        vToken = _vToken;
        asset = IvToken(_vToken).asset();
        registry = IvToken(_vToken).registry();

        targetDepositPercentageInBP = _targetDepositPercentageInBP;
        percentageInBPPerStep = _percentageInBPPerStep;
        stepDuration = _stepDuration;
        emit SetDepositInfo(_targetDepositPercentageInBP, _percentageInBPPerStep, _stepDuration);
    }

    /// @notice Virtual deposit method to be overridden in derived classes
    /// @param _amount Amount of deposit
    function _deposit(uint _amount) internal virtual;

    /// @notice Virtual withdraw method to be overridden in derived classes
    function _withdraw() internal virtual;

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal view virtual override onlyRole(RESERVE_MANAGER_ROLE) {}

    /// @notice Calculates new deposited percentage in BP
    /// @param _currentDepositedPercentInBP Current deposited percentage in BP (base point)
    function _calculateNewPercentageInBP(uint _currentDepositedPercentInBP) private view returns (uint) {
        uint stepsPassed = (block.timestamp - lastDepositUpdateTimestamp) / stepDuration;
        uint percentageChangeInBP = stepsPassed * percentageInBPPerStep;

        return Math.min(targetDepositPercentageInBP, _currentDepositedPercentInBP + percentageChangeInBP);
    }

    uint256[45] private __gap;
}
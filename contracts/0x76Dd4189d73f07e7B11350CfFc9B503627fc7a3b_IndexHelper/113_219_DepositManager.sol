// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IvToken.sol";
import "./interfaces/IDepositManager.sol";
import "./interfaces/IVaultController.sol";

contract DepositManager is IDepositManager {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Base point number
    uint16 internal constant BP = 10_000;

    /// @notice Role allows configure reserve related data/components
    bytes32 internal immutable RESERVE_MANAGER_ROLE;
    /// @inheritdoc IDepositManager
    address public immutable override registry;

    /// @notice vTokens to deposit for
    EnumerableSet.AddressSet internal vTokens;

    /// @inheritdoc IDepositManager
    uint32 public override depositInterval;

    /// @inheritdoc IDepositManager
    uint16 public override maxLossInBP;

    /// @inheritdoc IDepositManager
    mapping(address => uint96) public override lastDepositTimestamp;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "DepositManager: FORBIDDEN");
        _;
    }

    /// @notice Checks if max loss is within an acceptable range
    modifier isValidMaxLoss(uint16 _maxLossInBP) {
        require(_maxLossInBP <= BP, "DepositManager: MAX_LOSS");
        _;
    }

    constructor(
        address _registry,
        uint16 _maxLossInBP,
        uint32 _depositInterval
    ) isValidMaxLoss(_maxLossInBP) {
        RESERVE_MANAGER_ROLE = keccak256("RESERVE_MANAGER_ROLE");

        registry = _registry;
        maxLossInBP = _maxLossInBP;
        depositInterval = _depositInterval;
    }

    /// @inheritdoc IDepositManager
    function addVToken(address _vToken) external override onlyRole(RESERVE_MANAGER_ROLE) {
        require(vTokens.add(_vToken), "DepositManager: EXISTS");
    }

    /// @inheritdoc IDepositManager
    function removeVToken(address _vToken) external override onlyRole(RESERVE_MANAGER_ROLE) {
        require(vTokens.remove(_vToken), "DepositManager: !FOUND");
    }

    /// @inheritdoc IDepositManager
    function setDepositInterval(uint32 _interval) external override onlyRole(RESERVE_MANAGER_ROLE) {
        require(_interval > 0, "DepositManager: INVALID");
        depositInterval = _interval;
    }

    /// @inheritdoc IDepositManager
    function setMaxLoss(uint16 _maxLossInBP) external isValidMaxLoss(_maxLossInBP) onlyRole(RESERVE_MANAGER_ROLE) {
        maxLossInBP = _maxLossInBP;
    }

    /// @inheritdoc IDepositManager
    function canUpdateDeposits() external view override returns (bool) {
        uint count = vTokens.length();
        for (uint i; i < count; ++i) {
            address vToken = vTokens.at(i);
            if (block.timestamp - lastDepositTimestamp[vToken] >= depositInterval) {
                return true;
            }
        }
        return false;
    }

    /// @inheritdoc IDepositManager
    function containsVToken(address _vToken) external view override returns (bool) {
        return vTokens.contains(_vToken);
    }

    /// @inheritdoc IDepositManager
    function updateDeposits() public virtual override {
        bool deposited;
        uint count = vTokens.length();
        for (uint i; i < count; ++i) {
            IvToken vToken = IvToken(vTokens.at(i));
            if (block.timestamp - lastDepositTimestamp[address(vToken)] >= depositInterval) {
                uint _depositedBefore = vToken.deposited();
                uint _totalBefore = vToken.totalAssetSupply();

                vToken.deposit();

                require(
                    _isValidMaxLoss(_depositedBefore, _totalBefore, vToken.totalAssetSupply()),
                    "DepositManager: MAX_LOSS"
                );

                lastDepositTimestamp[address(vToken)] = uint96(block.timestamp);
                deposited = true;
            }
        }

        require(deposited, "DepositManager: !DEPOSITED");
    }

    function _isValidMaxLoss(
        uint _depositedBefore,
        uint _totalBefore,
        uint _totalAfter
    ) internal view returns (bool) {
        if (_totalAfter < _totalBefore) {
            return _totalBefore - _totalAfter <= (_depositedBefore * maxLossInBP) / BP;
        }
        return true;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/finance/VestingWalletUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VestingManager is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    VestingWalletUpgradeable
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _owner,
        address _beneficiaryAddress,
        uint64 _startTimestamp,
        uint64 _durationSeconds,
        address _upgrader
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __VestingWallet_init(
            _beneficiaryAddress,
            _startTimestamp,
            _durationSeconds
        );

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(UPGRADER_ROLE, _upgrader);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract VestingFactory is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant FACTORY_MANAGER = keccak256("FACTORY_MANAGER");
    address public vestingManagerImplementation;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _admin,
        address _factoryManager,
        address _vestingManagerImplementation
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        vestingManagerImplementation = _vestingManagerImplementation;

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(FACTORY_MANAGER, _factoryManager);
        _grantRole(UPGRADER_ROLE, _admin);
    }

    function setVestingManager(
        address _vestingManagerImplementation
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        vestingManagerImplementation = _vestingManagerImplementation;
    }

    function createSchedule(
        address _owner,
        address _beneficiaryAddress,
        uint64 _startTimestamp,
        uint64 _durationSeconds,
        address _upgrader
    ) external onlyRole(FACTORY_MANAGER) returns (address scheduleProxy) {
        scheduleProxy = address(
            new ERC1967Proxy(
                vestingManagerImplementation,
                prepareInitializerData(
                    _owner,
                    _beneficiaryAddress,
                    _startTimestamp,
                    _durationSeconds,
                    _upgrader
                )
            )
        );
    }

    function prepareInitializerData(
        address _owner,
        address _beneficiaryAddress,
        uint64 _startTimestamp,
        uint64 _durationSeconds,
        address _upgrader
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "initialize(address,address,uint64,uint64,address)",
                _owner,
                _beneficiaryAddress,
                _startTimestamp,
                _durationSeconds,
                _upgrader
            );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}
}
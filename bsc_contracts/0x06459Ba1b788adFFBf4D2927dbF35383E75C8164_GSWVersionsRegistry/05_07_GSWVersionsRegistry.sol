// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { IGSWFactory } from "./interfaces/IGSWFactory.sol";
import { IGSWVersionsRegistry } from "./interfaces/IGSWVersionsRegistry.sol";

error GSWVersionsRegistry__Unauthorized();
error GSWVersionsRegistry__InvalidParams();
error GSWVersionsRegistry__InvalidVersion();

/// @title      GSWVersionsRegistry
/// @notice     holds lists of valid versions for the various GSW related contracts
/// @dev        Upgradeable tthrough GSWVersionsRegistryProxy
contract GSWVersionsRegistry is IGSWVersionsRegistry, Initializable, OwnableUpgradeable {
    /***********************************|
    |           STATE VARIABLES         |
    |__________________________________*/

    /// @notice  current GSWFactory where new GSW versions get registered automatically as newest version
    ///          on registerGSWVersion calls
    ///          modifiable by owner
    IGSWFactory public gswFactory;

    /// @notice mapping to store allowed GSW versions
    ///         modifiable by owner
    mapping(address => bool) public gswVersions;

    /// @notice mapping to store allowed GSWForwarder versions
    ///         modifiable by owner
    mapping(address => bool) public gswForwarderVersions;

    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/

    /// @notice checks if an address is not 0x000...
    modifier validAddress(address _address) {
        if (_address == address(0)) {
            revert GSWVersionsRegistry__InvalidParams();
        }
        _;
    }

    /***********************************|
    |               EVENTS              |
    |__________________________________*/

    /// @notice emitted when the status for a certain GSW version is updated
    event SetGSWVersion(address indexed gswVersion, bool indexed allowed, bool indexed setDefault);

    /// @notice emitted when the status for a certain GSWForwarder version is updated
    event SetGSWForwarderVersion(address indexed gswForwarderVersion, bool indexed allowed);

    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    constructor() {
        // ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /// @notice initializes the contract for owner_ as owner
    /// @param owner_           address of owner_ authorized to set versions
    function initialize(address owner_) public initializer {
        if (owner_ == address(0)) {
            revert GSWVersionsRegistry__InvalidParams();
        }

        __Ownable_init();
        transferOwnership(owner_);
    }

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    /// @inheritdoc IGSWVersionsRegistry
    function requireValidGSWVersion(address gswVersion_) external view {
        if (gswVersions[gswVersion_] != true) {
            revert GSWVersionsRegistry__InvalidVersion();
        }
    }

    /// @inheritdoc IGSWVersionsRegistry
    function requireValidGSWForwarderVersion(address gswForwarderVersion_) external view {
        if (gswForwarderVersions[gswForwarderVersion_] != true) {
            revert GSWVersionsRegistry__InvalidVersion();
        }
    }

    /***********************************|
    |            ONLY OWNER             |
    |__________________________________*/

    /// @notice             sets the current GSWFactory address
    /// @param gswFactory_  address of the new gswFactory
    function setGSWFactory(address gswFactory_) external onlyOwner validAddress(gswFactory_) {
        gswFactory = IGSWFactory(gswFactory_);
    }

    /// @notice             sets the status for a certain address as valid GSW version
    /// @param gsw_         the address of the contract to treat as GSW version
    /// @param allowed_     flag to set this address as valid version (true) or not (false)
    /// @param setDefault_  flag to indicate whether this version should automatically be set as new
    ///                     default version for new deployments at the linked GSWFactory
    function setGSWVersion(
        address gsw_,
        bool allowed_,
        bool setDefault_
    ) external onlyOwner validAddress(gsw_) {
        if (!allowed_ && setDefault_) {
            // can't be not allowed but supposed to be set as default
            revert GSWVersionsRegistry__InvalidParams();
        }

        gswVersions[gsw_] = allowed_;

        if (setDefault_) {
            // register the new version as default version at the linked GSWFactory
            gswFactory.setGSWImpl(gsw_);
        }

        emit SetGSWVersion(gsw_, allowed_, setDefault_);
    }

    /// @notice                 sets the status for a certain address as valid GSWForwarder (proxy) version
    /// @param gswForwarder_    the address of the contract to treat as GSWForwarder version
    /// @param allowed_         flag to set this address as valid version (true) or not (false)
    function setGSWForwarderVersion(address gswForwarder_, bool allowed_)
        external
        onlyOwner
        validAddress(gswForwarder_)
    {
        gswForwarderVersions[gswForwarder_] = allowed_;

        emit SetGSWForwarderVersion(gswForwarder_, allowed_);
    }
}
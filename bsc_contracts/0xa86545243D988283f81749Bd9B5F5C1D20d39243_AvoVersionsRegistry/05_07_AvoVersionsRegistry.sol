// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { IAvoFactory } from "./interfaces/IAvoFactory.sol";
import { IAvoVersionsRegistry } from "./interfaces/IAvoVersionsRegistry.sol";

/// @title      AvoVersionsRegistry
/// @notice     holds lists of valid versions for the various Avo related contracts
/// @dev        Upgradeable tthrough AvoVersionsRegistryProxy
contract AvoVersionsRegistry is IAvoVersionsRegistry, Initializable, OwnableUpgradeable {
    /***********************************|
    |                ERRORS             |
    |__________________________________*/

    error AvoVersionsRegistry__InvalidParams();
    error AvoVersionsRegistry__InvalidVersion();

    /***********************************|
    |           STATE VARIABLES         |
    |__________________________________*/

    /// @notice  current AvoFactory where new AvoWallet versions get registered automatically as newest version
    ///          on registerAvoVersion calls
    ///          modifiable by owner
    IAvoFactory public avoFactory;

    /// @notice mapping to store allowed AvoWallet versions
    ///         modifiable by owner
    mapping(address => bool) public avoWalletVersions;

    /// @notice mapping to store allowed AvoForwarder versions
    ///         modifiable by owner
    mapping(address => bool) public avoForwarderVersions;

    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/

    /// @notice checks if an address is not 0x000...
    modifier validAddress(address _address) {
        if (_address == address(0)) {
            revert AvoVersionsRegistry__InvalidParams();
        }
        _;
    }

    /***********************************|
    |               EVENTS              |
    |__________________________________*/

    /// @notice emitted when the status for a certain AvoWallet version is updated
    event SetAvoWalletVersion(address indexed avoWalletVersion, bool indexed allowed, bool indexed setDefault);

    /// @notice emitted when the status for a certain AvoForwarder version is updated
    event SetAvoForwarderVersion(address indexed avoForwarderVersion, bool indexed allowed);

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
    function initialize(address owner_) public initializer validAddress(owner_) {
        _transferOwnership(owner_);
    }

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    /// @inheritdoc IAvoVersionsRegistry
    function requireValidAvoWalletVersion(address avoWalletVersion_) external view {
        if (avoWalletVersions[avoWalletVersion_] != true) {
            revert AvoVersionsRegistry__InvalidVersion();
        }
    }

    /// @inheritdoc IAvoVersionsRegistry
    function requireValidAvoForwarderVersion(address avoForwarderVersion_) public view {
        if (avoForwarderVersions[avoForwarderVersion_] != true) {
            revert AvoVersionsRegistry__InvalidVersion();
        }
    }

    /***********************************|
    |            ONLY OWNER             |
    |__________________________________*/

    /// @notice             sets the current AvoFactory address
    /// @param avoFactory_  address of the new avoFactory
    function setAvoFactory(address avoFactory_) external onlyOwner validAddress(avoFactory_) {
        avoFactory = IAvoFactory(avoFactory_);
    }

    /// @notice                 sets the status for a certain address as valid AvoWallet version
    /// @param avoWallet_       the address of the contract to treat as AvoWallet version
    /// @param allowed_         flag to set this address as valid version (true) or not (false)
    /// @param setDefault_      flag to indicate whether this version should automatically be set as new
    ///                         default version for new deployments at the linked AvoFactory
    function setAvoWalletVersion(
        address avoWallet_,
        bool allowed_,
        bool setDefault_
    ) external onlyOwner validAddress(avoWallet_) {
        if (!allowed_ && setDefault_) {
            // can't be not allowed but supposed to be set as default
            revert AvoVersionsRegistry__InvalidParams();
        }

        avoWalletVersions[avoWallet_] = allowed_;

        if (setDefault_) {
            // register the new version as default version at the linked AvoFactory
            avoFactory.setAvoWalletImpl(avoWallet_);
        }

        emit SetAvoWalletVersion(avoWallet_, allowed_, setDefault_);
    }

    /// @notice                 sets the status for a certain address as valid AvoForwarder (proxy) version
    /// @param avoForwarder_    the address of the contract to treat as AvoForwarder version
    /// @param allowed_         flag to set this address as valid version (true) or not (false)
    function setAvoForwarderVersion(address avoForwarder_, bool allowed_)
        external
        onlyOwner
        validAddress(avoForwarder_)
    {
        avoForwarderVersions[avoForwarder_] = allowed_;

        emit SetAvoForwarderVersion(avoForwarder_, allowed_);
    }
}
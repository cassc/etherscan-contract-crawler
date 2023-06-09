// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IDefaultImplementationBeacon } from "../../modules/proxy-factory/contracts/interfaces/IDefaultImplementationBeacon.sol";

/// @title A Maple factory for Proxy contracts that proxy MapleProxied implementations.
interface IMapleProxyFactory is IDefaultImplementationBeacon {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   A default version was set.
     *  @param version_ The default version.
     */
    event DefaultVersionSet(uint256 indexed version_);

    /**
     *  @dev   A version of an implementation, at some address, was registered, with an optional initializer.
     *  @param version_               The version registered.
     *  @param implementationAddress_ The address of the implementation.
     *  @param initializer_           The address of the initializer, if any.
     */
    event ImplementationRegistered(uint256 indexed version_, address indexed implementationAddress_, address indexed initializer_);

    /**
     *  @dev   A proxy contract was deployed with some initialization arguments.
     *  @param version_                 The version of the implementation being proxied by the deployed proxy contract.
     *  @param instance_                The address of the proxy contract deployed.
     *  @param initializationArguments_ The arguments used to initialize the proxy contract, if any.
     */
    event InstanceDeployed(uint256 indexed version_, address indexed instance_, bytes initializationArguments_);

    /**
     *  @dev   A instance has upgraded by proxying to a new implementation, with some migration arguments.
     *  @param instance_           The address of the proxy contract.
     *  @param fromVersion_        The initial implementation version being proxied.
     *  @param toVersion_          The new implementation version being proxied.
     *  @param migrationArguments_ The arguments used to migrate, if any.
     */
    event InstanceUpgraded(address indexed instance_, uint256 indexed fromVersion_, uint256 indexed toVersion_, bytes migrationArguments_);

    /**
     *  @dev   The MapleGlobals was set.
     *  @param mapleGlobals_ The address of a Maple Globals contract.
     */
    event MapleGlobalsSet(address indexed mapleGlobals_);

    /**
     *  @dev   An upgrade path was disabled, with an optional migrator contract.
     *  @param fromVersion_ The starting version of the upgrade path.
     *  @param toVersion_   The destination version of the upgrade path.
     */
    event UpgradePathDisabled(uint256 indexed fromVersion_, uint256 indexed toVersion_);

    /**
     *  @dev   An upgrade path was enabled, with an optional migrator contract.
     *  @param fromVersion_ The starting version of the upgrade path.
     *  @param toVersion_   The destination version of the upgrade path.
     *  @param migrator_    The address of the migrator, if any.
     */
    event UpgradePathEnabled(uint256 indexed fromVersion_, uint256 indexed toVersion_, address indexed migrator_);

    /**************************************************************************************************************************************/
    /*** State Variables                                                                                                                ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev The default version.
     */
    function defaultVersion() external view returns (uint256 defaultVersion_);

    /**
     *  @dev The address of the MapleGlobals contract.
     */
    function mapleGlobals() external view returns (address mapleGlobals_);

    /**
     *  @dev    Whether the upgrade is enabled for a path from a version to another version.
     *  @param  toVersion_   The initial version.
     *  @param  fromVersion_ The destination version.
     *  @return allowed_     Whether the upgrade is enabled.
     */
    function upgradeEnabledForPath(uint256 toVersion_, uint256 fromVersion_) external view returns (bool allowed_);

    /**************************************************************************************************************************************/
    /*** State Changing Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Deploys a new instance proxying the default implementation version, with some initialization arguments.
     *          Uses a nonce and `msg.sender` as a salt for the CREATE2 opcode during instantiation to produce deterministic addresses.
     *  @param  arguments_ The initialization arguments to use for the instance deployment, if any.
     *  @param  salt_      The salt to use in the contract creation process.
     *  @return instance_  The address of the deployed proxy contract.
     */
    function createInstance(bytes calldata arguments_, bytes32 salt_) external returns (address instance_);

    /**
     *  @dev   Enables upgrading from a version to a version of an implementation, with an optional migrator.
     *         Only the Governor can call this function.
     *  @param fromVersion_ The starting version of the upgrade path.
     *  @param toVersion_   The destination version of the upgrade path.
     *  @param migrator_    The address of the migrator, if any.
     */
    function enableUpgradePath(uint256 fromVersion_, uint256 toVersion_, address migrator_) external;

    /**
     *  @dev   Disables upgrading from a version to a version of a implementation.
     *         Only the Governor can call this function.
     *  @param fromVersion_ The starting version of the upgrade path.
     *  @param toVersion_   The destination version of the upgrade path.
     */
    function disableUpgradePath(uint256 fromVersion_, uint256 toVersion_) external;

    /**
     *  @dev   Registers the address of an implementation contract as a version, with an optional initializer.
     *         Only the Governor can call this function.
     *  @param version_               The version to register.
     *  @param implementationAddress_ The address of the implementation.
     *  @param initializer_           The address of the initializer, if any.
     */
    function registerImplementation(uint256 version_, address implementationAddress_, address initializer_) external;

    /**
     *  @dev   Sets the default version.
     *         Only the Governor can call this function.
     *  @param version_ The implementation version to set as the default.
     */
    function setDefaultVersion(uint256 version_) external;

    /**
     *  @dev   Sets the Maple Globals contract.
     *         Only the Governor can call this function.
     *  @param mapleGlobals_ The address of a Maple Globals contract.
     */
    function setGlobals(address mapleGlobals_) external;

    /**
     *  @dev   Upgrades the calling proxy contract's implementation, with some migration arguments.
     *  @param toVersion_ The implementation version to upgrade the proxy contract to.
     *  @param arguments_ The migration arguments, if any.
     */
    function upgradeInstance(uint256 toVersion_, bytes calldata arguments_) external;

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Returns the deterministic address of a potential proxy, given some arguments and salt.
     *  @param  arguments_       The initialization arguments to be used when deploying the proxy.
     *  @param  salt_            The salt to be used when deploying the proxy.
     *  @return instanceAddress_ The deterministic address of a potential proxy.
     */
    function getInstanceAddress(bytes calldata arguments_, bytes32 salt_) external view returns (address instanceAddress_);

    /**
     *  @dev    Returns the address of an implementation version.
     *  @param  version_        The implementation version.
     *  @return implementation_ The address of the implementation.
     */
    function implementationOf(uint256 version_) external view returns (address implementation_);

    /**
     *  @dev    Returns if a given address has been deployed by this factory/
     *  @param  instance_   The address to check.
     *  @return isInstance_ A boolean indication if the address has been deployed by this factory.
     */
    function isInstance(address instance_) external view returns (bool isInstance_);

    /**
     *  @dev    Returns the address of a migrator contract for a migration path (from version, to version).
     *          If oldVersion_ == newVersion_, the migrator is an initializer.
     *  @param  oldVersion_ The old version.
     *  @param  newVersion_ The new version.
     *  @return migrator_   The address of a migrator contract.
     */
    function migratorForPath(uint256 oldVersion_, uint256 newVersion_) external view returns (address migrator_);

    /**
     *  @dev    Returns the version of an implementation contract.
     *  @param  implementation_ The address of an implementation contract.
     *  @return version_        The version of the implementation contract.
     */
    function versionOf(address implementation_) external view returns (uint256 version_);

}
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../blueprints/DynamicBlueprint.sol";
import "../expansion/Expansion.sol";
import "../broadcast/DynamicBlueprintsBroadcast.sol";
import "../storefront/SimpleExpansionStorefront.sol";
import "../storefront/RandomExpansionStorefront.sol";
import "../storefront/SimpleDBPStorefront.sol";
import "../common/StorefrontProxy.sol";
import "../common/IRoyalty.sol";
import "../common/IOperatorFilterer.sol";

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Used to deploy and configure DynamicBlueprint and DynamicBlueprintsExpansion contracts with multiple settings.
 *         This deploys a factory on a network that's already set up
 * @author Ohimire Labs
 */
contract DynamicBlueprintsFactoryPreInitialized is Ownable {
    /**
     * @notice Default addresses given admin roles on DBP instances
     * @param defaultAdmin Account given DEFAULT_ADMIN_ROLE
     * @param minter Account made platform minter
     * @param storefrontMinters Storefronts initially registered as valid storefront minters
     */
    struct DynamicBlueprintsDefaultRoles {
        address defaultAdmin;
        address minter;
        address[] storefrontMinters;
    }

    /**
     * @notice Default addresses given admin roles on Expansion instances
     * @param defaultAdmin Account given DEFAULT_ADMIN_ROLE
     * @param minter Account given MINTER_ROLE
     * @param storefrontMinters Storefronts initially registered as valid storefront minters
     */
    struct ExpansionDefaultRoles {
        address defaultAdmin;
        address minter;
        address[] storefrontMinters;
    }

    /**
     * @notice Beacon keeping track of current DynamicBlueprint implementation
     */
    address public immutable dynamicBlueprintsBeacon;

    /**
     * @notice Beacon keeping track of current Expansion implementation
     */
    address public immutable expansionBeacon;

    /**
     * @notice Broadcast contract where application intents are sent
     */
    address public immutable broadcast;

    /**
     * @notice Default addresses given administrative roles on dynamic blueprint instances
     */
    DynamicBlueprintsDefaultRoles public dbpDefaultRoles;

    /**
     * @notice Default addresses given administrative roles on expansion instances
     */
    ExpansionDefaultRoles public expansionDefaultRoles;

    /**
     * @notice Emitted when DynamicBlueprint is deployed
     * @param dynamicBlueprint Address of deployed DynamicBlueprints BeaconProxy
     * @param dynamicBlueprintPlatformID Platform's identification of dynamic blueprint
     */
    event DynamicBlueprintDeployed(address indexed dynamicBlueprint, string dynamicBlueprintPlatformID);

    /**
     * @notice Emitted when Expansion is deployed
     * @param expansion Address of deployed DynamicBlueprintsExpansion BeaconProxy
     * @param expansionPlatformID Platform's identification of dynamic blueprint expansion
     */
    event ExpansionDeployed(address indexed expansion, string expansionPlatformID);

    constructor(
        address _dynamicBlueprintsBeacon,
        address _expansionBeacon,
        address _broadcast,
        DynamicBlueprintsDefaultRoles memory _dbpDefaultRoles,
        ExpansionDefaultRoles memory _expansionDefaultRoles,
        address factoryOwner
    ) {
        dynamicBlueprintsBeacon = _dynamicBlueprintsBeacon;
        expansionBeacon = _expansionBeacon;
        broadcast = _broadcast;
        dbpDefaultRoles = _dbpDefaultRoles;
        expansionDefaultRoles = _expansionDefaultRoles;
        _transferOwnership(factoryOwner);
    }

    /**
     * @notice Deploy DynamicBlueprintsExpansion instance only.
     *         The deployer can pay an optional fee in ether to front the gas cost of preparePack calls that
     *         AsyncArt will make on their behalf on the Expansion contract.
     * @param _contractURI Contract-level metadata for the Expansion contract
     * @param _artist The artist authorized to create items on the expansion
     * @param _royalty Expansion contracts' royalty parameters
     * @param operatorFiltererInputs OpenSea operator filterer addresses
     * @param expansionPlatformID Platform's identification of the expansion contract
     */
    function deployExpansion(
        string calldata _contractURI,
        address _artist,
        IRoyalty.Royalty calldata _royalty,
        IOperatorFilterer.OperatorFiltererInputs calldata operatorFiltererInputs,
        string calldata expansionPlatformID
    ) external payable {
        address expansion = address(
            new BeaconProxy(
                expansionBeacon,
                abi.encodeWithSelector(
                    Expansion(address(0)).initialize.selector,
                    expansionDefaultRoles.storefrontMinters,
                    expansionDefaultRoles.defaultAdmin,
                    expansionDefaultRoles.minter,
                    _contractURI,
                    _artist,
                    _royalty,
                    broadcast,
                    operatorFiltererInputs,
                    msg.value
                )
            )
        );

        // If the deployer supplied a gas deposit, send it to the platform that will administrate preparePack calls
        if (msg.value > 0) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = (expansionDefaultRoles.minter).call{ value: msg.value }("");
            /* solhint-enable avoid-low-level-calls */
            require(success, "gas deposit to platform failed");
        }
        emit ExpansionDeployed(expansion, expansionPlatformID);
    }

    /**
     * @notice Deploy DynamicBlueprint instance only
     * @param dynamicBlueprintsInput Dynamic Blueprint initialization input
     * @param _royalty Royalty for DBP instance
     * @param operatorFiltererInputs OpenSea operator filterer addresses
     * @param blueprintPlatformID Off-chain ID associated with DBP deployment
     */
    function deployDynamicBlueprint(
        IDynamicBlueprint.DynamicBlueprintsInput calldata dynamicBlueprintsInput,
        IRoyalty.Royalty calldata _royalty,
        IOperatorFilterer.OperatorFiltererInputs calldata operatorFiltererInputs,
        string calldata blueprintPlatformID
    ) external {
        address dynamicBlueprint = address(
            new BeaconProxy(
                dynamicBlueprintsBeacon,
                abi.encodeWithSelector(
                    DynamicBlueprint(address(0)).initialize.selector,
                    dynamicBlueprintsInput,
                    dbpDefaultRoles.defaultAdmin,
                    dbpDefaultRoles.minter,
                    _royalty,
                    dbpDefaultRoles.storefrontMinters,
                    broadcast,
                    operatorFiltererInputs
                )
            )
        );
        emit DynamicBlueprintDeployed(dynamicBlueprint, blueprintPlatformID);
    }

    /**
     * @notice Owner-only function to change the default addresses given privileges on DBP instances
     * @param newDBPDefaultRoles New DBP default roles
     */
    function changeDBPDefaultRoles(DynamicBlueprintsDefaultRoles calldata newDBPDefaultRoles) external onlyOwner {
        require(
            newDBPDefaultRoles.defaultAdmin != address(0) && newDBPDefaultRoles.minter != address(0),
            "Invalid address"
        );
        dbpDefaultRoles = newDBPDefaultRoles;
    }

    /**
     * @notice Owner-only function to change the default addresses given privileges on Expansion instances
     * @param newExpansionDefaultRoles New Expansion default roles
     */
    function changeExpansionDefaultRoles(ExpansionDefaultRoles calldata newExpansionDefaultRoles) external onlyOwner {
        require(newExpansionDefaultRoles.defaultAdmin != address(0), "Invalid address");
        expansionDefaultRoles = newExpansionDefaultRoles;
    }

    /**
     * @notice Get DBP default storefront minters
     */
    function getDBPDefaultStorefrontMinters() external view returns (address[] memory) {
        return dbpDefaultRoles.storefrontMinters;
    }

    /**
     * @notice Get Expansion default storefront minters
     */
    function getExpansionDefaultStorefrontMinters() external view returns (address[] memory) {
        return expansionDefaultRoles.storefrontMinters;
    }
}
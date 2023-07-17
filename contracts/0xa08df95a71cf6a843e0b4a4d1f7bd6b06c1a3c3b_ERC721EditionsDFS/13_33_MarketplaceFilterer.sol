// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { IOperatorFilterRegistry } from "./interfaces/IOperatorFilterRegistry.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title  MarketplaceFilterer
 * @notice Abstract contract whose constructor automatically registers and subscribes to default
           subscription from OpenSea, if a valid registry is passed in. 
           Slightly modified from `OperatorFilterer` contract by [email protected] highlight.xyz.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract MarketplaceFilterer is OwnableUpgradeable {
    error NotAContract();

    error OperatorNotAllowed(address operator);

    /**
     * @notice MarketplaceFilterer Registry (CORI)
     */
    address public constant MARKETPLACE_FILTERER_REGISTRY = 0x000000000000AAeB6D7670E522A718067333cd4E;

    /**
     * @notice Default subscription to register collection with on CORI Marketplace filterer registry
     */
    address public constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    /**
     * @notice CORI Marketplace filterer registry. Set to address(0) when not used to avoid extra inter-contract calls.
     */
    address public operatorFiltererRegistry;

    /**
     * @notice Update the address that the contract will make MarketplaceFilterer checks against.
     *         Also register this contract with that registry.
     */
    function setMarketplaceFiltererRegistryAndRegisterDefaultSubscription() public onlyOwner {
        _setMarketplaceFiltererRegistryAndRegisterDefaultSubscription(MARKETPLACE_FILTERER_REGISTRY);
    }

    /**
     * @notice Update the address that the contract will make MarketplaceFilterer checks against.
     *         Also register this contract with that registry.
     */
    function setCustomMarketplaceFiltererRegistryAndRegisterDefaultSubscription(address newRegistry) public onlyOwner {
        if (newRegistry.code.length == 0) {
            _revert(NotAContract.selector);
        }
        _setMarketplaceFiltererRegistryAndRegisterDefaultSubscription(newRegistry);
    }

    /**
     * @notice Remove the address that the contract will make MarketplaceFilterer checks against.
     *         Also unregister this contract from that registry.
     */
    function removeMarketplaceFiltererRegistryAndUnregister() public onlyOwner {
        if (operatorFiltererRegistry.code.length > 0) {
            IOperatorFilterRegistry(operatorFiltererRegistry).unregister(address(this));
        }
        operatorFiltererRegistry = address(0);
    }

    function __MarketplaceFilterer__init__(bool useFilterer) internal onlyInitializing {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (useFilterer) {
            _setMarketplaceFiltererRegistryAndRegisterDefaultSubscription(MARKETPLACE_FILTERER_REGISTRY);
        }
    }

    function _setMarketplaceFiltererRegistryAndRegisterDefaultSubscription(address newRegistry) private {
        operatorFiltererRegistry = newRegistry;
        if (newRegistry.code.length > 0) {
            IOperatorFilterRegistry(newRegistry).registerAndSubscribe(address(this), DEFAULT_SUBSCRIPTION);
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != _msgSender()) {
            _checkFilterOperator(_msgSender());
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (operatorFiltererRegistry != address(0)) {
            if (!IOperatorFilterRegistry(operatorFiltererRegistry).isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure virtual {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}
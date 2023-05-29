// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "operator-filter-registry/src/IOperatorFilterRegistry.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title "Kurt The Roadie" Contract
 * @author rminla.eth
 * @notice Custom OperatorFilterer implementation with safeguards.  Allows owners to transfer their own NFTs and allows universal toggle of subscription registry functionality
 */
contract KSOperatorFilterer is Ownable {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant operatorFilterRegistry =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    bool public enforceOperatorRegistry = false;

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (subscribe) {
                operatorFilterRegistry.registerAndSubscribe(
                    address(this),
                    subscriptionOrRegistrantToCopy
                );
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    operatorFilterRegistry.registerAndCopyEntries(
                        address(this),
                        subscriptionOrRegistrantToCopy
                    );
                } else {
                    operatorFilterRegistry.register(address(this));
                }
            }
        }
    }

    /**
     * @notice Toggle operator registry enforcement
     */
    function setEnforceOperatorRegistry(bool _enforceOperatorRegistry)
        public
        onlyOwner
    {
        enforceOperatorRegistry = _enforceOperatorRegistry;
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Only execute if operator registry functionality is enabled AND this is not a person transfering their own NFT
        if (enforceOperatorRegistry && from != msg.sender) {
            // Check registry code length to facilitate testing in environments without a deployed registry.
            if (address(operatorFilterRegistry).code.length > 0) {
                if (
                    !operatorFilterRegistry.isOperatorAllowed(
                        address(this),
                        msg.sender
                    )
                ) {
                    revert OperatorNotAllowed(msg.sender);
                }
            }
        }
        _;
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "operator-filter-registry/src/IOperatorFilterRegistry.sol";

/**
 * @title  OpenseaOperatorFilterer
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         - `_setOperatorFilterRegistry to update the registry contract to check against
 *         - `_permanentlyFreezeOperatorFilterRegistry` to permanently disable registry checks
 */
abstract contract OpenseaOperatorFilterer {
    error OperatorNotAllowed(address operator);

    bool public isOperatorFilterRegistryAddressPermanentlyFrozen;

    // Default: OpenSea OperatorFilterRegistry contract
    address public operatorFilterRegistryAddress = 
        0x000000000000AAeB6D7670E522A718067333cd4E;

    // required as authority to make updates to OperatorFilterRegistry for this contract.
    function owner() public virtual returns (address);

    // Enables updating registry contract address
    // (requires manual registering / unregistring with Registry)
    // set to address(0) to disable operator filtering
    function _setOperatorFilterRegistryAddress(
        address _operatorFilterRegistryAddress
    ) internal virtual {
        require(
            !isOperatorFilterRegistryAddressPermanentlyFrozen,
            "O:01"
        );
        operatorFilterRegistryAddress = _operatorFilterRegistryAddress;
    }

    // Permanently freeze filter registry address.
    function _permanentlyFreezeOperatorFilterRegistryAddress() internal virtual {
        isOperatorFilterRegistryAddressPermanentlyFrozen = true;
    }

    function _isOperatorAllowed(address operator) private view {
        if (
            !IOperatorFilterRegistry(operatorFilterRegistryAddress).isOperatorAllowed(
                address(this),
                operator
            )
        ) {
            revert OperatorNotAllowed(operator);
        }
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Modifiers
    ///////////////////////////////////////////////////////////////////////////////

    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender && operatorFilterRegistryAddress != address(0)) {
            _isOperatorAllowed(msg.sender);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _isOperatorAllowed(operator);
        _;
    }
}
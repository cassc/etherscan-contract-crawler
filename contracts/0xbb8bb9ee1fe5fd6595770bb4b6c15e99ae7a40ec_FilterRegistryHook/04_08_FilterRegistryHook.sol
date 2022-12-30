// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OperatorFilterRegistry} from "./OperatorFilterRegistry.sol";
import {IBeforeTokenTransferHandler} from "./IBeforeTokenTransferHandler.sol";

/**
 * A before transfer hook that uses OpenSea's marketplace blocking registry
 */
contract FilterRegistryHook is IBeforeTokenTransferHandler, Ownable {
    /// @notice The operator filter registry to use to check before a token is transferred
    address private _operatorFilterRegistry;

    /** ERRORS **/
    constructor(address __operatorFilterRegistry) {
        _operatorFilterRegistry = __operatorFilterRegistry;
    }

    /// @notice Reverts when a given operator is not allowed to perform a token transfer
    error OperatorNotAllowed(address operator);

    /**
     * Get the address of the filter registry this contract is using.
     *
     * @return address The address of the operator registry this contract is using.
     */
    function getOperatorFilterRegistry() external view returns (address) {
        return _operatorFilterRegistry;
    }

    /**
     * Set the filter registry to a specific address.
     *
     * @param newRegistry Address of the new registry contract
     */
    function setOperatorFilterRegistry(address newRegistry) external onlyOwner {
        _operatorFilterRegistry = newRegistry;
    }

    /**
     * Handles before token transfer events from a ERC721 contract.
     */
    function beforeTokenTransfer(
        address tokenContract,
        address operator,
        address from,
        address to,
        uint256 tokenId
    ) external view {
        beforeTokenTransfer(tokenContract, operator, from, to, tokenId, 1);
    }

    /**
     * Handles before token transfer events from a ERC721 contract.
     */
    function beforeTokenTransfer(
        address tokenContract,
        address operator,
        address, // from
        address, // to
        uint256, // firstId
        uint256  // batchSize
    ) public view {
        if (_operatorFilterRegistry.code.length > 0) {
            if (
                !(
                    OperatorFilterRegistry(_operatorFilterRegistry)
                        .isOperatorAllowed(tokenContract, operator)
                )
            ) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}
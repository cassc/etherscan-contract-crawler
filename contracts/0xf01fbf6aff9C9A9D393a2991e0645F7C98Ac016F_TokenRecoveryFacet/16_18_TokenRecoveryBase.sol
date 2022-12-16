// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721} from "./../../token/ERC721/interfaces/IERC721.sol";
import {ContractOwnershipStorage} from "./../../access/libraries/ContractOwnershipStorage.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/// @title Recovery mechanism for ETH/ERC20/ERC721 tokens accidentally sent to this contract (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC173 (Contract Ownership standard).
contract TokenRecoveryBase is Context {
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;
    using SafeERC20 for IERC20;
    using Address for address payable;

    /// @notice Extract ETH tokens which were accidentally sent to the contract to a list of accounts.
    /// @dev Note: While contracts can generally prevent accidental ETH transfer by implementating a reverting
    ///  `receive()` function, this can still be bypassed in a `selfdestruct(address)` scenario.
    /// @dev Warning: this function should be overriden for contracts which are supposed to hold ETH tokens
    ///  so that the extraction is limited to only amounts sent accidentally.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Reverts if `accounts` and `amounts` do not have the same length.
    /// @dev Reverts if one of the ETH transfers fails for any reason.
    /// @param accounts the list of accounts to transfer the tokens to.
    /// @param amounts the list of token amounts to transfer.
    function recoverETH(address payable[] calldata accounts, uint256[] calldata amounts) external virtual {
        ContractOwnershipStorage.layout().enforceIsContractOwner(_msgSender());
        uint256 length = accounts.length;
        require(length == amounts.length, "Recovery: inconsistent arrays");
        unchecked {
            for (uint256 i; i != length; ++i) {
                accounts[i].sendValue(amounts[i]);
            }
        }
    }

    /// @notice Extract ERC20 tokens which were accidentally sent to the contract to a list of accounts.
    /// @dev Warning: this function should be overriden for contracts which are supposed to hold ERC20 tokens
    ///  so that the extraction is limited to only amounts sent accidentally.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Reverts if `accounts`, `tokens` and `amounts` do not have the same length.
    /// @dev Reverts if one of the ERC20 transfers fails for any reason.
    /// @param accounts the list of accounts to transfer the tokens to.
    /// @param tokens the list of ERC20 token addresses.
    /// @param amounts the list of token amounts to transfer.
    function recoverERC20s(address[] calldata accounts, IERC20[] calldata tokens, uint256[] calldata amounts) external virtual {
        ContractOwnershipStorage.layout().enforceIsContractOwner(_msgSender());
        uint256 length = accounts.length;
        require(length == tokens.length && length == amounts.length, "Recovery: inconsistent arrays");
        unchecked {
            for (uint256 i; i != length; ++i) {
                tokens[i].safeTransfer(accounts[i], amounts[i]);
            }
        }
    }

    /// @notice Extract ERC721 tokens which were accidentally sent to the contract to a list of accounts.
    /// @dev Warning: this function should be overriden for contracts which are supposed to hold ERC721 tokens
    ///  so that the extraction is limited to only tokens sent accidentally.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Reverts if `accounts`, `contracts` and `amounts` do not have the same length.
    /// @dev Reverts if one of the ERC721 transfers fails for any reason.
    /// @param accounts the list of accounts to transfer the tokens to.
    /// @param contracts the list of ERC721 contract addresses.
    /// @param tokenIds the list of token ids to transfer.
    function recoverERC721s(address[] calldata accounts, IERC721[] calldata contracts, uint256[] calldata tokenIds) external virtual {
        ContractOwnershipStorage.layout().enforceIsContractOwner(_msgSender());
        uint256 length = accounts.length;
        require(length == contracts.length && length == tokenIds.length, "Recovery: inconsistent arrays");
        unchecked {
            for (uint256 i; i != length; ++i) {
                contracts[i].transferFrom(address(this), accounts[i], tokenIds[i]);
            }
        }
    }
}
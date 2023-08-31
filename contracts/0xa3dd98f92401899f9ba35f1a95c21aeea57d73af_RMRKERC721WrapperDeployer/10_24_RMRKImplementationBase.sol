// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import "../../RMRK/access/Ownable.sol";
import "../../RMRK/library/RMRKErrors.sol";
import "../../RMRK/extension/RMRKRoyalties.sol";

/**
 * @title RMRKImplementationBase
 * @author RMRK team
 * @notice Smart contract of the RMRK minting utils module.
 * @dev This smart contract includes the top-level utilities for managing minting and implements Ownable by default.
 */
abstract contract RMRKImplementationBase is RMRKRoyalties, Ownable {
    string private _collectionMetadata;
    string private _name;
    string private _symbol;

    uint256 private _nextId;
    uint256 internal _totalSupply;
    uint256 internal _maxSupply;
    uint256 internal _totalAssets;

    /**
     * @notice Initializes the smart contract with a given maximum supply and minting price.
     * @param name_ Name of the token collection
     * @param symbol_ Symbol of the token collection
     * @param collectionMetadata_ The collection metadata URI
     * @param maxSupply_ The maximum supply of tokens
     * @param royaltyRecipient Address to which royalties should be sent
     * @param royaltyPercentageBps The royalty percentage expressed in basis points
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory collectionMetadata_,
        uint256 maxSupply_,
        address royaltyRecipient,
        uint256 royaltyPercentageBps
    ) RMRKRoyalties(royaltyRecipient, royaltyPercentageBps) {
        _name = name_;
        _symbol = symbol_;
        _collectionMetadata = collectionMetadata_;
        _maxSupply = maxSupply_;
    }

    /**
     * @notice Used to retrieve the total supply of the tokens in a collection.
     * @return The number of tokens in a collection
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Used to retrieve the maximum supply of the collection.
     * @return The maximum supply of tokens in the collection
     */
    function maxSupply() public view virtual returns (uint256) {
        return _maxSupply;
    }

    /**
     * @notice Used to retrieve the total number of assets.
     * @return The total number of assets
     */
    function totalAssets() public view virtual returns (uint256) {
        return _totalAssets;
    }

    /**
     * @notice Used to retrieve the metadata of the collection.
     * @return string The metadata URI of the collection
     */
    function collectionMetadata() public view virtual returns (string memory) {
        return _collectionMetadata;
    }

    /**
     * @notice Used to retrieve the collection name.
     * @return Name of the collection
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @notice Used to retrieve the collection symbol.
     * @return Symbol of the collection
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @inheritdoc RMRKRoyalties
     */
    function updateRoyaltyRecipient(
        address newRoyaltyRecipient
    ) public virtual override onlyOwner {
        _setRoyaltyRecipient(newRoyaltyRecipient);
    }

    /**
     * @notice Used to calculate the token IDs of tokens to be minted.
     * @param numToMint Amount of tokens to be minted
     * @return nextToken The ID of the first token to be minted in the current minting cycle
     * @return totalSupplyOffset The ID of the last token to be minted in the current minting cycle
     */
    function _prepareMint(
        uint256 numToMint
    ) internal virtual returns (uint256 nextToken, uint256 totalSupplyOffset) {
        if (numToMint == uint256(0)) revert RMRKMintZero();
        if (numToMint + _nextId > _maxSupply) revert RMRKMintOverMax();

        unchecked {
            nextToken = _nextId + 1;
            _nextId += numToMint;
            _totalSupply += numToMint;
            totalSupplyOffset = _nextId + 1;
        }
    }
}
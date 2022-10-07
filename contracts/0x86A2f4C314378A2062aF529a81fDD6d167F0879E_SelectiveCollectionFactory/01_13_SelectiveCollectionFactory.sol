// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {ISale} from "../../../ISale.sol";
import {SelectiveCollectionToken} from "./SelectiveCollectionToken.sol";
import {Pausable} from "../../../Pausable.sol";

contract SelectiveCollectionFactory is Pausable {
    struct Metadata { string name; string symbol; string description; string banner_uri; }
    struct Collection { string name; string symbol; string description; string banner_uri; uint256 limit; uint256 royalty; address token_address; address owner_of; }

    address private _sale_contract_address;
    address private _auction_contract_address;

    mapping(address => bool) private _exists;
    mapping(address => Collection) private _collection;

    constructor(address owner_of_) Pausable(owner_of_) {}

    event collectionCreated(Metadata metadata, uint256 limit, uint256 royalty, address token_address, address owner_of);

    /**
     * @dev helps create new ERC721 collection
     * @param metadata includes name, symbol, description and link to banner image.
     * @param limit maximal amount of NFTs should be minted by contract.
     * @param royalty percentage which should return to collection creator.
     */
    function createCollection(Metadata memory metadata, uint256 limit, uint256 royalty) public notPaused {
        SelectiveCollectionToken token = new SelectiveCollectionToken(metadata.name, metadata.symbol, msg.sender, limit, royalty);
        address token_address = address(token);
        _collection[token_address] = Collection(metadata.name, metadata.symbol, metadata.description, metadata.banner_uri, limit, royalty, token_address, msg.sender);
        _exists[token_address] = true;
        emit collectionCreated(metadata, limit, royalty, token_address, msg.sender);
        address[] memory addresses = new address[](1);
        addresses[0] = token_address;
        ISale(_sale_contract_address).update(addresses);
        ISale(_auction_contract_address).update(addresses);
    }

    /**
     * @dev helps add exists ERC721 collection
     * @param metadata includes name, symbol, description and link to banner image.
     * @param limit maximal amount of NFTs should be minted by contract.
     * @param royalty percentage which should return to collection creator.
     */
    function addCollection(Metadata memory metadata, uint256 limit, uint256 royalty, address token_address) public notPaused {
        require(!_exists[token_address], "Collection has been registered");
        metadata.name = IERC721Metadata(token_address).name();
        metadata.symbol = IERC721Metadata(token_address).symbol();
        _collection[token_address] = Collection(metadata.name, metadata.symbol, metadata.description, metadata.banner_uri, limit, royalty, token_address, msg.sender);
        _exists[token_address] = true;
        emit collectionCreated(metadata, limit, royalty, token_address, msg.sender);
        address[] memory addresses = new address[](1);
        addresses[0] = token_address;
        ISale(_sale_contract_address).update(addresses);
        ISale(_auction_contract_address).update(addresses);
    }

    function setSaleAddress(address sale_contract_address) public {
        require(msg.sender == _owner_of, "Permission denied sale");
        _sale_contract_address = sale_contract_address;
    }

    function setAuctionAddress(address auction_contract_address) public {
        require(msg.sender == _owner_of, "Permission denied auction");
        _auction_contract_address = auction_contract_address;
    }
}
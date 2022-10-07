// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {ISale} from "../../../ISale.sol";
import {GenerativeCollectionToken} from "./GenerativeCollectionToken.sol";
import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title GenerativeCollectionFactory
 * @notice Manages the make an offer logic. 
 */
contract GenerativeCollectionFactory is Pausable {
    struct Metadata { string name; string symbol; string description; string banner_uri; string token_uri; }
    struct Collection { string name; string symbol; string description; string banner_uri; string token_uri; address owner_of; uint256 price; uint256 royalty; uint256 limit; uint256 limit_per_account; address token_address; uint256 start_time; }
    
    address private _sale_contract_address;
    address private _auction_contract_address;

    mapping(address => bool) private _exists;
    mapping(address => Collection) private _collection;

    constructor(address owner_of_) Pausable(owner_of_) {}

    event collectionCreated(Metadata metadata, address owner_of, uint256 price, uint256 royalty, uint256 limit, uint256 limit_per_account, address token_address, uint256 start_time);

    /**
     * @dev helps create new ERC721 collection
     * @param metadata includes name, symbol, description, link to banner image and link to tokens metadata folder.
     * @param limit maximal amount of NFTs should be minted by contract.
     * @param royalty percentage which should return to collection creator.
     */
    function createCollection(Metadata memory metadata, uint256 price, uint256 royalty, uint256 limit, uint256 limit_per_account, uint256 start_time) public {
        GenerativeCollectionToken token = new GenerativeCollectionToken(metadata.name, metadata.symbol, metadata.token_uri, msg.sender, price, royalty, limit, limit_per_account, start_time, _owner_of);
        address token_address = address(token);
        _collection[token_address] = Collection(metadata.name, metadata.symbol, metadata.description, metadata.banner_uri, metadata.token_uri, msg.sender, price, royalty, limit, limit_per_account, token_address, start_time);
        _exists[token_address] = true;
        emit collectionCreated(metadata, msg.sender, price, royalty, limit, limit_per_account, token_address, start_time);
        address[] memory addresses = new address[](1);
        addresses[0] = token_address;
        ISale(_sale_contract_address).update(addresses);
        ISale(_auction_contract_address).update(addresses);
    }

     /**
     * @dev helps add exists ERC721 collection
     * @param metadata includes name, symbol, description, link to banner image and link to tokens metadata folder.
     * @param limit maximal amount of NFTs should be minted by contract.
     * @param royalty percentage which should return to collection creator.
     */
    function addCollection(Metadata memory metadata, uint256 price, uint256 royalty, uint256 limit, uint256 limit_per_account, address token_address, uint256 start_time) public {
        require(!_exists[token_address], "Collection has been registered");
        metadata.name = IERC721Metadata(token_address).name();
        metadata.symbol = IERC721Metadata(token_address).symbol();
        _collection[token_address] = Collection(metadata.name, metadata.symbol, metadata.description, metadata.banner_uri, metadata.token_uri, msg.sender, price, royalty, limit, limit_per_account, token_address, start_time);
        _exists[token_address] = true;
        emit collectionCreated(metadata, msg.sender, price, royalty, limit, limit_per_account, token_address, start_time);
        address[] memory addresses = new address[](1);
        addresses[0] = token_address;
        ISale(_sale_contract_address).update(addresses);
        ISale(_auction_contract_address).update(addresses);
    }

    function setSaleAddress(address sale_contract_address) public {
        require(msg.sender == _owner_of);
        _sale_contract_address = sale_contract_address;
    }

    function setAuctionAddress(address auction_contract_address) public {
        require(msg.sender == _owner_of);
        _auction_contract_address = auction_contract_address;
    }
}
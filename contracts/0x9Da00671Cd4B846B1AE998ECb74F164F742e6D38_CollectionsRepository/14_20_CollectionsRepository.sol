// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./OmniERC721.sol";
import "../interfaces/ICollectionsRepository.sol";
import { CreateParams } from "../structs/erc721/ERC721Structs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CollectionsRepository
 * @author Omnisea
 * @custom:version 1.1
 * @notice CollectionsRepository is responsible for ERC721 contract creation and storing a reference.
 */
contract CollectionsRepository is ICollectionsRepository, Ownable {
    event Created(address addr, address creator);

    mapping(address => address[]) public userCollections;
    address public collectionFactory;
    address public tokenFactory;

    /**
     * @notice Creates ERC721 collection contract and stores the reference to it with relation to a creator.
     *
     * @param params See CreateParams struct in ERC721Structs.sol.
     * @param creator The address of the collection creator.
     */
    function create(
        CreateParams calldata params,
        address creator
    ) external override {
        require(msg.sender == collectionFactory);
        OmniERC721 collection = new OmniERC721(_getSymbolByName(params.name), params, creator, tokenFactory);
        userCollections[creator].push(address(collection));
        emit Created(address(collection), creator);
    }

    /**
     * @notice Sets the CollectionFactory.
     *
     * @param factory The address of the CollectionFactory contract.
     */
    function setCollectionFactory(address factory) external onlyOwner {
        collectionFactory = factory;
    }

    /**
     * @notice Sets the TokenFactory.
     *
     * @param factory The address of the TokenFactory contract.
     */
    function setTokenFactory(address factory) external onlyOwner {
        tokenFactory = factory;
    }

    /**
     * @notice Getter of the collections created by a given address.
     *
     * @param user The address of the collections creator.
     */
    function getAllByUser(address user) external view returns (address[] memory) {
        return userCollections[user];
    }

    /**
     * @notice Prepares the ERC721 collection symbol based on the collection's name.
     *
     * @param name The name of the collection.
     */
    function _getSymbolByName(string memory name) private pure returns (string memory) {
        bytes memory _tSym = new bytes(3);
        _tSym[0] = bytes(name)[0];
        _tSym[1] = bytes(name)[1];
        _tSym[2] = bytes(name)[2];
        return string(_tSym);
    }
}
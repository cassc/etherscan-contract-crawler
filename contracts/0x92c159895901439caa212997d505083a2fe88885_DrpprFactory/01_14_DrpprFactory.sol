// SPDX-License-Identifier: MIT
// Drppr Factory v0.1.0
//  ▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ 
// ▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
// ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌
// ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌
// ▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌
// ▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
// ▐░▌       ▐░▌▐░█▀▀▀▀█░█▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀█░█▀▀ 
// ▐░▌       ▐░▌▐░▌     ▐░▌  ▐░▌          ▐░▌          ▐░▌     ▐░▌  
// ▐░█▄▄▄▄▄▄▄█░▌▐░▌      ▐░▌ ▐░▌          ▐░▌          ▐░▌      ▐░▌ 
// ▐░░░░░░░░░░▌ ▐░▌       ▐░▌▐░▌          ▐░▌          ▐░▌       ▐░▌
//  ▀▀▀▀▀▀▀▀▀▀   ▀         ▀  ▀            ▀            ▀         ▀ .io
//  The no-code digital collectibles launchpad you needed

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Drppr721.sol";

/**
 * @title Factory
 * @dev A contract to create clone contracts based on a template contract.
 */
contract DrpprFactory is Ownable {
    // The address of the template contract
    address internal implementationAddress;
    
    // Treasuryeloper's address
    address internal treasury;

    // Mapping of a user address to an array of deployed contracts' addresses
    mapping(address => address[]) internal userDeployedContracts;

    /**
     * @dev Emitted when a new clone contract (collection) is created
     */
    event collectionCreated(address indexed sender, address indexed receiver, address collection);

    /**
     * @dev Contract constructor
     * @param _implementationAddress The address of the template contract
     * @param _treasury The treasury's address
     */
    constructor(address _implementationAddress, address _treasury) {
        implementationAddress = _implementationAddress;
        treasury = _treasury;
    }

    /**
     * @dev Struct for the data of the collection to be created
     */
    struct CollectionData {
        string name;
        string symbol;
        string baseURI;
        uint256 maxSupply;
        uint256 maxFreeSupply;
        uint256 costPublic;
        uint256 maxMintPublic;
        uint256 freePerWallet;
        uint256 platformFee;
        uint256 costWL;
        uint256 maxMintWL;
        address withdrawAddress;
    }

    /**
     * @dev Creates a new clone contract (collection)
     * @param _data CollectionData struct with data for the new collection
     * @return The address of the newly created clone contract
     */
    function createCollection(CollectionData memory _data) public returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_data.name, block.number));
        address clone = ClonesUpgradeable.cloneDeterministic(implementationAddress, salt);
        Drppr721 token = Drppr721(clone);

        require(_data.platformFee >= 5 && _data.platformFee <= 100, "must be between 5 and 100");
        
        InitParams memory params = InitParams({
            baseURI: _data.baseURI,
            maxSupply: _data.maxSupply,
            maxFreeSupply: _data.maxFreeSupply,
            costPublic: _data.costPublic,
            maxMintPublic: _data.maxMintPublic,
            freePerWallet: _data.freePerWallet,
            platformFee: _data.platformFee,
            costWL: _data.costWL,
            maxMintWL: _data.maxMintWL,
            withdrawAddress: _data.withdrawAddress,
            treasury: treasury
        });

        token.initialize(_data.name, _data.symbol, params);

        token.transferOwnership(msg.sender);

        userDeployedContracts[msg.sender].push(clone);

        emit collectionCreated(msg.sender, _data.withdrawAddress, clone);
        return clone;
    }

    /**
     * @dev Sets the address of the template contract
     * @param _newImplementationAddress The address of the new template contract
     */
    function setImplementationAddress(address _newImplementationAddress) public onlyOwner {
        implementationAddress = _newImplementationAddress;
    }

    /**
     * @dev Sets the treasury's address
     * @param _newTreasury The new treasury's address
     */
    function setTreasury(address _newTreasury) public onlyOwner {
        treasury = _newTreasury;
    }

    /**
     * @dev Gets the addresses of all contracts deployed by a specific user
     * @param user The user's address
     * @return Array of addresses of contracts deployed by the user
     */
    function getDeployedContracts(address user) public view returns (address[] memory) {
        return userDeployedContracts[user];
    }
}
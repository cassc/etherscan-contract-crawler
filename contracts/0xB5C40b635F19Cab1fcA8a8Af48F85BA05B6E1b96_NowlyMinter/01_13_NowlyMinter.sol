// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./NowlyCollection.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract NowlyMinter is Ownable {

    /**
        *   @dev Initializes the contract by setting a 
        *   `NowlyCollection`, `endDate`, `price`, `mintLimit`, and a `publicMinting` to the contract.
        *   @param _address The `NowlyCollection` contract address.
        *   @param _endDate The minting End Date.
        *   @param _price The Price per NFT.
        *   @param _mintLimit The maxLimit for how many NFTs an account can mint.
        *   @param _publicMinting The initial value of publicMinting.
        */
    constructor(NowlyCollection _address, uint _endDate, uint256 _price, uint256 _mintLimit, bool _publicMinting) {
        season = 1;
        nowlyCollection = _address;
        endDate = _endDate;
        price = _price;
        mintLimit = _mintLimit;
        publicMinting = _publicMinting;
    }

    // The contract address of the `NowlyCollection`.
    NowlyCollection public nowlyCollection;

    // The current minting season.
    uint256 public season;

    // The minting end date.
    uint public endDate;

    // The minting flag.
    bool public publicMinting;

    // The Price in Wei per NFT.
    uint256 public price;

    // The Limit of how many an `address` can mint.
    uint256 public mintLimit;
    
    // Mapping of the authorized `address` to private mint this `season`.
    mapping(uint256 => mapping(address => bool)) authorized;
    
    // Mapping of the `address` total minted this `season`.
    mapping(uint256 => mapping(address => uint256)) userMinted; 

    /**
        *   Fetches the amount of NFTs the `account` has minted for the current `season`.
        *   @param _address The address that is being checked for how many NFTs have been minted total.
        *   @return uint256 The amount of NFTs minted this `season`.
        */
    function userMintedNFTs(address _address) 
        public
        view
        returns (uint256)
    {
        return userMinted[season][_address];
    }
    
    /**
        *   Checks if the `_address` is authorized to private mint for the current `season`.
        *   @param _address The address that is being checked for authorization.
        *   @return bool If the address is `authorized` or not.
        */
    function isAuthorized(address _address)
        public
        view
        returns (bool)
    {
        return authorized[season][_address];
    }

    /**
        *   Fetches the current balance of this contract.
        *   @return uint256 The Eth balance of the contract.
        */
    function getContractBalance()
        public
        view
        returns (uint256)
    {
        return address(this).balance;
    }

    /**
        *   Updates the current value of the `mintLimit`.
        *   @param _mintLimit The new value of the `mintLimit`.
        *   @notice Can only be executed by the Owner.
        */
    function setMintingLimit(uint256 _mintLimit)
        public
        onlyOwner
    {
        mintLimit = _mintLimit;
    }

    /**
        *   Updates the NowlyCollection pointer to mint from a different contract.
        *   @param _address The new value of the `nowlyCollection`.
        *   @notice Can only be executed by the Owner.
        */
    function setMintingContract(NowlyCollection _address) 
        public
        onlyOwner
    {
        nowlyCollection = _address;
    }
    
    /**
        *   Updates the current value of the `publicMinting` flag.
        *   @param _publicMinting The new value of the `publicMinting`.
        *   @notice Can only be executed by the Owner.
        */
    function setPublicMinting(bool _publicMinting)
        public
        onlyOwner
    {
        publicMinting = _publicMinting;
    }

    /**
        *   Updates the current price per NFT minted.
        *   @param _price The new value of the `price`.
        *   @notice Can only be executed by the Owner. 
        */
    function setPrice(uint256 _price) 
        public
        onlyOwner
    {
        price = _price;
    }

    /**
        *   Batch authorize addresses to private mint this `season`.
        *   @param _addresses The array of Addresses that will be authorized to private mint this `season`.
        *   @notice Can only be executed by the Owner.
        */
    function authorizeAddresses(address[] calldata _addresses) 
        public
        onlyOwner
    {
        for(uint256 i = 0; i < _addresses.length; ++i) {
            authorized[season][_addresses[i]] = true;
        }
    }

    /**
        *   Updates the minting end date.
        *   @param timestamp The new value of the `endDate`.
        *   @notice Can only be executed by the Owner. 
        */
    function setEndDate(uint timestamp)
        public
        onlyOwner
    {
        require(timestamp > block.timestamp, "End date must be greater than today");
        endDate = timestamp;
    }

    /**
        *   Updates the value of the current `season`.
        *   @param _season The new value of the `season`.
        *   @notice Can only be executed by the Owner. 
        */
    function setSeason(uint256 _season) 
        public
        onlyOwner
    {
        season = _season;
    }

    /**
        *   Increments the `current` season by 1.
        *   @notice Can only be executed by the Owner.
        */
    function incrementSeason()
        public
        onlyOwner
    {
        ++season;
    }

    /**
        *   Reopens the current minting `season`.
        *   @param timestamp The new value of the `endDate`.
        *   @param _publicMinting The value of the `publicMinting`
        *   @notice Can only be executed by the Owner.
        */
    function reopenMinting(uint timestamp, bool _publicMinting)
        public
        onlyOwner
    {
        require(timestamp > block.timestamp, "End date must be greater than today");
        endDate = timestamp;
        publicMinting = _publicMinting;
    }

    /**
        *   Opens a new minting `season`.
        *   @param timestamp The new value of the `endDate`.
        *   @param _publicMinting The new value of the `_publicMinting`.
        *   @notice Can only be executed by the Owner.
        */
    function openNewMintingSeason(uint timestamp, bool _publicMinting)
        public
        onlyOwner
    {
        require(timestamp > block.timestamp, "End date must be greater than today");
        endDate = timestamp;
        publicMinting = _publicMinting;
        incrementSeason();
    }

    /**
        *   Mints an amount of NFTs from the `NowlyCollection` contract.
        *   @param amount The amount of NFTs to be minted.
        *   @notice Can only be executed by the Owner or an Authorized Address.
        */
    function mint(uint256 amount)
        public
        payable
    {
        require(endDate > block.timestamp, "Minting has ended");
        require(0 < amount, "Must set a valid amount");
        uint256 totalMinted = userMintedNFTs(msg.sender) + amount;
        require(totalMinted <= mintLimit, "You have exceeded the minting limit for this season");
        if(!publicMinting) {
            require(isAuthorized(msg.sender), "You are not authorized to private mint.");
        }
        require(price * amount == msg.value, "Not enough funds");
        userMinted[season][msg.sender] += amount;
        nowlyCollection.mint(msg.sender, amount);
    }
    
    /**
        *   Transfers the Contracts funds to the Owner address.
        *   @notice Can only be executed by the Owner.
        */
    function withdrawFunds()
        public
        onlyOwner
    {
        payable(owner()).transfer(address(this).balance);
    }
}
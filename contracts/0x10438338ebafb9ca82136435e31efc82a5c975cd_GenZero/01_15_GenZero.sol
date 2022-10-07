//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./MerkleDistributor.sol";

contract GenZero is ERC721A, MerkleDistributor, Ownable, ReentrancyGuard {
    using Strings for string;

    uint256 public constant maxGenZero = 6000;
    uint256 public maxPerMint = 100;
    bool public mintingIsActive = false;
    bool public bioUpgradingIsActive = false;
    bool public publicIsActive = false;


    string public currentSeasonalCollectionURI;

    uint256 public mintPrice;


    // Mapping between tokenId => seasonal collectiong baseURI
    mapping(uint256 => string) private _gensRegistry;
    
    event GenUpdated(uint256 tokenId, string newBaseURI);

    constructor() ERC721A("Eternity Complex", "GenZero") {}

    modifier ableToMint(uint256 numberOfGens) {
        require(totalSupply() + numberOfGens <= maxGenZero, 'Max Token Supply');
        _;
    }

    /*
    * Withdraw funds
    */
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Zero balance");

        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    /*
    * Set Mint Price
    */
    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setMintMax(uint256 newMax) public onlyOwner {
        maxPerMint = newMax;
    }
    //---------------------------------------------------------------------------------
    /**
    * Current on-going collection that is avaiable to BioUpgrade or use as base for minting
    */
    function setCurrentCollectionBaseURI(string memory newuri) public onlyOwner {
        currentSeasonalCollectionURI = newuri;
    }

    /*
    * Pause bioupgrading if active, make active if paused
    */
    function flipBioUpgradingState() public onlyOwner {
        bioUpgradingIsActive = !bioUpgradingIsActive;
    }
    /*
    * Pause minting if active, make active if paused
    */
    function flipMintingState() public onlyOwner {
        mintingIsActive = !mintingIsActive;
    }
    /*
    * Pause minting if active, make active if paused
    */
    function flipPublicState() public onlyOwner {
        publicIsActive = !publicIsActive;
    }

    /**
     * allow list
     */
    function setAllowList(bytes32 merkleRoot) external onlyOwner {
        _setAllowList(merkleRoot);
    }
    


    /**
     * arcClaim
     */
    function arcListMint(uint256 numberOfGens, bytes32[] memory merkleProof) 
    external
    ableToClaim(msg.sender, merkleProof)
    ableToMint(numberOfGens)
    nonReentrant 
    {
        require(mintingIsActive, "claim not active");
        require(numberOfGens > 0, "cannot mint zero");

        for(uint i = 0; i < numberOfGens; i++) {
            _gensRegistry[((_currentIndex) + i)] = currentSeasonalCollectionURI;                       
        }
        
        _setAllowListMinted(msg.sender, numberOfGens);
        _safeMint(msg.sender, numberOfGens);
    }

    /**
     * public
     */
    function publicMint(uint256 numberOfGens) 
    external
    payable
    ableToMint(numberOfGens)
    nonReentrant
    {
        require(publicIsActive, "public  not active");
        require(numberOfGens <= maxPerMint, 'over max mint');
        require(numberOfGens * mintPrice == msg.value, 'Ether value not correct');
        
        for(uint i = 0; i < numberOfGens; i++) {
            _gensRegistry[((_currentIndex) + i)] = currentSeasonalCollectionURI;                       
        }

        _safeMint(msg.sender, numberOfGens);

        
    }

    /**
    * BioUpgrading existing Gens.
    * Changing current baseURI of a token to a new one, that is current Season topic.
    */
    function bioUpgrade(uint256[] memory tokenIds) public payable {
        require(bioUpgradingIsActive, "BioUpgrading not active");
        require(tokenIds.length * mintPrice == msg.value, 'Ether value not correct');
        for(uint i = 0; i < tokenIds.length; i++) {
            // Allow bioupgrading for owner only
            if (ownerOf(tokenIds[i]) != msg.sender || !_exists(tokenIds[i])) {
                require(false, "Gen not owned");
            }
        }
        
        for(uint i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] < maxGenZero, "Token exceed max supply");
            _gensRegistry[tokenIds[i]] = currentSeasonalCollectionURI;
            emit GenUpdated(tokenIds[i], currentSeasonalCollectionURI);
        }
    }
    
    /// ERC721 related
    /**
     * @dev See {ERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");

        string memory baseURI = _gensRegistry[tokenId];
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), '.json'));
    }

    function _baseURI() internal view override returns (string memory) {
        return currentSeasonalCollectionURI;
    }

}
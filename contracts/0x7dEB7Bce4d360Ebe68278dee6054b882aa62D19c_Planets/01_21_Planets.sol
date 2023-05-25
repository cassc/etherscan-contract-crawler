// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import './AbstractERC1155Factory.sol';
import "./PaymentSplitter.sol";

/*
* @title ERC1155 token for Pixelvault planets
*
* @author Niftydude
*/
contract Planets is AbstractERC1155Factory, PaymentSplitter  {
    using Counters for Counters.Counter;
    Counters.Counter private counter; 

    uint256 constant MOON_ID = 3;
    
    uint256 public claimWindowOpens = 4788607340;
    uint256 public claimWindowCloses = 4788607340;
    uint256 public purchaseWindowOpens = 4788607340;
    uint256 public daoBurnWindowOpens = 4788607340;
    uint256 public burnWindowOpens = 4788607340;

    ERC721Contract public comicContract;
    ERC721Contract public founderDAOContract;

    bool burnClosed;
    mapping(uint256 => bool) private isSaleClosed;
    mapping(uint256 => bool) private isClaimClosed;

    mapping(uint256 => Planet) public planets;

    event Claimed(uint indexed index, address indexed account, uint amount);
    event Purchased(uint indexed index, address indexed account, uint amount);

    struct Planet {
        uint256 mintPrice;
        uint256 maxSupply;
        uint256 maxPurchaseSupply;
        uint256 maxPurchaseTx;
        uint256 purchased;
        string ipfsMetadataHash;
        bytes32 merkleRoot;
        mapping(address => uint256) claimed;
    }

    constructor(
        string memory _name, 
        string memory _symbol,  
        address _comicContract,
        address _founderDAOContract,
        address[] memory payees,
        uint256[] memory shares_
    ) ERC1155("ipfs://") PaymentSplitter(payees, shares_) {
        name_ = _name;
        symbol_ = _symbol;

        comicContract = ERC721Contract(_comicContract);
        founderDAOContract = ERC721Contract(_founderDAOContract);
    }

    /**
    * @notice adds a new planet
    * 
    * @param _merkleRoot the merkle root to verify eligile claims
    * @param _mintPrice mint price in gwei
    * @param _maxSupply maximum total supply
    * @param _maxPurchaseSupply maximum supply that can be purchased
    * @param _ipfsMetadataHash the ipfs hash for planet metadata
    */
    function addPlanet(
        bytes32 _merkleRoot, 
        uint256  _mintPrice, 
        uint256 _maxSupply,
        uint256 _maxPurchaseSupply,      
        uint256 _maxPurchaseTx,        
        string memory _ipfsMetadataHash
    ) public onlyOwner {
        Planet storage p = planets[counter.current()];
        p.merkleRoot = _merkleRoot;
        p.mintPrice = _mintPrice;
        p.maxSupply = _maxSupply;
        p.maxPurchaseSupply = _maxPurchaseSupply;
        p.maxPurchaseTx = _maxPurchaseTx;                                        
        p.ipfsMetadataHash = _ipfsMetadataHash;

        counter.increment();
    }    

    /**
    * @notice edit an existing planet
    * 
    * @param _merkleRoot the merkle root to verify eligile claims
    * @param _mintPrice mint price in gwei
    * @param _maxPurchaseSupply maximum total supply
    * @param _ipfsMetadataHash the ipfs hash for planet metadata
    * @param _planetIndex the planet id to change
    */
    function editPlanet(
        bytes32 _merkleRoot, 
        uint256  _mintPrice, 
        uint256 _maxPurchaseSupply,
        uint256 _maxPurchaseTx,        
        string memory _ipfsMetadataHash,
        uint256 _planetIndex
    ) external onlyOwner {
        require(exists(_planetIndex), "EditPlanet: planet does not exist");

        planets[_planetIndex].merkleRoot = _merkleRoot;
        planets[_planetIndex].mintPrice = _mintPrice;  
        planets[_planetIndex].maxPurchaseSupply = _maxPurchaseSupply;     
        planets[_planetIndex].maxPurchaseTx = _maxPurchaseTx;                       
        planets[_planetIndex].ipfsMetadataHash = _ipfsMetadataHash;    
    }    

    /**
    * @notice mint planet tokens
    * 
    * @param planetID the planet id to mint
    * @param amount the amount of tokens to mint
    */
    function mint(uint256 planetID, uint256 amount, address to) external onlyOwner {
        require(exists(planetID), "Mint: planet does not exist");
        require(totalSupply(planetID) + amount <= planets[planetID].maxSupply, "Mint: Max supply reached");

        _mint(to, planetID, amount, "");
    }

    /**
    * @notice close planet sale
    * 
    * @param planetIds the planet ids to close the sale for
    */
    function closeSale(uint256[] calldata planetIds) external onlyOwner {
        uint256 count = planetIds.length;

        for (uint256 i; i < count; i++) {
            require(exists(planetIds[i]), "Close sale: planet does not exist");

            isSaleClosed[planetIds[i]] = true;
        }
    }

    /**
    * @notice close claiming planets for MHs hold
    * 
    * @param planetIds the planet ids to close claiming for 
    */
    function closeClaim(uint256[] calldata planetIds) external onlyOwner {
        uint256 count = planetIds.length;

        for (uint256 i; i < count; i++) {
            require(exists(planetIds[i]), "Close claim: planet does not exist");

            isClaimClosed[planetIds[i]] = true;
        }
    }

    /**
    * @notice close burning comics for moon tokens
    */
    function closeBurn() external onlyOwner {
        burnClosed = true;
    }

    /**
    * @notice edit windows for claiming and purchasing planets
    * 
    * @param _claimWindowOpens UNIX timestamp for claiming window opening time
    * @param _claimWindowOpens UNIX timestamp for claiming window close time
    * @param _claimWindowOpens UNIX timestamp for purchasing window opening time
    */
    function editWindows(
        uint256 _purchaseWindowOpens,
        uint256 _daoBurnWindowOpens,
        uint256 _burnWindowOpens,
        uint256 _claimWindowOpens, 
        uint256 _claimWindowCloses
    ) external onlyOwner {   
        claimWindowOpens = _claimWindowOpens;
        claimWindowCloses = _claimWindowCloses;
        purchaseWindowOpens = _purchaseWindowOpens;
        daoBurnWindowOpens = _daoBurnWindowOpens;
        burnWindowOpens = _burnWindowOpens;
    }

    /**
    * @notice purchase planet tokens
    * 
    * @param planetID the planet id to purchase
    * @param amount the amount of tokens to purchase
    */
    function purchase(uint256 planetID, uint256 amount) external payable whenNotPaused {
        require(!isSaleClosed[planetID], "Purchase: sale is closed");
        require (block.timestamp >= purchaseWindowOpens, "Purchase: window closed");
        require(amount <= planets[planetID].maxPurchaseTx, "Purchase: Max purchase per tx exceeded");                
        require(planets[planetID].purchased + amount <= planets[planetID].maxPurchaseSupply, "Purchase: Max purchase supply reached");
        require(totalSupply(planetID) + amount <= planets[planetID].maxSupply, "Purchase: Max total supply reached");
        require(msg.value == amount * planets[planetID].mintPrice, "Purchase: Incorrect payment"); 

        planets[planetID].purchased += amount;

        _mint(msg.sender, planetID, amount, "");

        emit Purchased(planetID, msg.sender, amount);
    }

    /**
    * @notice burn punks comics to receive moon tokens
    * 
    * @param tokenIds the token ids of the comics to burn
    */
    function burnComicForMoon(uint256[] calldata tokenIds) external whenNotPaused {
        require(!burnClosed, "Burn: is closed");
        require((founderDAOContract.balanceOf(msg.sender) > 0 && block.timestamp >= daoBurnWindowOpens) || block.timestamp >= burnWindowOpens, "burnComicForMoon: window not open or DAO token required");

        uint256 count = tokenIds.length;

        require(count <= 40, "Too many tokens");
        require(totalSupply(MOON_ID) + count <= planets[MOON_ID].maxSupply, "Burn comic: Max moon supply reached");

        for (uint256 i; i < count; i++) {
            comicContract.burn(tokenIds[i]);
        }

       _mint(msg.sender, MOON_ID, count, "");
    }

    /**
    * @notice burn punks comics to receive moon tokens
    * 
    * @param amount the amount of planet tokens to claim
    * @param planetId the id of the planet to claim for
    * @param index the index of the merkle proof
    * @param maxAmount the max amount óf planet tokens sender is eligible to claim
    * @param merkleProof the valid merkle proof of sender for given planet id
    */
    function claim(
        uint256 amount,
        uint256 planetId,
        uint256 index,
        uint256 maxAmount,
        bytes32[] calldata merkleProof
    ) external whenNotPaused {
        require(!isClaimClosed[planetId], "Claim: is closed");        
        require (block.timestamp >= claimWindowOpens && block.timestamp <= claimWindowCloses, "Claim: time window closed");        
        require(planets[planetId].claimed[msg.sender] + amount <= maxAmount, "Claim: Not allowed to claim given amount");

        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, maxAmount));
        require(
            MerkleProof.verify(merkleProof, planets[planetId].merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        planets[planetId].claimed[msg.sender] = planets[planetId].claimed[msg.sender] + amount;

        _mint(msg.sender, planetId, amount, "");
        emit Claimed(planetId, msg.sender, amount);                
    }

    /**
     * @notice Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     * 
     * @param account the payee to release funds for
     */
    function release(address payable account) public override onlyOwner {
        super.release(account);
    } 

    /**
    * @notice return total supply for all existing planets
    */
    function totalSupplyAll() external view returns (uint[] memory) {
        uint[] memory result = new uint[](counter.current());

        for(uint256 i; i < counter.current(); i++) {
            result[i] = totalSupply(i);
        }

        return result;
    }

    /**
    * @notice indicates weither any token exist with a given id, or not
    */
    function exists(uint256 id) public view override returns (bool) {
        return planets[id].maxSupply > 0;
    }    

    /**
    * @notice returns the metadata uri for a given id
    * 
    * @param _id the planet id to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
            require(exists(_id), "URI: nonexistent token");
            
            return string(abi.encodePacked(super.uri(_id), planets[_id].ipfsMetadataHash));
    }    
}

interface ERC721Contract is IERC721 {
    function burn(uint256 tokenId) external;
}
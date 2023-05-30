// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
  _    _                           _    _                 _           
 | |  | |                         | |  | |               (_)          
 | |__| | __ _ _ __  _ __  _   _  | |__| | ___  _ __ ___  _  ___  ___ 
 |  __  |/ _` | '_ \| '_ \| | | | |  __  |/ _ \| '_ ` _ \| |/ _ \/ __|
 | |  | | (_| | |_) | |_) | |_| | | |  | | (_) | | | | | | |  __/\__ \
 |_|  |_|\__,_| .__/| .__/ \__, | |_|  |_|\___/|_| |_| |_|_|\___||___/
              | |   | |     __/ |                                     
              |_|   |_|    |___/                                      

/// @title Happy Homies Smart Contract
/// @author DuroNFT

Thanks to numerous resources around the NFT community we have created a contract
that tries to keep the gas fees low for our Happy Homies.

We implemented ERC721A to save on Gas during the initial mint. (https://erc721a.org)
Allow List - We used the Merkle Tree method to provide proof of allow list.

Founders: @ChichiNFT & @DuroNFT
Optimization credits: @nftchance
**/

/// Contract ///
contract happyHomies is ERC721A, Ownable, ReentrancyGuard {  
    using Address for address;
    using Strings for uint256;

    // Constants //
    uint256 constant MAX_SUPPLY = 10000;
    uint256 public price = 0.06 ether;
    uint256 public maxMint = 2; 
    uint256 public maxPresaleMint = 1; 
    uint256 public maxContestMint = 2;

    bool public saleActive;
    bool public presaleActive;

    string public _baseTokenURI;
    string public homiesProvenance;

    mapping (address => uint256) public _tokensMintedByAddress;
    mapping (address => uint256) public publicsaleAddressMinted;
    bytes32 public presaleMerkleRoot;
    bytes32 public contestMerkleRoot;

    // Founders and Project Addresses //
    address a1 = 0xB21e19093deeC7Cd11428AD4619f351e6daAD653;
    address a2 = 0x7f1086B3AEA172d38F51e7fa466eec27Ea458558;
    address a3 = 0x660fE4fB6BEA04B4cC5C68B0CB99b939d982d857;

    // Constructor //
    constructor( )
        ERC721A("Happy Homies", "HH") {                  
        // team gets the first NFTs to represent themselves in the community
        _safeMint( a3, 1);
        _safeMint( a1, 1);
        _safeMint( a2, 1);
        _safeMint( 0x4210EeE2bc528b0A846EaA016cE8167A840B8B23, 1);
        _safeMint( 0xC2CB0904B3EE10A71e5e61cDc5044946A1Dd4983, 1);
        _safeMint( 0x28834F2c5643c7D490f51Ca60175bedA7729eC89, 1);
    }

    // Modifiers //
    modifier onlySaleActive() {
        require(saleActive, "Public sale is not active");
        _;
    }

    modifier onlyPresaleActive() {
        require(presaleActive, "Presale is not active");
        _;
    }

    // Minting Functions //

    // Public sale minting function, max 2 per wallet
    function mintToken(uint256 quantity) external payable onlySaleActive nonReentrant() {
        require(quantity <= maxMint, "You can not mint more than alowed");
        require(price * quantity == msg.value, "Wrong amout of ETH sent");
        require(publicsaleAddressMinted[msg.sender] + quantity <= maxMint, "Can only mint 2 per wallet");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Can not mint more than max supply");

        publicsaleAddressMinted[msg.sender] += quantity;
           _safeMint( msg.sender, quantity);
    } 

    // Presale minting function, max 1.
    function mintPresale(uint256 quantity, bytes32[] calldata proof) external payable onlyPresaleActive nonReentrant() {
        require(MerkleProof.verify(proof, presaleMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address is not on 1 MINT Allowlist");
        require(price * quantity == msg.value, "Wrong amout of ETH sent");
        require(_tokensMintedByAddress[msg.sender] + quantity == maxPresaleMint, "Can only mint 1 token during PreSale");
        require(totalSupply() + quantity < MAX_SUPPLY, "Can not mint more than max supply");

        _tokensMintedByAddress[msg.sender] += quantity;
         _safeMint(msg.sender, quantity);
     
    }

    // Contest Presale minting function, max 2.
    function mintContest(uint256 quantity, bytes32[] calldata proof) external payable onlyPresaleActive nonReentrant() {
        require(MerkleProof.verify(proof, contestMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address is not on 2 MINT Allowlist");
        require(price * quantity == msg.value, "Wrong amout of ETH sent");
        require(_tokensMintedByAddress[msg.sender] + quantity <= maxContestMint, "Can only mint 2 tokens during PreSale");
        require(totalSupply() + quantity < MAX_SUPPLY, "Can not mint more than max supply");

        _tokensMintedByAddress[msg.sender] += quantity;
         _safeMint(msg.sender, quantity);
     
    }

    // Dev minting function 
        function mintDev(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Minting too many");
        _safeMint(msg.sender, quantity);
    }
    
    // Metadata //
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Setters //
	function setPresaleMerkleRoot(bytes32 presaleRoot) public onlyOwner {
		presaleMerkleRoot = presaleRoot;
	}

    function setContestMerkleRoot(bytes32 contestRoot) public onlyOwner {
		contestMerkleRoot = contestRoot;
	}

    function setPresaleActive(bool val) external onlyOwner {
        presaleActive = val;
    }

    function setSaleActive(bool val) external onlyOwner {
        saleActive = val;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setMaxMint(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    function setMaxPresaleMint(uint256 _maxPresaleMint) external onlyOwner {
        maxPresaleMint = _maxPresaleMint;
    }

    function setMaxContestMint(uint256 _maxContestMint) external onlyOwner {
        maxContestMint = _maxContestMint;
    }    

    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        homiesProvenance = provenanceHash;
    }

    // Withdraw funds from contract for the founders and Project Wallet.
    function withdrawAll() public payable onlyOwner {
        uint256 _balance = address(this).balance;
        uint256 percent = _balance / 100;
        // 54% Split among the founders
        require(payable(a1).send(percent * 36));
        require(payable(a2).send(percent * 18));
        // 46% to the Project Wallet
        require(payable(a3).send(percent * 46));
    }
}
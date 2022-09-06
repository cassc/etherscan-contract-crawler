// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
   _____            _         _____                   
  / ____|          (_)       / ____|                  
 | |  __  ___ _ __  _  ___  | |  __  __ _ _ __   __ _ 
 | | |_ |/ _ \ '_ \| |/ _ \ | | |_ |/ _` | '_ \ / _` |
 | |__| |  __/ | | | |  __/ | |__| | (_| | | | | (_| |
  \_____|\___|_| |_|_|\___|  \_____|\__,_|_| |_|\__, |
                                                 __/ |
                                                |___/                                           
                                               
/// @title Genie Gang Contract
/// @author Duro <[email protected]> (https://twitter.com/duronft)
**/

/// Contract ///
contract genieGang is ERC721A, Ownable {  
    using Strings for uint256;

    // Constants //
    uint256 constant MAX_SUPPLY = 777;
    uint256 public price = 0.03 ether;
    uint256 public holderPrice = 0.015 ether;
    uint256 public maxMint = 2;

    bool public saleActive;
    bool public presaleActive;
    bool public paused;

    string public _baseTokenURI = 'ipfs://bafybeibe7e2oojr3x5bz6e6ov7fj5gmmtvodaeqtkqr7vmbiub5pfgqucq/';

    mapping (address => uint256) public _userMintedPresale;
    mapping (address => uint256) public _userMintedPublic;
    bytes32 public merkleRoot;
    bytes32 public holderMerkleRoot;

    // Constructor //
    constructor( )
        ERC721A("Genie Gang", "GENIE") {                  
    }

    // Modifiers //
    modifier mintCompliance(uint256 quantity) {
        require(!paused, "Contract is paused");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough mints left");
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }

    // Minting Functions //
    function holderMint(uint256 quantity, bytes32[] calldata proof) external payable mintCompliance(quantity) {
        require(presaleActive, "Presale inactive");
        require(MerkleProof.verify(proof, holderMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address is not on holders List");
        require(holderPrice * quantity == msg.value, "Wrong amout of ETH sent");
        require(_userMintedPresale[msg.sender] + quantity == maxMint, "Can only mint 2 during presale");
        _safeMint(msg.sender, quantity);
        _userMintedPresale[msg.sender] += quantity;
    }

    function presaleMint(uint256 quantity, bytes32[] calldata proof) external payable mintCompliance(quantity) {
        require(presaleActive, "Presale inactive");
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address is not on Presale Allow List");
        require(_userMintedPresale[msg.sender] + quantity <= maxMint, "Can't mint more than 2 during presale");
        require(price * quantity == msg.value, "Wrong amout of ETH sent");
        _safeMint(msg.sender, quantity);
        _userMintedPresale[msg.sender] += quantity;
    }

    function publicMint(uint256 quantity) external payable mintCompliance(quantity)  {
        require(saleActive, "Public sale inactive");
        require(_userMintedPublic[msg.sender] + quantity <= maxMint, "Can't mint more than Max allowed");
        require(price * quantity == msg.value, "Wrong amout of ETH sent");
        _safeMint( msg.sender, quantity);
        _userMintedPublic[msg.sender] += quantity;
    } 

 	function devMint(address recipient, uint256 _genie) public onlyOwner {
        require(totalSupply() + _genie <= MAX_SUPPLY, "Not enough mints left");
        _safeMint(recipient, _genie);
    } 

    // Metadata //
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Setters //
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setHolderMerkleRoot(bytes32 _holderMerkleRoot) public onlyOwner {
		holderMerkleRoot = _holderMerkleRoot;
	}

	function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
		merkleRoot = _merkleRoot;
	}

    function setPresaleActive(bool val) external onlyOwner {
        presaleActive = val;
    }

    function setSaleActive(bool val) external onlyOwner {
        saleActive = val;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMaxMint(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    // Withdraw funds to the owner //
    function withdrawFunds() public payable onlyOwner {
	      (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		  require(success);
	}
}
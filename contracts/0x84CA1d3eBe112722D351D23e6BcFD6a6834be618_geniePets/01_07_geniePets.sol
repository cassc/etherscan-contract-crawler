// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
   _____            _         _____     _       
  / ____|          (_)       |  __ \   | |      
 | |  __  ___ _ __  _  ___   | |__) |__| |_ ___ 
 | | |_ |/ _ \ '_ \| |/ _ \  |  ___/ _ \ __/ __|
 | |__| |  __/ | | | |  __/  | |  |  __/ |_\__ \
  \_____|\___|_| |_|_|\___|  |_|   \___|\__|___/
                                               
                                               
/// @title Genie Pets Contract
/// @author Duro <[email protected]> (https://twitter.com/duronft)
**/

/// Contract ///
contract geniePets is ERC721A, Ownable {  
    using Strings for uint256;

    // Constants //
    uint256 constant MAX_SUPPLY = 150;
    uint256 public maxMint = 1;

    bool public saleActive;
    bool public presaleActive = true;
    bool public paused = true;

    string public _baseTokenURI = 'ipfs://bafybeic4yzgudiu5ybbdniqvxsbs7kwwxuo64yp2e4tf7frthrcojfpipm/';

    mapping (address => uint256) public _userMintedPresale;
    mapping (address => uint256) public _userMintedPublic;
    bytes32 public merkleRoot = 0x5c20c71ceec55f066fc45e5b415f9bf189940746fd3d3f80c40940ddf5956ce1;

    // Constructor //
    constructor( )
        ERC721A("Genie Pets", "GPETS") {                  
    }

    // Modifiers //
    modifier mintCompliance(uint256 quantity) {
        require(!paused, "Contract is paused");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough mints left");
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }

    // Minting Functions //
    function presaleMint(uint256 quantity, bytes32[] calldata proof) external mintCompliance(quantity) {
        require(presaleActive, "Presale inactive");
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address is not on Presale Allow List");
        require(_userMintedPresale[msg.sender] + quantity == 1, "Can't mint more than 1 during presale");
        _safeMint(msg.sender, quantity);
        _userMintedPresale[msg.sender] += quantity;
    }

    function publicMint(uint256 quantity) external mintCompliance(quantity)  {
        require(saleActive, "Public sale inactive");
        require(_userMintedPublic[msg.sender] + quantity <= maxMint, "Can't mint more than Max allowed");
        _safeMint( msg.sender, quantity);
        _userMintedPublic[msg.sender] += quantity;
    } 

 	function devMint(address recipient, uint256 _pets) public onlyOwner {
        require(totalSupply() + _pets <= MAX_SUPPLY, "Not enough mints left");
        _safeMint(recipient, _pets);
    } 

    // Metadata //
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Setters //
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
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

    // Withdraw funds if Eth should find its way to the contract //
    function withdrawFunds() public payable onlyOwner {
	      (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		  require(success);
	  }  
}
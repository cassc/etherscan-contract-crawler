//   Mutant Croco Golf Club 
/*
     ___           ___           ___           ___     
     /\  \         /\__\         /\__\         /\__\    
    |::\  \       /:/  /        /:/ _/_       /:/  /    
    |:|:\  \     /:/  /        /:/ /\  \     /:/  /     
  __|:|\:\  \   /:/  /  ___   /:/ /::\  \   /:/  /  ___ 
 /::::|_\:\__\ /:/__/  /\__\ /:/__\/\:\__\ /:/__/  /\__\
 \:\~~\  \/__/ \:\  \ /:/  / \:\  \ /:/  / \:\  \ /:/  /
  \:\  \        \:\  /:/  /   \:\  /:/  /   \:\  /:/  / 
   \:\  \        \:\/:/  /     \:\/:/  /     \:\/:/  /  
    \:\__\        \::/  /       \::/  /       \::/  /   
     \/__/         \/__/         \/__/         \/__/    

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MCGC is Ownable, ERC721AQueryable { 
    
    using Strings for uint256;

    // Storage
    uint256 public constant MAX_CROCOS = 4444;
    uint256 public constant MAX_PUBLIC_PER_WALLET = 5;

    bytes32 public merkleRoot;
    mapping(address => bool) public claimed;

    string private baseURI;
    bool public presale;
    bool public publicSale;

    uint private publicPrice = 22000000000000000; //0.022 ETH

    // Constructor
    constructor() ERC721A("Mutant Croco Golf Club", "MCGC") {
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1; 
    }

    function presaleMint(bytes32[] calldata merkleProof) public payable {
        require(presale, "WL NOT STARTED YET");
        require(claimed[msg.sender] == false, "WL SPOT USED");
        require(MerkleProof.verify(merkleProof, merkleRoot, toBytes32(msg.sender)) == true, "Invalid Merkle Proof");
        require (_totalMinted() + 1 <= MAX_CROCOS, "ALL NFT MINTED");

        claimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function publicMint(uint256 amount) public payable {
        require(publicSale, "PUBLIC SALE NOT ACTIVE");
        require (_totalMinted() + amount <= MAX_CROCOS, "TRY MINT LESS");
        require (amount <= MAX_PUBLIC_PER_WALLET, "MAX PER TX EXCEEDED");
        require (msg.value >= publicPrice*amount, "LOW ETH");

        _safeMint(msg.sender, amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPresaleState(bool state) public onlyOwner {
            presale = state;
    }

    function setPublicSaleState(bool state) public onlyOwner {
            publicSale = state;
    }

    function toBytes32(address addr) pure internal returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed");
    }
}
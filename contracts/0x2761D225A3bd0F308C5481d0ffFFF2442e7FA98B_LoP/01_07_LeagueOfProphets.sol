// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract LoP is ERC721A, Ownable {
    using Strings for uint;
    enum SaleStatus{ PAUSED, PUBLIC, WL }

    uint public constant COLLECTION_SIZE = 5555;
    string public baseURI = "ipfs://Qmab6koavopSZPkWLnBQ965ac6spRS8orK5uodHUbQ7vF7/"; 
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    uint256 public mintCap = 5;
    bytes32 public root;

    // price
    uint256 public price = 0.0066 ether;

    constructor() ERC721A("League of Prophets", "LOP") {} 
    
    // returns the base uri of the token metadata
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    /// @notice Update the merkle tree root
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }
    /// @notice Checks if user is whitelisted
    function verifyWhitelisted(bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, root, leaf);
    }
    // So the tokens start at 1 instead of 0
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    /// @notice Returns how many tokens a user has minted
    /// @param owner the address to check 
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
    /// @notice Mints NFTs, first is free
    /// @param proof The merkle proof required if you are whitelist minting
    /// @param quantity the amount to mint, must be less than 5, first is free per wallet 
    function mint(bytes32[] memory proof, uint256 quantity) external payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(saleStatus != SaleStatus.PAUSED, "Sale not open");
        require(quantity > 0, "Invalid quantity");
        require(quantity <= mintCap, "Max per call is 5");
        require(_numberMinted(msg.sender) + quantity <= mintCap, "Max per wallet is 5");
        require(totalSupply() + quantity <= COLLECTION_SIZE, "Supply exceeded");
        
        if (saleStatus == SaleStatus.WL) {
            require(verifyWhitelisted(proof), "Not whitelisted");
        }

        // Check how many the user has minted, and calculate cost, as first is free
        if(_numberMinted(msg.sender) > 0){
            require(msg.value >= price * quantity, "INVALID_ETH"); // Free mint is used
        }else{
            require(msg.value >= (price * quantity) - price, "INVALID_ETH"); // Deduct cost of 1 mint
        }

        _safeMint(msg.sender, quantity);
    }
    /// @notice Update current sale stage
    function setSaleStatus(SaleStatus status) external onlyOwner {
        saleStatus = status;
    }
    /// @notice Withdraw contract's balance
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No balance");
        payable(owner()).transfer(balance);
    }
    /// @notice Allows owner to mint tokens to a specified address
    function airdrop(address to, uint count) external onlyOwner {
        require(totalSupply() + count <= COLLECTION_SIZE, "Supply exceeded");
        _safeMint(to, count);
    }
    /// @notice Get token's URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "tokenId doesn't exist yet");

        string memory baseURI_mem = _baseURI();
        return bytes(baseURI_mem).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }
    /// @notice Sets the base URI for the tokens
    /// @param newURI the URI to set
    function setBaseURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }
}
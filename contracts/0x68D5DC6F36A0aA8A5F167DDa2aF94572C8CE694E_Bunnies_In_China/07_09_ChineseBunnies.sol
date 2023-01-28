//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Bunnies_In_China is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public baseURI;
    string public hiddenMetadataURI = "";

    bytes32 public merkleRoot;

    uint256 public mintPrice = 0 ether;
    uint256 public maxSupply = 2023;
    uint256 public maxMintPerWallet = 1;
    uint256 public teamAllocation = 50;

    bool public whitelist_MintEnabled = false;
    bool public public_MintEnabled = false;
    bool public revealed = false;

    mapping(address => bool) public whitelistClaimed;

    constructor() ERC721A("Bunnies In China", "BIC") {}

    modifier mintCompliance(uint256 _quantity) {
        require(_quantity >= 1, "Enter the correct quantity");
        require(_quantity + _numberMinted(msg.sender) <= maxMintPerWallet, "Mint limit exceeded");
        require(_quantity + totalSupply() <= (maxSupply - teamAllocation), "Sold Out!");
        _;
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "Invalid TokenId");
        string memory currentBaseURI = _baseURI();
        if(revealed == false) {
            return hiddenMetadataURI;
        } else {
            return bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
            : "";
        }
    }

    function _startTokenId() internal view virtual override returns(uint256) {
        return 1;
    }

    // Mint fuction for WL address 
    // Takes as input the merkle tree proof and the quantity of nft to be minted 
    function mint(uint256 _quantity, bytes32[] calldata proof) external payable mintCompliance(_quantity) {
        require(whitelist_MintEnabled, "Whitelist mint not live");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Not Whitelisted!");

        
        require(!(whitelistClaimed[msg.sender]), "Whitelist already claimed");
        whitelistClaimed[msg.sender] = true;

        _safeMint(msg.sender, _quantity);
    }

    // Mint function for addresses that are not whitelisted 
    // takes in as input only the quantity of nft to be minted 
    function publicMint(uint256 _quantity) external payable mintCompliance(_quantity) {
        require(public_MintEnabled, "Public mint not live");
        require(msg.value >= _quantity * mintPrice);
        _safeMint(msg.sender, _quantity);
    }

    function teamMint(uint256 _quantity) external payable onlyOwner{
        require(_quantity <= teamAllocation, "limit exceeded");
        _safeMint(msg.sender, _quantity);
    }

    function setWhitelistMintEnabled() external onlyOwner {
        whitelist_MintEnabled = !whitelist_MintEnabled;
    }

    function setPublicMintEnabled() external onlyOwner {
        public_MintEnabled = !public_MintEnabled;
    }

    function setReaveal() external onlyOwner {
        revealed = !revealed;
    }

    function setMaxMintPerWallet(uint256 _maxMintPerWallet) external onlyOwner {
        maxMintPerWallet = _maxMintPerWallet; 
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function setHiddenMetadataURI(string memory _hiddenMetadataURI) external onlyOwner {
        hiddenMetadataURI = _hiddenMetadataURI;
    }

    function withdrawETH() external onlyOwner nonReentrant {
        (bool sent, ) = payable(owner()).call{ value: address(this).balance }("");
        require(sent, "Failed Transaction");
    }

    receive() external payable {}
    fallback() external payable {}
}
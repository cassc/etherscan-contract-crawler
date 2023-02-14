// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Tiddles is ERC721A, Ownable{
    using Strings for uint256;
    string public baseURI;
    string public hiddenMetadataURI = "";

    uint256 public mintPrice = 0 ether;
    uint256 public maxSupply = 1414;
    uint256 public maxPerWallet = 1;
    uint256 public teamAllocation = 140;

    bool public revealed = false;

    bytes32 public merkleRoot;

    enum MintStatus {
        PAUSED,
        WHITELIST,
        PUBLIC
    }

    MintStatus public mintPhase = MintStatus.PAUSED;

    mapping(address => bool) public claimedWhitelist;

    constructor() ERC721A("Tiddles NFT", "Tiddles") {}

    modifier mintCompliance(uint256 _quantity) {
        require(_quantity >= 1, "Enter the correct quantity");
        require(_quantity + _numberMinted(msg.sender) <= maxPerWallet, "Mint limit exceeded");
        require(_quantity + totalSupply() <= (maxSupply - teamAllocation), "Sold Out!");
        _;
    }


    // MINT FUNCTIONS //

    function whitelistMint(uint256 _quantity, bytes32[] calldata proof) external payable mintCompliance(_quantity) {
        require(mintPhase == MintStatus.WHITELIST, "Whitelist mint not live");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Not Whitelisted!");

        
        require(!(claimedWhitelist[msg.sender]), "Whitelist already claimed");
        claimedWhitelist[msg.sender] = true;

        _safeMint(msg.sender, _quantity);
    }

    function publicMint(uint256 _quantity) external payable mintCompliance(_quantity) {
        require(mintPhase == MintStatus.PUBLIC, "Public mint not live");
        require(msg.value >= _quantity * mintPrice);
        _safeMint(msg.sender, _quantity);
    }

    function teamMint(uint256 _quantity) external payable onlyOwner{
        require(_quantity <= teamAllocation, "limit exceeded");
        _safeMint(msg.sender, _quantity);
    }


    // TOKEN URI

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


    // SET MINT-PHASE

    function enableWhitelistMint() external onlyOwner {
        mintPhase = MintStatus.WHITELIST;
    }

    function enablePublicMint() external onlyOwner {
        mintPhase = MintStatus.PUBLIC;
    }

    function pauseMint() external onlyOwner {
        mintPhase = MintStatus.PAUSED;
    }

    // SETTERS

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function setMaxMintPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet; 
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setHiddenMetadataURI(string memory _hiddenMetadataURI) external onlyOwner {
        hiddenMetadataURI = _hiddenMetadataURI;
    }

    function setReaveal() external onlyOwner {
        revealed = !revealed;
    }


    function withdrawETH() external onlyOwner {
        (bool sent, ) = payable(owner()).call{ value: address(this).balance }("");
        require(sent, "Failed Transaction");
    }

    receive() external payable {}
    fallback() external payable {}
}
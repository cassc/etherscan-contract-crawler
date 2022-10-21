// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ░█████╗░██████╗░░█████╗░██████╗░██╗░█████╗░███╗░░██╗
// ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██║██╔══██╗████╗░██║
// ███████║██████╔╝███████║██████╦╝██║███████║██╔██╗██║
// ██╔══██║██╔══██╗██╔══██║██╔══██╗██║██╔══██║██║╚████║
// ██║░░██║██║░░██║██║░░██║██████╦╝██║██║░░██║██║░╚███║
// ╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝

// ██████╗░███████╗███╗░░██╗░██████╗░██╗░░░██╗██╗███╗░░██╗░██████╗
// ██╔══██╗██╔════╝████╗░██║██╔════╝░██║░░░██║██║████╗░██║██╔════╝
// ██████╔╝█████╗░░██╔██╗██║██║░░██╗░██║░░░██║██║██╔██╗██║╚█████╗░
// ██╔═══╝░██╔══╝░░██║╚████║██║░░╚██╗██║░░░██║██║██║╚████║░╚═══██╗
// ██║░░░░░███████╗██║░╚███║╚██████╔╝╚██████╔╝██║██║░╚███║██████╔╝
// ╚═╝░░░░░╚══════╝╚═╝░░╚══╝░╚═════╝░░╚═════╝░╚═╝╚═╝░░╚══╝╚═════╝░
// powered by https://nalikes.com
contract ArabianPenguins is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(address => uint256) public addressMintedBalance;

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    string public hiddenMetadataUri;

    uint256 public cost = 0.03 ether;

    uint256 public finalMaxSupply = 2888;

    uint256 public maxMintAmountPerTx = 4;
    uint256 public nftPerAddressLimit = 4;

    uint256 public remainingTeamMints = 45;

    bool public publicMintEnabled = false;
    bool public allowlistMintEnabled = false;
    bool public paused = true;
    bool public revealed = false;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    //***************************************************************************
    // MODIFIERS
    //***************************************************************************

    /// @dev Ensure the user cannot mint more than the max amount per tx, as well as the current max supply.

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        // require(totalSupply() + _mintAmount <= finalMaxSupply, "Max supply exceeded!");
        require(totalSupply() + _mintAmount <= finalMaxSupply - remainingTeamMints, "Max supply exceeded!");
        _;
    }

    /// @dev Confirm that the user has sent the appropriate amount of ether.

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    /// @dev Users cannot mint if contract is paused
    modifier notPaused() {
        require(!paused, "The contract is paused!");
        _;
    }

    //***************************************************************************
    //  MINT FUNCTIONS
    //***************************************************************************
    
    function allowlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable notPaused mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount)
    {
        require(allowlistMintEnabled, "The allowlist is not enabled!");

        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

        addressMintedBalance[msg.sender]++;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable notPaused mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(publicMintEnabled, "Public sale is not active.");
        // require(totalSupply() + _mintAmount <= finalMaxSupply - remainingTeamMints, "Max supply exceeded!");
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public notPaused mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function mintToTeamMember(uint256 _mintAmount, address _receiver) public notPaused onlyOwner {
        require(totalSupply() + _mintAmount <= finalMaxSupply, "Max supply exceeded!");
        require(_mintAmount <= remainingTeamMints, "Exceeds reserved NFTs supply" );
        remainingTeamMints -= _mintAmount;
        _safeMint(_receiver, _mintAmount);
    }

    //***************************************************************************
    //  VIEW FUNCTIONS
    //***************************************************************************
    
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : "";    
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    //***************************************************************************
    //  CRUD FUNCTIONS
    //***************************************************************************

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmount) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmount;
    }

    function setFinalMaxSupply(uint256 _supply) public onlyOwner {
        require(_supply <= finalMaxSupply, "Invalid supply");
        finalMaxSupply = _supply;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function startAllowlistMint() public onlyOwner {
        if(paused) paused = false;
        if(publicMintEnabled) publicMintEnabled = false;
        
        allowlistMintEnabled = true;
        cost = 0.03 ether;
    }
    
    function startPublicMint() public onlyOwner {
        if(paused) paused = false;
        if(allowlistMintEnabled) allowlistMintEnabled = false;
        
        publicMintEnabled = true;
        cost = 0.04 ether;
    }

    function withdraw() public onlyOwner nonReentrant {

        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
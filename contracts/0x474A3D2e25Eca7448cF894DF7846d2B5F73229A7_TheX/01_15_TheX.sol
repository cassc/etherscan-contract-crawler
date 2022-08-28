// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ████████╗██╗░░██╗███████╗  ██╗░░██╗
// ╚══██╔══╝██║░░██║██╔════╝  ╚██╗██╔╝
// ░░░██║░░░███████║█████╗░░  ░╚███╔╝░
// ░░░██║░░░██╔══██║██╔══╝░░  ░██╔██╗░
// ░░░██║░░░██║░░██║███████╗  ██╔╝╚██╗
// ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝  ╚═╝░░╚═╝
// Powered by: https://nalikes.com

contract TheX is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    string public hiddenMetadataUri;
    string public LC_hiddenMetadataUri;

    uint256 public cost;

    uint256 public finalMaxSupply;
    uint256 public currentMaxSupply;

    uint256 public maxMintAmountPerTx;

    uint256 public remainingTeamMints = 95;

    bool public publicMintEnabled = false;
    bool public paused = true;
    bool public revealed = false;

    address public daoWallet;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _hiddenMetadataUri,
        string memory _LC_hiddenMetadataUri,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _currentMaxSupply,
        uint256 _maxMintAmountPerTx
    ) ERC721A(_tokenName, _tokenSymbol) {
        setCost(_cost);
        finalMaxSupply = _maxSupply;
        setCurrentMaxSupply(_currentMaxSupply);
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
        setLCHiddenMetadataUri(_LC_hiddenMetadataUri);
    }

    //***************************************************************************
    // MODIFIERS
    //***************************************************************************

    /// @dev Ensure the user cannot mint more than the max amount per tx, as well as the current max supply.

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(totalSupply() + _mintAmount <= currentMaxSupply, "Max supply exceeded!");
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

    function mint(uint256 _mintAmount) public payable notPaused mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(publicMintEnabled, "Public sale is not active.");
        require(totalSupply() + _mintAmount <= currentMaxSupply - remainingTeamMints, "Max supply exceeded!");
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public notPaused mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function mintToTeamMember(uint256 _mintAmount, address _receiver) public notPaused mintCompliance(_mintAmount) onlyOwner {
        require(_mintAmount <= remainingTeamMints, "Exceeds reserved NFTs supply" );
        remainingTeamMints -= _mintAmount;
        _safeMint(_receiver, _mintAmount);
    }

    //***************************************************************************
    //  VIEW FUNCTIONS
    //***************************************************************************

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (revealed == false) {
            if (_tokenId > 0 && _tokenId <= 10) {
                return LC_hiddenMetadataUri;
            }
            else {
                return hiddenMetadataUri;
            }
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

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmount) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmount;
    }

    function setCurrentMaxSupply(uint256 _supply) public onlyOwner {
        require(_supply <= finalMaxSupply && _supply >= currentMaxSupply, "Invalid supply");
        currentMaxSupply = _supply;
    }

    function setFinalMaxSupply() public onlyOwner {
        finalMaxSupply = currentMaxSupply;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setLCHiddenMetadataUri(string memory _LCHiddenMetadataUri) public onlyOwner {
        LC_hiddenMetadataUri = _LCHiddenMetadataUri;
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

    function setPublicMintEnabled(bool _state) public onlyOwner {
        publicMintEnabled = _state;
    }

    function setDaoWallet(address _daoWallet) public onlyOwner {
        require(daoWallet == 0x0000000000000000000000000000000000000000, "DAO wallet already set");
        daoWallet = payable(_daoWallet);
    }

    function withdraw() public onlyOwner nonReentrant {
        
        uint256 balance = address(this).balance;

        bool success;
        (success, ) = payable(0x44084dff2a31c34C7EA4CFceA80aC9A883c51F74).call{value: ((balance * 35) / 100)}("BlocqX");
        require(success, "BlocqX Transaction Unsuccessful");

        (success, ) = payable(0xcea28cD43406a8a83d140dD9A4ABF8A413735fEd).call{value: ((balance * 35) / 100)}("Mode");
        require(success, "Mode Transaction Unsuccessful");

        (success, ) = payable(0xc259D6a0623411033f2E69384556f7c0F49dFa37).call{value: ((balance * 10) / 100)}("LtDan");
        require(success, "Dan Transaction Unsuccessful");

        (success, ) = daoWallet.call{value: ((balance * 20) / 100)}("DAO");
        require(success, "DAO Transaction Unsuccessful");

        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
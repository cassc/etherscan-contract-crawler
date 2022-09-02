// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// ░░░░░██╗██╗░░░██╗██╗░█████╗░███████╗  ██╗░░░██╗██████╗░  ░█████╗░███╗░░██╗██████╗░
// ░░░░░██║██║░░░██║██║██╔══██╗██╔════╝  ██║░░░██║██╔══██╗  ██╔══██╗████╗░██║██╔══██╗
// ░░░░░██║██║░░░██║██║██║░░╚═╝█████╗░░  ██║░░░██║██████╔╝  ███████║██╔██╗██║██║░░██║
// ██╗░░██║██║░░░██║██║██║░░██╗██╔══╝░░  ██║░░░██║██╔═══╝░  ██╔══██║██║╚████║██║░░██║
// ╚█████╔╝╚██████╔╝██║╚█████╔╝███████╗  ╚██████╔╝██║░░░░░  ██║░░██║██║░╚███║██████╔╝
// ░╚════╝░░╚═════╝░╚═╝░╚════╝░╚══════╝  ░╚═════╝░╚═╝░░░░░  ╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

// ██╗░░░░░██╗███████╗████████╗  ██████╗░██████╗░░█████╗░██╗
// ██║░░░░░██║██╔════╝╚══██╔══╝  ██╔══██╗██╔══██╗██╔══██╗██║
// ██║░░░░░██║█████╗░░░░░██║░░░  ██████╦╝██████╔╝██║░░██║██║
// ██║░░░░░██║██╔══╝░░░░░██║░░░  ██╔══██╗██╔══██╗██║░░██║╚═╝
// ███████╗██║██║░░░░░░░░██║░░░  ██████╦╝██║░░██║╚█████╔╝██╗
// ╚══════╝╚═╝╚═╝░░░░░░░░╚═╝░░░  ╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝

contract NattyBros is ERC721A, Ownable {
    using Strings for uint256;

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    string public hiddenMetadataUri;

    uint256 public cost;

    uint256 public finalMaxSupply;
    uint256 public currentMaxSupply;

    uint256 public maxMintAmountPerTx;

    bool public publicMintEnabled = false;
    bool public paused = true;
    bool public revealed = false;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _hiddenMetadataUri,
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
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public notPaused mintCompliance(_mintAmount) onlyOwner {
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

    function withdraw() public onlyOwner{
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
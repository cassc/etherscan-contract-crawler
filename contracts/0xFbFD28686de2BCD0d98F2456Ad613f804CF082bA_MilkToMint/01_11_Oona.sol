// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "./Opensea/DefaultOperatorFilterer.sol";

// ███╗░░░███╗██╗██╗░░░░░██╗░░██╗  ████████╗░█████╗░  ███╗░░░███╗██╗███╗░░██╗████████╗
// ████╗░████║██║██║░░░░░██║░██╔╝  ╚══██╔══╝██╔══██╗  ████╗░████║██║████╗░██║╚══██╔══╝
// ██╔████╔██║██║██║░░░░░█████═╝░  ░░░██║░░░██║░░██║  ██╔████╔██║██║██╔██╗██║░░░██║░░░
// ██║╚██╔╝██║██║██║░░░░░██╔═██╗░  ░░░██║░░░██║░░██║  ██║╚██╔╝██║██║██║╚████║░░░██║░░░
// ██║░╚═╝░██║██║███████╗██║░╚██╗  ░░░██║░░░╚█████╔╝  ██║░╚═╝░██║██║██║░╚███║░░░██║░░░
// ╚═╝░░░░░╚═╝╚═╝╚══════╝╚═╝░░╚═╝  ░░░╚═╝░░░░╚════╝░  ╚═╝░░░░░╚═╝╚═╝╚═╝░░╚══╝░░░╚═╝░░░

contract MilkToMint is ERC721AQueryable, DefaultOperatorFilterer, Ownable {
    using Strings for uint256;

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    uint256 public cost = 0.1 ether;

    uint256 public maxMintAmountPerTx = 1;

    bool public paused = true;

    constructor(
        string memory _uri
    ) ERC721A("MILK TO MINT made by OONA", "OONAMM") {
        setUriPrefix(_uri);
    }

    //***************************************************************************
    // MODIFIERS
    //***************************************************************************

    modifier notPaused() {
        require(!paused, "The contract is paused!");
        _;
    }

    //***************************************************************************
    //  MINT FUNCTIONS
    //***************************************************************************

    function mint(uint256 _mintAmount) public payable notPaused {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintToAddress(address _receiver, uint256 _mintAmount) public onlyOwner {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        _safeMint(_receiver, _mintAmount);
    }

    //***************************************************************************
    //  VIEW FUNCTIONS
    //***************************************************************************
    
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function tokenURI(uint256 _tokenId) public view virtual override (ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : "";    
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //***************************************************************************
    //  CRUD FUNCTIONS
    //***************************************************************************

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmount) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmount;
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

    function withdraw() public onlyOwner {

        (bool success, ) = payable(0x4D1C149e6728314d0d6C4f7d48DbF83bD196444E).call{value: address(this).balance}("");
        require(success); 
    }
}
/*
      _____          _         _    _____ _     _ _     _ 
     |_   _|        | |       (_)  / ____| |   (_) |   (_)
       | |  ___  ___| | ____ _ _  | |    | |__  _| |__  _ 
       | | / __|/ _ \ |/ / _` | | | |    | '_ \| | '_ \| |
      _| |_\__ \  __/   < (_| | | | |____| | | | | |_) | |
     |_____|___/\___|_|\_\__,_|_|  \_____|_| |_|_|_.__/|_|
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract IsekaiChibi is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // Metadata URI and extension
    string public baseURI;
    string public baseExtension = ".json";
    
    uint256 public price= 0.001 ether;
    
    // Supply Constraint
    uint256 public maxSupply = 3333;
    
    // Minting Constraints
    uint256 public maxMintPerTxn = 3;
    uint256 public maxMintPerWallet = 20;

    // Contract State
    bool public isLive;

    constructor(
        string memory __baseURI,
        bool _isLive
    ) ERC721A("IsekaiChibi", "ISKCHBI") {
        baseURI = __baseURI;
        isLive = _isLive;
    }

    /*                 Modifiers                */

    modifier supplyConstraints(uint256 _mintAmount) {
        uint256 totalSupply = totalSupply(); 
        require(_mintAmount + totalSupply <= maxSupply, "Exceeds Max Supply");

        require(_numberMinted(_msgSender()) + _mintAmount <=  maxMintPerWallet, "Exceeds Max Mint Per Wallet");
        require( _mintAmount <=  maxMintPerTxn, "Exceeds Max Mint Per Txn");
        _;
    }

    modifier priceConstraint(uint256 _mintAmount) {
        require(msg.value == (price * _mintAmount), "Insufficient Ether");
        _;
    }

    /*                                       Mint Functions                                                      */

    function mint(uint256 _mintAmount) public payable supplyConstraints(_mintAmount) priceConstraint(_mintAmount) {
        require(isLive, "The contract is not live");
        _safeMint(_msgSender(), _mintAmount);
    }

    function devMint(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(_mintAmount <= maxSupply, "Exceeds Max Supply");
        _safeMint(_receiver, _mintAmount);
    }

    /*                          Token Functions                             */

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    /*                      Setters                       */

    function setBaseURI(string memory __baseURI) public onlyOwner {
        baseURI = __baseURI;
    }

    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxMintPerTxn(uint256 _maxMintPerTxn) public onlyOwner {
        maxMintPerTxn = _maxMintPerTxn;
    }

    function setMaxMintPerWallet(uint256 _maxMintPerWallet) public onlyOwner {
        maxMintPerWallet = _maxMintPerWallet;
    }

    function setIsLive(bool _state) public onlyOwner {
        isLive = _state;
    }

    /*                          Getters/Misc Functions                        */
   
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return (_numberMinted(owner));
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
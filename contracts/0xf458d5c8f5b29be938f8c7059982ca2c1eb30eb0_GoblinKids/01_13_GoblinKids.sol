// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
   _____       _     _ _         _  ___     _     
  / ____|     | |   | (_)       | |/ (_)   | |    
 | |  __  ___ | |__ | |_ _ __   | ' / _  __| |___ 
 | | |_ |/ _ \| '_ \| | | '_ \  |  < | |/ _` / __|
 | |__| | (_) | |_) | | | | | | | . \| | (_| \__ \
  \_____|\___/|_.__/|_|_|_| |_| |_|\_\_|\__,_|___/
  */

contract GoblinKids is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public maxSupply;
    uint256 public price;
    uint256 public maxFreeSupply;
    uint256 public maxFreePerWallet;
    uint256 public maxPerTx;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    bool public isFreeMintOpen = false;
    bool public paused = true;
    bool public revealed = false;

    mapping(address => uint256) private _mintedFreeAmount;

    constructor(
        uint256 _maxSupply,
        uint256 _price,
        uint256 _maxFreeSupply,
        uint256 _maxPerTx,
        string memory _hiddenMetadataUri
    ) ERC721A("GoblinKids", "GK") {
        maxSupply = _maxSupply;
        setPrice(_price);
        setMaxFreeSupply(_maxFreeSupply);
        setMaxPerTx(_maxPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxPerTx, "Invalid mint amount!");
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= price * _mintAmount, "Insufficient funds!");
        _;
    }

    function freeMint(uint256 _mintAmount) public mintCompliance(_mintAmount) {
        require(!paused && isFreeMintOpen, "GK: Free mint phase not open yet!");

        require(totalSupply() + _mintAmount <= maxFreeSupply, "GK: Exceeds max free mint supply!");
        require(_mintedFreeAmount[msg.sender] + _mintAmount <= maxFreePerWallet, "GK: Exceeds max free mint per wallet!");
        _mintedFreeAmount[msg.sender] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function publicMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(_numberMinted(msg.sender) + _mintAmount <= 100, "GK: Exceeds max mint per wallet!");
        require(!paused, "The contract is paused!");

        _safeMint(_msgSender(), _mintAmount);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

            if (!ownership.burned) {
                if (ownership.addr != address(0)) {
                    latestOwnerAddress = ownership.addr;
                }

                if (latestOwnerAddress == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;

                    ownedTokenIndex++;
                }
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function getMintedFreeTokenByWallet(address _addr) public view returns (uint256) {
        return _mintedFreeAmount[_addr];
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : "";
    }

    function setIsFreeMintOpen(bool _isFreeMintOpen) public onlyOwner {
        isFreeMintOpen = _isFreeMintOpen;
    }

    function cutMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply -= _maxSupply;
    }

    function setMaxFreePerWallet(uint256 _maxFreePerWallet) public onlyOwner {
        maxFreePerWallet = _maxFreePerWallet;
    }

    function setMaxFreeSupply(uint256 _maxFreeSupply) public onlyOwner {
        maxFreeSupply = _maxFreeSupply;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setMaxPerTx(uint256 _maxPerTx) public onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
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

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os, "Withdraw failed!");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
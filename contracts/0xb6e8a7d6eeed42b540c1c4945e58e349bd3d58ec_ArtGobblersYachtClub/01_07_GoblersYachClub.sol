// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract ArtGobblersYachtClub is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  mapping(address => bool) private _approvedMarketplaces;

  uint256 public cost = 0.0025 ether;
  uint256 public maxGoblers = 10000;
  uint256 public txnMax = 5;
  uint256 public maxFreeMintEach = 1;
  uint256 public maxMintAmount = 20;


  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;

  bool public revealed = true;
  bool public paused = true;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier checkGoo(uint256 _mintAmount) {
    require(!paused, "Goo sale has not started yet");
    require(_mintAmount > 0 && _mintAmount <= txnMax, "Maximum 10 Gobblers");
    require(totalSupply() + _mintAmount <= maxGoblers, "No gobblers lefts!");
        require(
      _mintAmount > 0 && numberMinted(msg.sender) + _mintAmount <= maxMintAmount,
       "You have minted max gobblers!"
    );
    _;
  }

  modifier checkGooPrice(uint256 _mintAmount) {
    uint256 realCost = 0;
    
    if (numberMinted(msg.sender) < maxFreeMintEach) {
      uint256 freeMintsLeft = maxFreeMintEach - numberMinted(msg.sender);
      realCost = cost * freeMintsLeft;
    }
   
    require(msg.value >= cost * _mintAmount - realCost, "Pay me corret value!");

    if (cost == 0) {
      require(tx.origin == msg.sender, "Not today");
    }
    _;
  }

  function SummonGOB(uint256 _mintAmount) public payable checkGoo(_mintAmount) checkGooPrice(_mintAmount) {
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxGoblers, "Max supply exceeded!");
    _safeMint(_receiver, _mintAmount);
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
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setmaxFreeMintEach(uint256 _maxFreeMintEach) public onlyOwner {
    maxFreeMintEach = _maxFreeMintEach;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
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


  function withdraw() public onlyOwner nonReentrant {
    (bool withdrawFunds, ) = payable(owner()).call{value: address(this).balance}("");
    require(withdrawFunds);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function approve(address to, uint256 tokenId) public virtual override {
    require(_approvedMarketplaces[to], "Invalid marketplace");
    super.approve(to, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(_approvedMarketplaces[operator], "Invalid marketplace");
    super.setApprovalForAll(operator, approved);
  }

  function setApprovedMarketplace(address market, bool approved) public onlyOwner {
    _approvedMarketplaces[market] = approved;
  }
}
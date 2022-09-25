// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "./ERC721AI.sol";

contract AIXenomorph is ERC721A, Ownable {
  using Strings for uint256;

  string private uriPrefix = "https://ai-xenomorph.sfo3.digitaloceanspaces.com/json/json/";
  string private uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public price = 0 ether; 
  uint256 public maxSupply = 394; 
  uint256 public maxMintAmountPerTx = 5; 
  uint256 public maxPerWallet = 5; 
  
  bool public paused = false;
  bool public revealed = true;
  
  mapping(address => uint256) public addressMintedBalance;


  constructor() ERC721A("AIXenomorph", "AIX", maxMintAmountPerTx) {
    setHiddenMetadataUri("");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(currentIndex + _mintAmount <= maxSupply, "Max supply exceeded! Please don't confirm transaction and refresh page!!");
    _;
  }

    function mint(uint256 _mintAmount) public payable {
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(!paused, "The contract is paused!");
    require(ownerMintedCount + _mintAmount <= maxPerWallet, "Max per wallet exceeded! Please don't confirm transaction and refresh page!!");
    require(msg.value >= price * _mintAmount, "Insufficient funds!");
    addressMintedBalance[msg.sender]+=_mintAmount;
    
    _safeMint(msg.sender, _mintAmount);
  }

  function AirdropTo(address _to, uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_to, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 0;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
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

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;

  }
 
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setmaxPerWallet(uint256 _limit) public onlyOwner {
    maxPerWallet = _limit;
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

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
      _safeMint(_receiver, _mintAmount);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
    }
    
    function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    
  }
  
}
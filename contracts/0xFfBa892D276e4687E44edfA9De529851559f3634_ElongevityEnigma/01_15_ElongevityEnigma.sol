// SPDX-License-Identifier: MIT
// Author: Nicholas Hickey, Dvorak

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ElongevityEnigma is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.01 ether;
  uint256 public WL = 2500;
  uint256 public currentSupply = 0;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmountPerTx = 2;


  bool public onlyWhitelisted = true;
  mapping(address => uint256) public addressMintedBalance;
  mapping(address => bool) public isWhitelisted;

  bool public paused = true;
  bool public revealed = false;
  bool public unlocked = false;

  constructor() ERC721("Elongevity Enigma", "ELONENIGMA") {
    setHiddenMetadataUri("ipfs://______/replace.json");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(supply.current() + _mintAmount <= WL || unlocked, "Reserved supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The mint has not been activated yet!");

    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(isWhitelisted[msg.sender], "user is not whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= maxMintAmountPerTx, "max NFT per address exceeded");
        }
        if (addressMintedBalance[msg.sender] + _mintAmount > 2 || supply.current() + _mintAmount > WL) {
	        require(msg.value >= cost * _mintAmount, "insufficient funds");
        }
    }

    _mintLoop(msg.sender, _mintAmount);

  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
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

  function setUnlocked(bool _state) public onlyOwner {
    unlocked = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
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

  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  function whitelistUser(address _user, bool _state) public onlyOwner {
    isWhitelisted[_user] = _state;
  }

  function whitelistUsers(address[] calldata _users, bool _state) public onlyOwner {
    for (uint i = 0; i < _users.length; i++) {
      isWhitelisted[_users[i]] = _state;
    }
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      currentSupply += 1;
      addressMintedBalance[msg.sender] += 1;
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
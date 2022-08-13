// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract InfernoFriends is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => uint256) public addressMintedBalance;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.04 ether;
  uint256 public ogPrice = 0.03 ether;
  uint256 public devilsPrice = 0.035 ether;
  uint256 public maxSupply = 1000;
  uint256 public maxMintAmountPerTx = 6;
  uint256 public nftPerAddressLimit = 6;
  uint256 public maxMintPerPresaleTx = 3;

  bool public paused = false;
  bool public isDropActive = true;
  bool public whitelistMintEnabled = true;
  bool public revealed = false;

  address[] public whitelistUsers;
  address[] public ogWhitelistUsers;
  address[] public devilsWhitelistUsers;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount) public payable {
    // Verify whitelist requirements
    uint256 supply = totalSupply();
    require(!paused, 'The contract is paused!');
    require(isDropActive, "The whitelist sale is not enabled!");
    require(!whitelistClaimed[_msgSender()], "Address already claimed!");
    require(_mintAmount > 0, "You need to mint at least 1 NFT");
    require(_mintAmount == 1, "You can not claim more than one free mint");
    require(supply + _mintAmount <= maxSupply, "Max NFT limit supply exceeded");
    require(isWhitelistedUser(_msgSender()), "You are not eligable for the whitelist");

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable {
    require(!paused, 'The contract is paused!');
    uint256 supply = totalSupply();
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(_mintAmount > 0, "You need to mint at least 1 NFT");
    require(_mintAmount <= maxMintAmountPerTx, "Max mint amount per session exceeded");
    require(ownerMintedCount + _mintAmount <= maxMintAmountPerTx, "Max mint per wallet amount exceeded");
    require(supply + _mintAmount <= maxSupply, "Max NFT limit supply exceeded");

    if (msg.sender != owner()) {
        if(whitelistMintEnabled == true) {
            require(isDevilsUser(_msgSender()) || isOgUser(_msgSender()), "User is not on the Devil's or OG allowlist.");
            require(ownerMintedCount + _mintAmount <= maxMintPerPresaleTx, "Max NFT per whitelist transaction exceeded");
        }
        require(msg.value >= determineMintCost() * _mintAmount, "Insufficient funds!");
    }
    
    for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[msg.sender]++;
    }

    _safeMint(_msgSender(), _mintAmount);
  }
  function isWhitelistedUser(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistUsers.length; i++) {
      if (whitelistUsers[i] == _user) {
          return true;
      }
    }
    return false;
  }

  function isOgUser(address _user) public view returns (bool) {
    for (uint i = 0; i < ogWhitelistUsers.length; i++) {
      if (ogWhitelistUsers[i] == _user) {
          return true;
      }
    }
    return false;
  }

  function isDevilsUser(address _user) public view returns (bool) {
    for (uint i = 0; i < devilsWhitelistUsers.length; i++) {
      if (devilsWhitelistUsers[i] == _user) {
          return true;
      }
    }
    return false;
  }

  function determineMintCost() internal view returns (uint256 _cost) {
      if (whitelistMintEnabled == true) {
        require(isOgUser(_msgSender()) || isDevilsUser(_msgSender()), "Country roads take me home, I don't know how I got here..");
        if (isOgUser(_msgSender())) {
            return ogPrice;
        }
        if (isDevilsUser(_msgSender())) {
            return devilsPrice;
        }
      }
      return cost;
  }

  function getCostPerTransaction(address _user) public view returns (uint256 _cost) {
    if (whitelistMintEnabled == false) {
      return cost;
    }
    if (isOgUser(_user)) {
      return ogPrice;
    }
    if (isDevilsUser(_user)) {
      return devilsPrice;
    }
    return cost;
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
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

  function resetUriPrefix() public onlyOwner {
    uriPrefix = "";
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setIsDropActive(bool _state) public onlyOwner {
    isDropActive = _state;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setOgWhitelistUsers(address[] calldata _users) public onlyOwner {
    delete ogWhitelistUsers;
    ogWhitelistUsers = _users;
  }

  function setDevilsWhitelistUsers(address[] calldata _users) public onlyOwner {
    delete devilsWhitelistUsers;
    devilsWhitelistUsers = _users;
  }

  function setWhitelistedUsers(address[] calldata _users) public onlyOwner {
    delete whitelistUsers;
    whitelistUsers = _users;
  }

  function withdraw() public onlyOwner {
    (bool js, ) = payable(0x4eebE6296f00C180aE7c2125B911DF4D11F6CA6a).call{value: address(this).balance * 7 / 100}("");
    require(js);

    (bool ad, ) = payable(0x18CC187f97A7ADFAcBb062E0cF994B8ebc477b97).call{value: address(this).balance * 10 / 100}("");
    require(ad);

    (bool success, ) = payable(owner()).call{value: address(this).balance}('');
    require(success);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
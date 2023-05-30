// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface INFT {
  function balanceOf(address owner) external view returns (uint256 balance);
}

contract Doodlz is ERC721A, Ownable {
  using Strings for uint256;

  uint256 public maxSupply = 3333;

  bool public paused = true;
  bool public revealed = false;

  string public baseURI;
  string public unrevealedURI;

  INFT public cryptoPolzContract;
  INFT public polzillaContract;
  INFT public eggzillaContract;
  INFT public kongzillaContract;

  constructor(
    address _cryptoPolzContractAddress,
    address _polzillaContractAddress,
    address _eggzillaContractAddress,
    address _kongzillaContractAddress
  ) ERC721A("Doodlz", "DOODLZ") {
    setUnrevealedURI("ipfs://QmcEcr8cBgXtWtD8EUsbm2TBv4yd5jBi5WWSVS8mpBsSZR");
    setCryptoPolzContract(_cryptoPolzContractAddress);
    setPolzillaContract(_polzillaContractAddress);
    setEggzillaContract(_eggzillaContractAddress);
    setKongzillaContract(_kongzillaContractAddress);
  }

  function reveal() public onlyOwner {
    revealed = true;
  }

  function flipPause() public onlyOwner {
    paused = !paused;
  }

  function setUnrevealedURI(string memory _unrevealedURI) public onlyOwner {
    unrevealedURI = _unrevealedURI;
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function setCryptoPolzContract(address _address) public onlyOwner {
    cryptoPolzContract = INFT(_address);
  }

  function setPolzillaContract(address _address) public onlyOwner {
    polzillaContract = INFT(_address);
  }

  function setEggzillaContract(address _address) public onlyOwner {
    eggzillaContract = INFT(_address);
  }

  function setKongzillaContract(address _address) public onlyOwner {
    kongzillaContract = INFT(_address);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
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

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require (_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return unrevealedURI;
    }

    return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
  }

  function bonusOf(
    address _user, 
    bool _hasCryptoPolz, 
    bool _hasPolzilla,
    bool _hasEggzilla,
    bool _hasKongzilla
  ) public view returns (uint256) {
    uint256 bonus = 0;

    if (_hasCryptoPolz) {
      bonus += cryptoPolzContract.balanceOf(_user);
    }

    if (_hasPolzilla) {
      bonus += polzillaContract.balanceOf(_user);
    }

    if (_hasEggzilla) {
      bonus += eggzillaContract.balanceOf(_user);
    }

    if (_hasKongzilla) {
      bonus += kongzillaContract.balanceOf(_user);
    }

    return bonus;
  }

  function mint() external {
    require (! paused, "Contract is paused");
    require (totalSupply() + 1 <= maxSupply, "Minted out");
    require (balanceOf(msg.sender) < 1, "Already claimed");
    
    _safeMint(msg.sender, 1);
  }

  function claim(
    uint256 _quantity,
    bool _hasCryptoPolz,
    bool _hasPolzilla,
    bool _hasEggzilla,
    bool _hasKongzilla
  ) external {
    require (! paused, "Contract is paused");
    require (_quantity > 0, "Wasting gas is not allowed");
    require (totalSupply() + _quantity <= maxSupply, "Minted out");
    require (
      balanceOf(msg.sender) + _quantity <= bonusOf(
        msg.sender,
        _hasCryptoPolz,
        _hasPolzilla,
        _hasEggzilla,
        _hasKongzilla
      ) + 1,
      "Claiming more than allowed"
    );

    _safeMint(msg.sender, _quantity);
  }
}
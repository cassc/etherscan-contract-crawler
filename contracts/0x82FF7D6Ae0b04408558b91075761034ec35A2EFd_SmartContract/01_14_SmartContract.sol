// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract SmartContract is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  uint256 public cost = 0.08 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 5;
  uint256 public maxNftPerAddress = 5;

  mapping(address => uint256) public numberOfMints;

  uint256 public reserveAmount = 30;
  uint256 public amountReserved = 0;
  bool public reserved = false;


  bool public paused = false;

  address private _signerAddress = 0x236F922715d6CA84D56232abd1df938331DA5634;
  address private _advisorAddress = 0x5F058DCcffB7862566aBe44F85d409823F5ce921;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function reserveSG() external onlyOwner {
    require(!reserved, "Reserved already");
    uint256 supply = totalSupply();
    require(supply + reserveAmount <= maxSupply, "Max Supply exceeded");
    for (uint256 i = 0; i < reserveAmount; i++) {
      _safeMint(msg.sender, supply + i);
      amountReserved++;
    }
    reserved = true;
  }

  function mint(uint256 _mintAmount, bytes memory _signature) external payable {
    require(!paused, "Minting is not active");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "At least one NFT needs to be minted");
    require(_mintAmount <= maxMintAmount, "Max mint amount exceeded");
    require(supply + _mintAmount + reserveAmount - amountReserved <= maxSupply, "Max Supply exceeded");
    require(numberOfMints[msg.sender] + _mintAmount <= maxNftPerAddress, "Max mint per wallet exceeded");
    require(verifySigner(msg.sender, _signature) == _signerAddress, "Direct mint is not allowed");
    if (msg.sender != owner()) {
      uint256 ownerTokenCount = balanceOf(msg.sender);
      require(ownerTokenCount <= maxNftPerAddress - _mintAmount, "Max NFT per address exceeded");
      require(msg.value >= cost * _mintAmount, "Insufficient funds");
    }

    for (uint256 i = 0; i < _mintAmount; i++) {
      numberOfMints[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }
  
  function verifySigner(address wallet, bytes memory _signature) public pure returns (address) {
    bytes32 _hash = keccak256(abi.encodePacked(wallet));
    bytes32 _prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    return ECDSA.recover(_prefixedHash, _signature);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function numberOfMintsCount(address addr) external view returns (uint256) {
    return numberOfMints[addr];
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
        : "";
  }

  function setMaxNftPerAddress(uint256 _limit) external onlyOwner() {
    maxNftPerAddress = _limit;
  }

  function setCost(uint256 _newCost) external onlyOwner() {
    cost = _newCost;
  }

  function setMaxMintAmount(uint256 _newmaxMintAmount) external onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause(bool _state) external onlyOwner {
    paused = _state;
  }

  function withdraw() external onlyOwner {
    payable(_advisorAddress).transfer(address(this).balance * 5 / 100);
    payable(msg.sender).transfer(address(this).balance);
  }

  function setSignerAddress(address addr) external onlyOwner {
    _signerAddress = addr;
  }

}
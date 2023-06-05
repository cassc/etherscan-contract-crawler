// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// @title:  RatGangNFT
// @url:    https://ratgangnft.com/

/*
  _____         _______ _____          _   _  _____ _   _ ______ _______ 
 |  __ \     /\|__   __/ ____|   /\   | \ | |/ ____| \ | |  ____|__   __|
 | |__) |   /  \  | | | |  __   /  \  |  \| | |  __|  \| | |__     | |   
 |  _  /   / /\ \ | | | | |_ | / /\ \ | . ` | | |_ | . ` |  __|    | |   
 | | \ \  / ____ \| | | |__| |/ ____ \| |\  | |__| | |\  | |       | |   
 |_|  \_\/_/    \_\_|  \_____/_/    \_\_| \_|\_____|_| \_|_|       |_|                                                                            
                                                                        
 */

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RatGangNFT is ERC721A, Ownable, IERC2981, ReentrancyGuard {
  using Address for address payable;

  // ====== Supply ======

  uint256 public publicMaxSupply = 2000;
  uint256 public maxSupply = 3333;
  uint256 public maxAmountPerWallet = 3;

  // ====== Price ======

  uint256 private price = 0.02 ether;

  // ====== Mint Status ======

  enum MintStatus {
    CLOSED,
    PRESALE,
    PUBLIC,
    FREEMINT
  }
  MintStatus public mintStatus = MintStatus.CLOSED;

  // ====== General ======

  string public baseTokenURI;
  uint256 private royaltyDivisor = 20;

  // ====== Mint Tracking ======

  bytes32 public presaleMerkleRoot;
  bytes32 public freemintMerkleRoot;
  mapping(address => uint256) public addressToPresaleMintCount;
  mapping(address => uint256) public addressToFreeMintCount;
  mapping(address => uint256) public addressToPublicMintCount;

  // ====== Withdraw Addresses ======

  address t1 = 0x73d6004E123EB60440AEf28A70E315777FC05279;

  // ====== Contract ======

  constructor(
    string memory _baseTokenURI,
    bytes32 _presaleMerkleRoot,
    bytes32 _freemintMerkleRoot,
    uint256 _publicMaxSupply,
    uint256 _maxSupply
  ) ERC721A("RatGangNFT", "RATS") {
    baseTokenURI = _baseTokenURI;
    presaleMerkleRoot = _presaleMerkleRoot;
    freemintMerkleRoot = _freemintMerkleRoot;
    publicMaxSupply = _publicMaxSupply;
    maxSupply = _maxSupply;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  // ====== Mint ======

  function mint(
    uint256 _amount,
    uint256 _maxAmount,
    bytes32[] calldata _proof
  ) public payable nonReentrant {
    require(msg.sender == tx.origin, "Caller not EOA");
    require(mintStatus != MintStatus.CLOSED, "Sale inactive");
    require(totalSupply() + _amount <= maxSupply, "Sold out!");

    if (mintStatus == MintStatus.PUBLIC) {
      _mintPublic(_amount);
    } else if (mintStatus == MintStatus.PRESALE) {
      _mintPresale(_amount, _maxAmount, _proof);
    } else if (mintStatus == MintStatus.FREEMINT) {
      _mintFreemint(_amount, _maxAmount, _proof);
    }
  }

  function _mintPublic(uint256 _amount) internal {
    require(msg.value >= price * _amount, "Amount of ETH sent is incorrect");
    require(totalSupply() + _amount <= publicMaxSupply, "Public Sold out!");
    require(
      addressToPublicMintCount[msg.sender] + _amount <= maxAmountPerWallet,
      "Amount must be less than or equal to wallet allowance"
    );
    addressToPublicMintCount[msg.sender] += _amount;
    _mintPrivate(msg.sender, _amount);
  }

  function _mintPresale(
    uint256 _amount,
    uint256 _maxAmount,
    bytes32[] calldata _proof
  ) internal {
    require(msg.value >= price * _amount, "Amount of ETH sent is incorrect");
    require(
      addressToPresaleMintCount[msg.sender] + _amount <= _maxAmount,
      "Amount must be less than or equal to whitelist allowance"
    );
    require(
      MerkleProof.verify(
        _proof,
        presaleMerkleRoot,
        keccak256(abi.encodePacked(msg.sender, _maxAmount, "presale"))
      ),
      "Proof is not valid"
    );

    addressToPresaleMintCount[msg.sender] += _amount;
    _mintPrivate(msg.sender, _amount);
  }

  function _mintFreemint(
    uint256 _amount,
    uint256 _maxAmount,
    bytes32[] calldata _proof
  ) internal {
    require(
      addressToFreeMintCount[msg.sender] + _amount <= _maxAmount,
      "Amount must be less than or equal to whitelist allowance"
    );
    require(
      MerkleProof.verify(
        _proof,
        freemintMerkleRoot,
        keccak256(abi.encodePacked(msg.sender, _maxAmount, "freemint"))
      ),
      "Proof is not valid"
    );

    addressToFreeMintCount[msg.sender] += _amount;
    _mintPrivate(msg.sender, _amount);
  }

  function mintTeam(address _to, uint256 _amount) external onlyOwner {
    _mintPrivate(_to, _amount);
  }

  function _mintPrivate(address _to, uint256 _amount) internal {
    _safeMint(_to, _amount);
  }

  // ====== Setters ======

  function setPublicMaxSupply(uint256 _publicMaxSupply) external onlyOwner {
    publicMaxSupply = _publicMaxSupply;
  }

  function setPrice(uint256 _newPrice) external onlyOwner {
    price = _newPrice;
  }

  function setBaseURI(string memory _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setPresaleMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    presaleMerkleRoot = _merkleRoot;
  }

  function setFreemintMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    freemintMerkleRoot = _merkleRoot;
  }

  function setMaxAmountPerWallet(uint256 _maxAmountPerWallet)
    external
    onlyOwner
  {
    maxAmountPerWallet = _maxAmountPerWallet;
  }

  function setRoyaltyDivisor(uint256 _divisor) external onlyOwner {
    royaltyDivisor = _divisor;
  }

  function setStatus(uint8 _status) external onlyOwner {
    mintStatus = MintStatus(_status);
  }

  function setPayoutWallet(address _to) external onlyOwner {
    t1 = _to;
  }

  // ====== Getters ======

  function checkPresaleMintMerkle(
    address _minter,
    uint256 _maxAmount,
    bytes32[] calldata _proof
  ) external view onlyOwner returns (bool) {
    return
      MerkleProof.verify(
        _proof,
        presaleMerkleRoot,
        keccak256(abi.encodePacked(_minter, _maxAmount, "presale"))
      );
  }

  function checkFreeMintMerkle(
    address _minter,
    uint256 _maxAmount,
    bytes32[] calldata _proof
  ) external view onlyOwner returns (bool) {
    return
      MerkleProof.verify(
        _proof,
        freemintMerkleRoot,
        keccak256(abi.encodePacked(_minter, _maxAmount, "freemint"))
      );
  }

  // ====== Withdraw ======

  function withdraw() public onlyOwner {
    require(address(this).balance != 0, "Balance is zero");

    payable(t1).sendValue(address(this).balance);
  }

  // ====== Misc ======

  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    require(_exists(tokenId), "Nonexistent token");

    return (address(this), salePrice / royaltyDivisor);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
}
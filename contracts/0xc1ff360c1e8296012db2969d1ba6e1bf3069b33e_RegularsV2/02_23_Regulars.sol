// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@amxx/hre/contracts/ENSReverseRegistration.sol";

import './ERC721DeckUpgradeable.sol';
import './ERC721NamedUpgradeable.sol';

import 'hardhat/console.sol';
import "@openzeppelin/contracts/utils/Strings.sol";

contract Regulars is
  OwnableUpgradeable,
  ERC721EnumerableUpgradeable,
  ERC721DeckUpgradeable,
  ERC721NamedUpgradeable
{
  string private _ipfsHash;
  string private _contractURI;
  address public beneficiary;
  bytes32 public currentSaleID;
  uint256 public currentSaleLimit;
  uint256 public currentSalePrice;
  mapping(bytes32 => mapping(address => uint256)) public minted;

  event Sale(bytes32 whitelistRoot, uint256 amount, uint256 price);

  modifier onlyRemaining(uint256 count) {
    require (remaining() >= count, 'Not enough tokens remaining');
    _;
  }

  modifier withPayment(uint256 price) {
    require(msg.value >= price, 'Insufficient payment');
    _;
    AddressUpgradeable.sendValue(payable(beneficiary), msg.value);
  }

  modifier onlyWhitelisted(bytes32 leave, bytes32[] memory proof) {
    require(currentSaleID == bytes32(0) || MerkleProofUpgradeable.verify(proof, currentSaleID, leave), 'Whitelist proof is not valid');
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer
  {}

  function initialize(string memory __name, string memory __symbol, uint256 __length, string memory __ipfsHash)
  public
    initializer()
  {
    __Ownable_init();
    __ERC721_init(__name, __symbol);
    __ERC721Enumerable_init();
    __ERC721Deck_init(__length);

    _ipfsHash = __ipfsHash;
    beneficiary = _msgSender();
    currentSaleID = bytes32(bytes2(0xdead)); // locked
  }

  /**
   * Lazy-minting
   */
  function mintGift(uint256 numberOfTokens, address recipient)
  external
    onlyRemaining(numberOfTokens)
    onlyOwner()
  {
    _mintBatch(recipient, numberOfTokens);
  }

  function mint(uint256 numberOfTokens, uint256 quota, bytes32[] calldata proof)
  external payable
    withPayment(numberOfTokens * currentSalePrice)
    onlyRemaining(numberOfTokens + currentSaleLimit)
    onlyWhitelisted(keccak256(abi.encodePacked(_msgSender(), quota)), proof)
  {
    if (quota > 0) {
      minted[currentSaleID][_msgSender()] += numberOfTokens;
      require(minted[currentSaleID][_msgSender()] <= quota, 'Whitelist quota reached');
    }

    _mintBatch(_msgSender(), numberOfTokens);
  }

  function _mintBatch(address to, uint256 count)
  internal
  {
    for (uint256 i = 0; i < count; ++i) {
      _mint(to);
    }
  }

  /**
   * Admin operations: ens reverse registration / pause / unpause / withdraw
   */
  function startSale(bytes32 whitelistRoot, uint256 amount, uint256 price)
  external
    onlyOwner()
  {
    currentSaleID    = whitelistRoot;
    currentSaleLimit = remaining() > amount ? remaining() - amount : 0;
    currentSalePrice = price;
    emit Sale(whitelistRoot, amount, price);
  }

  function setName(address ensRegistry, string calldata ensName)
  external
    onlyOwner()
  {
    ENSReverseRegistration.setName(ensRegistry, ensName);
  }

  function setBeneficiary(address newBeneficiary)
  external
    onlyOwner()
  {
    beneficiary = newBeneficiary;
  }

  function setContractURI(string calldata newURI)
  external
    onlyOwner()
  {
    _contractURI = newURI;
  }

  /**
   * View functions
   */
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  /**
   * Override merge
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }
  function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721DeckUpgradeable) {
    super._burn(tokenId);
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return string(bytes.concat("ipfs://", bytes(_ipfsHash), "/"));
  }
}
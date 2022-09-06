//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~(JJJJJJJJJJJJ,~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
//~~~~~~~~~~~[email protected]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~?MMMMMMMMMMMM8~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~(MMMM$~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~_JJJJJJ,~~~~~~(MMMM$~~~~~~(JJJJJJJJ-~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~(MMMMMM#~~~~~~(MMMM$~~~~~(MMMMMMMMMMe~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
//~~~~~~~~~~~~~~.~~~~.~~~~.~~~~.~~~~.~~~~.~~~~.~~~~~~(MMMMMMN~~~~~~(MMMM$~~~~dMMMMMMMMMMMMb~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~JMMMMMMM>~~~~~(MMMM$~~~~MMMMM=~~?MMMM#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
//~~~~~~~~(JJJJ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~dMMMMMMMr~~~~~(MMMM$~~~~MMMM#~~~~MMMM#~~~~~~.~~~~.~~~~.~~~~.~~~~.~~_JJJJJJJ~~~~.~~//
//~~~~~~~~JMMMM~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~MMMMJMMMF~~~~~(MMMM$~~~~MMMM#~__~MMMM#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~(MMMMMMN~~~~~~~//
//~~~~~~~~JMMMM~~~~~~~~~~~~~~~~~~~(+++++++++J,~~~~~~(MMM#JMMM#~~~~~(MMMM$~~~~MMMM#~_ ~MMMM#~~_JJJJJJJJJJJ~~~~~~~~~~~~~~~(MMMMMMM<~~~~~~//
//~~~~~~~~JMMMM~~~~~~~~~~~~~~~~~~~dMMMMMMMMMMMm,~~~~(MMM#(MMMN~~~~~(MMMM$~___MMMM#~` ~MMMM#_`.MMMMMMMMMMMNJ~~~~~~~~~~~~~JMMMMMMMr~~~~~~//
//~~~~~~~~JMMMM~~(JJJJ/~~~(JJJJ_~~dMMMM"""WMMMM#~~~~(MMMF_MMMM<~~~~(MMMM$~~~.?MMM#~  ~MMMH=.~_MMMM#""TMMMMM>~~(JJJJ~~~~~MMMMJMMMb~~~~~~//
//~~~~~~~~JMMMM~~(MMMM$~~~JMMMM~~~dMMMN~~~~MMMM#~~~~dMMMF~MMMMr~~~~(MMMM$~~~~Q,.T#~  [email protected]'[email protected]~~~JMMMM>~~dMMM#~~~~(MMM#(MMM#~~~~~~//
//~~~~~~~~JMMMM~~(MMMM$~~~JMMMM~~~dMMMN~~~~MMMM#~~~~MMMM%~dMMMb~~~~(MMMM$~~~~MMp  `  `  .M#[email protected]~~~JMMMM>~~dMMM#~~~~(MMM#(MMMM-~~~~~//
//~~~~~~~~JMMMM~~(MMMM$~~~JMMMM~~~dMMMN~~~~MMMM#~~~_MMMM<~JMMM#~~~~(MMMM$~___T"""      T""[email protected]~~~JMMMM>~~dMMM#~~~~JMMMF~MMMMr~~~~~//
//~~~~~~~~JMMMM~~(MMMM$~~~JMMMM~~~dMMMN~~~~MMMM#~~~(MMMN~~JMMMN~~~~(MMMN[-.......      ...,...gNNMb~~~JMMMM>~~dMMM#~~~~dMMM$~dMMMb~~~~~//
//~~~~~~~~JMMMM~~(MMMM$~~~JMMMM~~~dMMMN+++gMMMM#~~~(MMM#~~(MMMM<~~~(MMMM$~~~~MM#!      .WM#[email protected]~~~JMMMM>~~dMMM#~~~_MMMMl~JMMM#~~~~~//
//~~~~~~~~JMMMM~~([email protected]<[email protected]~~(MMMMr~~~(MMMM$~~~~M3 .K_  ~Q, ?#[email protected]~~~JMMMM>~~dMMM#~~~(MMMM~~JMMMN_~~~~//
//~~~~~~~~JMMMM~~(MMMM$~~~JMMMM~~~dMMMMTTMMMMr~~~~~dMMMMMMMMMMMF~~~(MMMM$~~~`.(MM#~  ~MMMa.`[email protected]>~~dMMM#~~~(MMM#~~(MMMMl~~~~//
//~~~~~~~~JMMMM~~([email protected]~~~(MMMM$~__.MMMM#~. ~MMMM#[email protected]~~~dMMM#~~~dMMM#__(MMMMF~~~~//
//~~~~~~~~JMMMM~~(MMMM$~~~JMMMM~~~dMMMN~~JMMMN_~~~(MMMMB"""HMMMN~~~(MMMM$~_~~MMMM#~_ ~MMMM#~~_MMMMMMMMMMB<~~~~dMMM#~~~MMMMMMMMMMMMN~~~~//
//~~~~~~~~JMMMM~~(MMMM$~~~JMMMM~~~dMMMN~~(MMMMr~~~(MMMM<~~~JMMMM-~~(MMMM$~~~~MMMM#~_.~MMMM#[email protected]~~~~~~~~~~~dMMM#~~(MMMMMMMMMMMMN~~~~//
//~~~~~~~~JMMMM~~(MMMM$~~~JMMMM~~~dMMMN~~~MMMMN~~~JMMMN~~~~JMMMMr~~(MMMM$~~~~MMMM#~_~~MMMM#[email protected]~~~~~~~~~~~dMMM#~~(MMMM>~~~JMMMM;~~~//
//~~~~~~~~JMMMM~~(MMMM$~~~JMMMM~~~dMMMN~~~JMMMM-~~dMMM#~~~~(MMMMF~~(MMMM$~~~~MMMMN,~~(MMMM#[email protected]~~~~~~~~~~~dMMM#~~jMMMM~~~~(MMMM]~~~//
//~~~(ggggMMMMM~~(MMMMMNggMMMMM~~~dMMMN~~~([email protected]~~~~([email protected]~~([email protected][email protected]~~~~~~~~~~~dMMM#~~dMMM#~~~~(MMMMb~~~//
//~~~(MMMMMMM#>~~~?MMMMMMMMMM#>~~~dMMMN~~~~dMMM#~(MMMMF~~~~~MMMMN~~([email protected]~~~~~~~~~~~dMMM#~(MMMMF~~~~~MMMMN~~~//
//~~~(777777>~~~~~~~?7777777=~~~~~?777=~~~~(7777~(7777:~~~~~?7777~~(7777:~~~~~~(77777777<~~~~~7777=~~~~~~~~~~~?777=~(7777>~~~~~?7777~~~//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract Juratopia is ERC721, IERC2981, Pausable, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  uint256 public constant MAX_SUPPLY = 5000;
  uint256 public constant MAX_PERMINT = 5;
  string public constant COLLECTION_NAME = "JURATOPIA";
  string public constant COLLECTION_SYMBOL = "JTP";
  uint256 public constant WL_LISTING_PRICE = 0.02 ether;
  uint256 public constant PUBLIC_LISTING_PRICE = 0.04 ether;
  uint256 public constant ROYALTY = 500; // 5%
  uint256 public periodMaxSupply = 100;

  bytes32 public merkleRoot;
  address payable private withdrawWallet = payable(0xC4834772D5D48d09Dd214C5C0F9eeeb5352380F3);
  address payable private royaltyWallet = payable(0x4774648628a0629AF9522B47b05073aFB68332b7);
  string private baseTokenURI = "ipfs://Qma9XYwEbEnTxXcTuh6MXpC1R3APEUsAxX9sGfrnKj258v/";
  bool private isWhitelistSale = false;
  bool private isPublicSale = false;

  mapping(address => bool) public whitelistClaimed;

  constructor(bytes32 _merkleRoot) ERC721(COLLECTION_NAME, COLLECTION_SYMBOL) {
    merkleRoot = _merkleRoot;
  }

  modifier isEnoughNFTs(uint256 _count) {
    uint256 totalMinted = _tokenIds.current();
    require(totalMinted.add(_count) <= MAX_SUPPLY && totalMinted.add(_count) <= periodMaxSupply, "Not enough NFTs!");
    _;
  }

  modifier isEnoughCount(uint256 _count) {
    require(_count > 0 && _count <= MAX_PERMINT, "Cannot mint specified number of NFTs.");
    _;
  }

  modifier isWhitelisted(address _address) {
    require(!whitelistClaimed[_address], "You need to be whitelisted");
    _;
  }

  modifier checkWhiteListSale {
    require(isWhitelistSale, 'Sorry. Not yet on sale.');
    _;
  }

  modifier checkPublicSale {
    require(isPublicSale, 'Sorry. Not yet on sale.');
    _;
  }

  modifier isAmountSufficient(uint256 _amount, uint256 _count, uint256 _mintPrice) {
    require(_amount >= _mintPrice.mul(_count), 'Please submit the asking price in order to continue');
    _;
  }

  modifier existsWhiteList(address _addr, bytes32[] calldata _merkleProof) {
    require(_verify(_addr, _merkleProof), "Sorry, you are not on the whitelist.");
    _;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function totalSupply() external view returns (uint256) {
    return _tokenIds.current();
  }

  function setBaseURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setPeriodMaxSupply(uint256 _value) external onlyOwner {
    periodMaxSupply = _value;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function startWhitelistSale() external onlyOwner {
    isWhitelistSale = true;
    isPublicSale = false;
  }

  function startPublicSale() external onlyOwner {
    isWhitelistSale = false;
    isPublicSale = true;
  }

  function finishSale() external onlyOwner {
    isWhitelistSale = false;
    isPublicSale = false;
  }

  function getWlSaleStatus() external view returns(bool) {
    return isWhitelistSale;
  }

  function getPublicSaleStatus() external view returns(bool) {
    return isPublicSale;
  }

  function ownerMint(uint256 _count) external whenNotPaused() onlyOwner isEnoughNFTs(_count) returns(uint256) {
    _mintNFT(msg.sender, _count);

    return _tokenIds.current();
  }

  function whitelistMint(uint256 _count, bytes32[] calldata _merkleProof) external payable nonReentrant whenNotPaused() isWhitelisted(msg.sender) checkWhiteListSale existsWhiteList(msg.sender, _merkleProof) isEnoughNFTs(_count) isEnoughCount(_count) isAmountSufficient(msg.value, _count, WL_LISTING_PRICE) returns(uint256) {
    require(WL_LISTING_PRICE != 0 ether, 'Sorry. No price has been set yet.');

    _mintNFT(msg.sender, _count);

    whitelistClaimed[msg.sender] = true;

    return _tokenIds.current();
  }

  function _getLeaf(address addr) private pure returns(bytes32)  {
    return keccak256(abi.encodePacked(addr));
  }

  function _verify(address _addr, bytes32[] calldata _merkleProof) private view returns(bool) {
    bytes32 leaf = _getLeaf(_addr);
    return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
  }

  function publicUserMint(uint256 _count) external payable nonReentrant whenNotPaused() checkPublicSale  isEnoughNFTs(_count) isEnoughCount(_count) isAmountSufficient(msg.value, _count, PUBLIC_LISTING_PRICE) returns(uint256) {
    require(PUBLIC_LISTING_PRICE != 0 ether, 'Sorry. No price has been set yet.');
    _mintNFT(msg.sender, _count);

    return _tokenIds.current();
  }

  function _mintNFT(address _receiver, uint256 _count) private {
    for(uint256 i = 1; i <= _count; i++) {
      _safeMint(_receiver, _tokenIds.current());
      _tokenIds.increment();
    }
  }

  function setWithdrawalWallet(address payable _withdrawWallet) external onlyOwner {
    withdrawWallet = _withdrawWallet;
  }

  function setRoyaltyWallet(address payable _royaltyWallet) external onlyOwner {
    royaltyWallet = _royaltyWallet;
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
    require(_exists(tokenId), "Token does not exist");
    return (payable(royaltyWallet), uint((salePrice * ROYALTY) / 10000));
  }

  function withdraw() external payable onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No ether left to withdraw");

    (bool success,) = payable(withdrawWallet).call{value: balance}("");

    require(success, "Transfer failed.");
  }
}
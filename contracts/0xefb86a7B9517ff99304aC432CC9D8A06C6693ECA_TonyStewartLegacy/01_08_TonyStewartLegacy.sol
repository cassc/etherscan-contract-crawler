/*
╭━━━╮╱╱╱╱╱╱╱╱╱╱╱╱╱╱╭━━━╮╱╱╱╱╱╱╱╱╭╮
┃╭━╮┃╱╱╱╱╱╱╱╱╱╱╱╱╱╱┃╭━╮┃╱╱╱╱╱╱╱╭╯╰╮
┃┃╱┃┣━┳━━┳━╮╭━━┳━━╮┃┃╱╰╋━━┳╮╭┳━┻╮╭╯
┃┃╱┃┃╭┫╭╮┃╭╮┫╭╮┃┃━┫┃┃╱╭┫╭╮┃╰╯┃┃━┫┃
┃╰━╯┃┃┃╭╮┃┃┃┃╰╯┃┃━┫┃╰━╯┃╰╯┃┃┃┃┃━┫╰╮
╰━━━┻╯╰╯╰┻╯╰┻━╮┣━━╯╰━━━┻━━┻┻┻┻━━┻━╯
╱╱╱╱╱╱╱╱╱╱╱╱╭━╯┃
╱╱╱╱╱╱╱╱╱╱╱╱╰━━╯
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract TonyStewartLegacy is ERC721A, IERC2981, Ownable, ReentrancyGuard {
  string public PROVENANCE_HASH;
  string public SEED_PHRASE_HASH;
  uint256 public MAX_MINT_BATCH = 10;

  string constant TOKEN_SYMBOL = "TONY-STEWART-LEGACY-500";
  string constant TOKEN_NAME = "Tony Stewart Legacy 500";
  uint256 constant ROYALTY_PCT = 10;
  uint256 constant MAX_SUPPLY = 500;

  string public baseURI;
  string public termsURI;
  string private _contractURI;

  uint256 public price = 0.16 ether;

  mapping(address => uint256) private _alreadyMinted;

  address public beneficiary;
  address public royalties;

  struct SaleConfig {
    bool isPublicActive;
    uint32 endTime;
    uint32 startTime;
  }

  struct MsgConfig {
    string BAD_AMOUNT;
    string MAX_MINT_BATCH;
    string MAX_SUPPLY;
    string QUANTITY;
  }

  struct MintEntity {
    address to;
    uint256 quantity;
  }

  SaleConfig public saleConfig;
  MsgConfig private msgConfig;

  constructor(
    address _royalties,
    string memory _initialBaseURI,
    string memory _initialContractURI
  ) ERC721A(TOKEN_NAME, TOKEN_SYMBOL) {
    royalties = _royalties;
    beneficiary = royalties;
    baseURI = _initialBaseURI;
    _contractURI = _initialContractURI;
    termsURI = "ipfs://QmTVp9aDwZYG9mFoxvL2SZ9wJUSNiUjz5haSSsqTtdJX5q";

    msgConfig = MsgConfig(
      "Incorrect amount paid",
      "Max minting batch will be exceeded",
      "Max supply will be exceeded",
      "Insufficient quantity left to mint"
    );

    saleConfig.isPublicActive = false;
    // Sale starts at Tue Aug 23 2022 12:00:00 GMT-0400 (Eastern Daylight Time)
    saleConfig.startTime = 1661270400;
    // Sale ends at Thu Aug 25 2022 12:00:00 GMT-0400 (Eastern Daylight Time)
    saleConfig.endTime = 1661443200;
  }

  function setProvenanceHash(string calldata hash) public onlyOwner {
    PROVENANCE_HASH = hash;
  }

  function setSeedPhraseHash(string calldata hash) public onlyOwner {
    SEED_PHRASE_HASH = hash;
  }

  function setBeneficiary(address _beneficiary) public onlyOwner {
    beneficiary = _beneficiary;
  }

  function setRoyalties(address _royalties) public onlyOwner {
    royalties = _royalties;
  }

  /**
   * Sets the public sale's active status.
   */
  function setPublicSaleActive(bool _isPublicSaleActive) public onlyOwner {
    saleConfig.isPublicActive = _isPublicSaleActive;
  }

  function setSaleEndTime(uint32 time) external onlyOwner {
    saleConfig.endTime = time;
  }

  function setSaleStartTime(uint32 time) external onlyOwner {
    saleConfig.startTime = time;
  }

  /**
   * Check if public sale is active
   */
  function isPublicActive() public view returns (bool) {
    return
      (saleConfig.startTime > 0 &&
        block.timestamp >= saleConfig.startTime &&
        block.timestamp <= saleConfig.endTime) || saleConfig.isPublicActive;
  }

  /**
   * Get start time of sale
   */
  function getStartTime() public view returns (uint256) {
    return saleConfig.startTime;
  }

  /**
   * Get end time of sale
   */
  function getEndTime() public view returns (uint256) {
    return saleConfig.endTime;
  }

  /**
   * Sets the Base URI for the token API
   */
  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }

  /**
   * Gets the Base URI of the token API
   */
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /**
   * OpenSea contract level metdata standard for displaying on storefront.
   * https://docs.opensea.io/docs/contract-level-metadata
   */
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory uri) public onlyOwner {
    _contractURI = uri;
  }

  function setTermsURI(string memory uri) public onlyOwner {
    termsURI = uri;
  }

  /*
   * Override start token to 1
   */
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /**
   * Mint next available token(s) to addres using ERC721A _safeMint
   */
  function _internalMint(address to, uint256 quantity) private {
    require(totalSupply() + quantity <= MAX_SUPPLY, msgConfig.MAX_SUPPLY);

    _safeMint(to, quantity);
  }

  /**
   * Mint to all addresses
   */
  function mint(uint256 quantity, uint256 maxQuantity)
    public
    payable
    nonReentrant
  {
    maxQuantity; // silence solc unused parameter warning
    address sender = _msgSender();
    require(isPublicActive(), "Public sale is not active");
    require(quantity <= MAX_MINT_BATCH, msgConfig.MAX_MINT_BATCH);
    require(msg.value == price * quantity, msgConfig.BAD_AMOUNT);

    _alreadyMinted[sender] += quantity;
    _internalMint(sender, quantity);
  }

  /**
   * Owner can mint to specified address
   */
  function ownerMint(address to, uint256 quantity) public onlyOwner {
    _internalMint(to, quantity);
  }

  /**
   * Return total quantity from an array of mint entities
   */
  function _totalQuantity(MintEntity[] memory entities)
    private
    pure
    returns (uint256)
  {
    uint256 totalQuantity = 0;

    for (uint256 i = 0; i < entities.length; i++) {
      totalQuantity += entities[i].quantity;
    }

    return totalQuantity;
  }

  /**
   * Bulk mint to address list with quantity
   */
  function _bulkMintQuantity(MintEntity[] memory entities) private {
    uint256 quantity = _totalQuantity(entities);
    require(totalSupply() + quantity <= MAX_SUPPLY, msgConfig.MAX_SUPPLY);

    for (uint256 i = 0; i < entities.length; i++) {
      _internalMint(entities[i].to, entities[i].quantity);
    }
  }

  /**
   * Awesome Drop multiple addresses with number to mint for each
   */
  function airDrop(MintEntity[] memory entities) public onlyOwner {
    _bulkMintQuantity(entities);
  }

  function withdraw() public onlyOwner {
    require(
      beneficiary != address(0),
      "beneficiary needs to be set to perform this function"
    );
    payable(beneficiary).transfer(address(this).balance);
  }

  /**
   * Supporting ERC721, IER165
   * https://eips.ethereum.org/EIPS/eip-165
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * Setting up royalty standard: IERC2981
   * https://eips.ethereum.org/EIPS/eip-2981
   */
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address, uint256 royaltyAmount)
  {
    _tokenId; // silence solc unused parameter warning
    royaltyAmount = (_salePrice / 100) * ROYALTY_PCT;
    return (royalties, royaltyAmount);
  }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./SanFranTokyoGenesisPassOperatorFilterer.sol";

// custom errors
error ReachedMaxTotalSupply();
error ReachedMaxTreasurySupply();
error InvalidMinter(address minter);

contract SanFranTokyoGenesisPass is
  ERC721A,
  ERC2981,
  Ownable,
  SanFranTokyoGenesisPassOperatorFilterer
{
  // metadata URI
  string private _baseTokenURI;

  // permitted cashier minters
  mapping(address => bool) public minters;

  uint256 private constant COLLECTION_SIZE = 2000;
  uint256 public treasuryMintedCount = 0;
  uint256 private constant MAX_TREASURY_MINT_LIMIT = 100;

  constructor(
    string memory name,
    string memory symbol,
    address defaultFiltererSubscription
  ) ERC721A(name, symbol) {
    registerForOperatorFiltering(defaultFiltererSubscription, true);
  }

  event TreasuryMint(
    address indexed recipient,
    uint256 quantity,
    uint256 fromIndex
  );

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function getBaseURI() external view returns (string memory) {
    return _baseTokenURI;
  }

  function addMinter(address minterAddress) external onlyOwner {
    minters[minterAddress] = true;
  }

  function removeMinter(address minterAddress) external onlyOwner {
    delete minters[minterAddress];
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function totalMinted() public view returns (uint256) {
    return _totalMinted();
  }

  /**
   * @dev Dev mint from treasury, token will be minted to the msg.sender
   */
  function treasuryMint(uint256 quantity) external onlyOwner {
    _treasuryMint(quantity, msg.sender);
  }

  /**
   * @dev Dev mint from treasury, token will be minted to the specified receiver
   */
  function treasuryMint(uint256 quantity, address receiver) external onlyOwner {
    _treasuryMint(quantity, receiver);
  }

  function _treasuryMint(uint256 quantity, address receiver) internal {
    if (treasuryMintedCount + quantity > MAX_TREASURY_MINT_LIMIT)
      revert ReachedMaxTreasurySupply();

    if (totalSupply() + quantity > COLLECTION_SIZE)
      revert ReachedMaxTotalSupply();

    uint256 indexBeforeMint = _nextTokenId();

    _safeMint(receiver, quantity);

    treasuryMintedCount += quantity;

    emit TreasuryMint(receiver, quantity, indexBeforeMint);
  }

  function burn(uint256 tokenId) external {
    _burn(tokenId, true);
  }

  modifier onlyMinters() {
    if (!minters[msg.sender]) {
      revert InvalidMinter(msg.sender);
    }
    _;
  }

  function mint(address to, uint256 quantity) external onlyMinters {
    if (totalSupply() + quantity > COLLECTION_SIZE)
      revert ReachedMaxTotalSupply();

    _safeMint(to, quantity);
  }

  // ERC2981 Royalty START
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721A, ERC2981) returns (bool) {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return
      ERC721A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }

  function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  // ERC2981 Royalty END

  // Operator filtering START
  function setApprovalForAll(
    address operator,
    bool approved
  ) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public payable override(ERC721A) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  /**
   * @dev Both safeTransferFrom functions in ERC721A call this function
   * so we don't need to override them.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  // Operator filtering END
}
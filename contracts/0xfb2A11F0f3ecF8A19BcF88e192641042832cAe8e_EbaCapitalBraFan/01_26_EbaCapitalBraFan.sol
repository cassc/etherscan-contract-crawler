// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@divergencetech/ethier/contracts/sales/FixedPriceSeller.sol";
import "@divergencetech/ethier/contracts/crypto/SignerManager.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@divergencetech/ethier/contracts/crypto/SignatureChecker.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/**
 @title CAPITAL BRA - EPIC BREAKTHROUGH AWARD - Superfan Collection
 @author VAULTRIDERS GMBH
 */
contract EbaCapitalBraFan is
  ERC721A,
  ERC2981,
  DefaultOperatorFilterer,
  FixedPriceSeller,
  SignerManager
{
  using SignatureChecker for EnumerableSet.AddressSet;
  using Strings for uint256;

  uint32 public mintAllowlistStartTime;

  string private _baseTokenURI;

  mapping(bytes32 => bool) private usedMessages;

  constructor(address payable _beneficiary, address payable _royaltyReceiver)
    ERC721A("CAPITAL BRA - EPIC BREAKTHROUGH AWARD - Superfan Collection", "EBA_CB_S")
    FixedPriceSeller(
      0.1 ether,
      Seller.SellerConfig({
        totalInventory: 250,
        lockTotalInventory: false,
        maxPerAddress: 10,
        maxPerTx: 10,
        freeQuota: 5,
        lockFreeQuota: false,
        reserveFreeQuota: true
      }),
      _beneficiary
    )
  {
    _setDefaultRoyalty(_royaltyReceiver, 1000);
  }

  /// @notice Internal override of Seller function for handling purchase (i.e. minting).
  function _handlePurchase(
    address to,
    uint256 n,
    bool
  ) internal override {
    _safeMint(to, n);
  }

  /// @notice Requires that msg.sender owns or is approved for the token.
  modifier onlyApprovedOrOwner(uint256 tokenId) {
    require(
      ownerOf(tokenId) == _msgSender() || getApproved(tokenId) == _msgSender(),
      "not approved nor owner"
    );
    _;
  }

  /// @notice Requires that a token with this id exists.
  modifier tokenIdExists(uint256 tokenId) {
    require(_exists(tokenId), "id does not exist");
    _;
  }

  /// @notice Requires that the mint is already open.
  modifier mintIsOpen(uint32 startTime) {
    uint256 _startTime = uint256(startTime);
    require(
      _startTime != 0 && block.timestamp >= _startTime,
      "mint has not started yet"
    );
    _;
  }

  function mintAllowlist(
    address to,
    uint16 requested,
    uint32 nonce,
    bytes calldata sig
  ) external payable mintIsOpen(mintAllowlistStartTime) {
    signers.requireValidSignature(
      _signaturePayload(to, nonce),
      sig,
      usedMessages
    );
    Seller._purchase(to, requested);
  }

  function setMintConfig(uint32 allowlistStartTime) external onlyOwner {
    mintAllowlistStartTime = allowlistStartTime;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  /**
    @dev Constructs the buffer that is hashed for validation with a minting
    signature.
    */
  function _signaturePayload(address to, uint32 nonce)
    internal
    pure
    returns (bytes memory)
  {
    return abi.encodePacked(to, nonce);
  }

  function setApprovalForAll(address operator, bool approved)
    public
    override
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
    public
    override
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, ERC2981)
    returns (bool)
  {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return
      ERC721A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Modified version of Zora's ERC721Drop: https://github.com/ourzora/zora-drops-contracts/blob/main/src/ERC721Drop.sol
// Supports an extra waitlist sale stage

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";

import "operator-filter-registry/src/OperatorFilterer.sol";

import "./ERC721SaleStorage.sol";
import "./IERC721Sale.sol";

contract ERC721Sale is
  ERC721AQueryable,
  ERC721ABurnable,
  ReentrancyGuard,
  AccessControl,
  IERC721Sale,
  ERC721SaleStorage,
  OperatorFilterer
{
  /// @dev This is the max mint batch size for the optimized ERC721A mint contract
  uint256 internal immutable MAX_MINT_BATCH_SIZE = 8;

  /// @dev Gas limit to send funds
  uint256 internal immutable FUNDS_SEND_GAS_LIMIT = 210_000;

  /// @notice Access control roles
  bytes32 public immutable MINTER_ROLE = keccak256("MINTER");
  bytes32 public immutable SALES_MANAGER_ROLE = keccak256("SALES_MANAGER");

  constructor(
    string memory name,
    string memory symbol,
    string memory uri,
    address payable fundsRecipient,
    uint64 collectionSize
  ) ERC721A(name, symbol) OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), true) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(SALES_MANAGER_ROLE, _msgSender());

    setBaseURI(uri);

    // Setup config variables
    config.collectionSize = collectionSize;
    config.fundsRecipient = fundsRecipient;
  }

  /// @notice Only allow for users with admin access
  modifier onlyAdmin() {
    if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
      revert Access_OnlyAdmin();
    }

    _;
  }

  /// @notice Only a given role has access or admin
  /// @param role role to check for alongside the admin role
  modifier onlyRoleOrAdmin(bytes32 role) {
    if (
      !hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) && !hasRole(role, _msgSender())
    ) {
      revert Access_MissingRoleOrAdmin(role);
    }

    _;
  }

  /// @notice Allows user to mint tokens at a quantity
  modifier canMintTokens(uint256 quantity) {
    if (quantity + _totalMinted() > config.collectionSize) {
      revert Mint_SoldOut();
    }

    _;
  }

  function _presaleActive() internal view returns (bool) {
    return
      salesConfig.presaleStart <= block.timestamp &&
      salesConfig.presaleEnd > block.timestamp;
  }

  function _waitlistSaleActive() internal view returns (bool) {
    return
      salesConfig.waitlistSaleStart <= block.timestamp &&
      salesConfig.waitlistSaleEnd > block.timestamp;
  }

  function _publicSaleActive() internal view returns (bool) {
    return
      salesConfig.publicSaleStart <= block.timestamp &&
      salesConfig.publicSaleEnd > block.timestamp;
  }

  /// @notice Presale active
  modifier onlyPresaleActive() {
    if (!_presaleActive()) {
      revert Presale_Inactive();
    }

    _;
  }

  /// @notice Presale active
  modifier onlyWaitlistSaleActive() {
    if (!_waitlistSaleActive()) {
      revert WaitlistSale_Inactive();
    }

    _;
  }

  /// @notice Public sale active
  modifier onlyPublicSaleActive() {
    if (!_publicSaleActive()) {
      revert Sale_Inactive();
    }

    _;
  }

  /// @notice Getter for last minted token ID (gets next token id and subtracts 1)
  function _lastMintedTokenId() internal view returns (uint256) {
    return _nextTokenId() - 1;
  }

  /// @notice Start token ID for minting (1-100 vs 0-99)
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /// @dev Getter for admin role associated with the contract to handle metadata
  /// @return boolean if address is admin
  function isAdmin(address user) external view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, user);
  }

  /// @notice Returns the base URI for tokens
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /// @notice Sale details
  /// @return IERC721Sale.SaleDetails sale information details
  function saleDetails()
    external
    view
    returns (IERC721Sale.SaleDetails memory)
  {
    return
      IERC721Sale.SaleDetails({
        publicSaleActive: _publicSaleActive(),
        presaleActive: _presaleActive(),
        waitlistSaleActive: _waitlistSaleActive(),
        publicSalePrice: salesConfig.publicSalePrice,
        publicSaleStart: salesConfig.publicSaleStart,
        publicSaleEnd: salesConfig.publicSaleEnd,
        presaleStart: salesConfig.presaleStart,
        presaleEnd: salesConfig.presaleEnd,
        waitlistSaleStart: salesConfig.waitlistSaleStart,
        waitlistSaleEnd: salesConfig.waitlistSaleEnd,
        presaleMerkleRoot: salesConfig.presaleMerkleRoot,
        waitlistMerkleRoot: salesConfig.waitlistMerkleRoot,
        totalMinted: _totalMinted(),
        maxSupply: config.collectionSize,
        maxSalePurchasePerAddress: salesConfig.maxSalePurchasePerAddress
      });
  }

  /// @dev Number of NFTs the user has minted per address
  /// @param minter to get counts for
  function mintedPerAddress(
    address minter
  ) external view override returns (IERC721Sale.AddressMintDetails memory) {
    return
      IERC721Sale.AddressMintDetails({
        presaleMints: presaleMintsByAddress[minter],
        waitlistMints: waitlistMintsByAddress[minter],
        publicMints: _numberMinted(minter) -
          presaleMintsByAddress[minter] -
          waitlistMintsByAddress[minter],
        totalMints: _numberMinted(minter)
      });
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***     PUBLIC MINTING FUNCTIONS       ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  /**
      @dev This allows the user to purchase a token
           at the given price in the contract.
     */
  function purchase(
    uint256 quantity
  )
    external
    payable
    nonReentrant
    canMintTokens(quantity)
    onlyPublicSaleActive
    returns (uint256)
  {
    uint256 salePrice = salesConfig.publicSalePrice;

    if (msg.value != salePrice * quantity) {
      revert Purchase_WrongPrice(salePrice * quantity);
    }

    // If max purchase per address == 0 there is no limit.
    // Any other number, the per address mint limit is that.
    if (
      salesConfig.maxSalePurchasePerAddress != 0 &&
      _numberMinted(_msgSender()) +
        quantity -
        presaleMintsByAddress[_msgSender()] -
        waitlistMintsByAddress[_msgSender()] >
      salesConfig.maxSalePurchasePerAddress
    ) {
      revert Purchase_TooManyForAddress();
    }

    _mintNFTs(_msgSender(), quantity);
    uint256 firstMintedTokenId = _lastMintedTokenId() - quantity;

    emit IERC721Sale.Sale({
      to: _msgSender(),
      quantity: quantity,
      pricePerToken: salePrice,
      firstPurchasedTokenId: firstMintedTokenId
    });
    return firstMintedTokenId;
  }

  /// @notice Function to mint NFTs
  /// @dev (important: Does not enforce max supply limit, enforce that limit earlier)
  /// @dev This batches in size of 8 as per recommended by ERC721A creators
  /// @param to address to mint NFTs to
  /// @param quantity number of NFTs to mint
  function _mintNFTs(address to, uint256 quantity) internal {
    do {
      uint256 toMint = quantity > MAX_MINT_BATCH_SIZE
        ? MAX_MINT_BATCH_SIZE
        : quantity;
      _mint({to: to, quantity: toMint});
      quantity -= toMint;
    } while (quantity > 0);
  }

  function purchasePresale(
    uint256 quantity,
    uint256 maxQuantity,
    uint256 pricePerToken,
    bytes32[] calldata merkleProof
  )
    external
    payable
    nonReentrant
    canMintTokens(quantity)
    onlyPresaleActive
    returns (uint256)
  {
    if (
      !MerkleProof.verify(
        merkleProof,
        salesConfig.presaleMerkleRoot,
        // address, uint256, uint256
        keccak256(
          bytes.concat(
            keccak256(abi.encode(_msgSender(), maxQuantity, pricePerToken))
          )
        )
      )
    ) {
      revert Presale_MerkleNotApproved();
    }

    if (msg.value != pricePerToken * quantity) {
      revert Purchase_WrongPrice(pricePerToken * quantity);
    }

    presaleMintsByAddress[_msgSender()] += quantity;
    if (presaleMintsByAddress[_msgSender()] > maxQuantity) {
      revert Presale_TooManyForAddress();
    }

    _mintNFTs(_msgSender(), quantity);
    uint256 firstMintedTokenId = _lastMintedTokenId() - quantity;

    emit IERC721Sale.Sale({
      to: _msgSender(),
      quantity: quantity,
      pricePerToken: pricePerToken,
      firstPurchasedTokenId: firstMintedTokenId
    });

    return firstMintedTokenId;
  }

  function purchaseWaitlist(
    uint256 quantity,
    uint256 maxQuantity,
    uint256 pricePerToken,
    bytes32[] calldata merkleProof
  )
    external
    payable
    nonReentrant
    canMintTokens(quantity)
    onlyWaitlistSaleActive
    returns (uint256)
  {
    if (
      !MerkleProof.verify(
        merkleProof,
        salesConfig.waitlistMerkleRoot,
        // address, uint256, uint256
        keccak256(
          bytes.concat(
            keccak256(abi.encode(_msgSender(), maxQuantity, pricePerToken))
          )
        )
      )
    ) {
      revert WaitlistSale_MerkleNotApproved();
    }

    if (msg.value != pricePerToken * quantity) {
      revert Purchase_WrongPrice(pricePerToken * quantity);
    }

    waitlistMintsByAddress[_msgSender()] += quantity;
    if (waitlistMintsByAddress[_msgSender()] > maxQuantity) {
      revert WaitlistSale_TooManyForAddress();
    }

    _mintNFTs(_msgSender(), quantity);
    uint256 firstMintedTokenId = _lastMintedTokenId() - quantity;

    emit IERC721Sale.Sale({
      to: _msgSender(),
      quantity: quantity,
      pricePerToken: pricePerToken,
      firstPurchasedTokenId: firstMintedTokenId
    });

    return firstMintedTokenId;
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***     ADMIN MINTING FUNCTIONS        ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  /// @notice Mint admin
  /// @param recipient recipient to mint to
  /// @param quantity quantity to mint
  function adminMint(
    address recipient,
    uint256 quantity
  )
    external
    onlyRoleOrAdmin(MINTER_ROLE)
    canMintTokens(quantity)
    returns (uint256)
  {
    _mintNFTs(recipient, quantity);

    return _lastMintedTokenId();
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***  ADMIN CONFIGURATION FUNCTIONS     ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  function setBaseURI(string memory uri) public onlyAdmin {
    baseURI = uri;
  }

  /// @dev This sets the sales configuration
  /// @param publicSalePrice New public sale price
  /// @param maxSalePurchasePerAddress Max # of purchases (public) per address allowed
  /// @param publicSaleStart unix timestamp when the public sale starts
  /// @param publicSaleEnd unix timestamp when the public sale ends (set to 0 to disable)
  /// @param presaleStart unix timestamp when the presale starts
  /// @param presaleEnd unix timestamp when the presale ends
  /// @param presaleMerkleRoot merkle root for the presale information
  /// @param waitlistSaleStart unix timestamp when the waitlist sale starts
  /// @param waitlistSaleEnd unix timestamp when the waitlist sale ends
  /// @param waitlistSaleEnd merkle root for the waitlist sale information
  function setSaleConfiguration(
    uint104 publicSalePrice,
    uint32 maxSalePurchasePerAddress,
    uint64 publicSaleStart,
    uint64 publicSaleEnd,
    uint64 presaleStart,
    uint64 presaleEnd,
    uint64 waitlistSaleStart,
    uint64 waitlistSaleEnd,
    bytes32 presaleMerkleRoot,
    bytes32 waitlistMerkleRoot
  ) external onlyRoleOrAdmin(SALES_MANAGER_ROLE) {
    salesConfig.publicSalePrice = publicSalePrice;
    salesConfig.maxSalePurchasePerAddress = maxSalePurchasePerAddress;
    salesConfig.publicSaleStart = publicSaleStart;
    salesConfig.publicSaleEnd = publicSaleEnd;
    salesConfig.presaleStart = presaleStart;
    salesConfig.presaleEnd = presaleEnd;
    salesConfig.presaleMerkleRoot = presaleMerkleRoot;
    salesConfig.waitlistSaleStart = waitlistSaleStart;
    salesConfig.waitlistSaleEnd = waitlistSaleEnd;
    salesConfig.waitlistMerkleRoot = waitlistMerkleRoot;

    emit SalesConfigChanged(_msgSender());
  }

  /// @notice Set a different funds recipient
  /// @param newRecipientAddress new funds recipient address
  function setFundsRecipient(
    address payable newRecipientAddress
  ) external onlyRoleOrAdmin(SALES_MANAGER_ROLE) {
    config.fundsRecipient = newRecipientAddress;
    emit FundsRecipientChanged(newRecipientAddress, _msgSender());
  }

  /// @notice This withdraws ETH from the contract to the contract owner.
  function withdraw() external nonReentrant {
    address sender = _msgSender();

    // Get fee amount
    uint256 funds = address(this).balance;

    // Check if withdraw is allowed for sender
    if (
      !hasRole(DEFAULT_ADMIN_ROLE, sender) &&
      !hasRole(SALES_MANAGER_ROLE, sender) &&
      sender != config.fundsRecipient
    ) {
      revert Access_WithdrawNotAllowed();
    }

    // Payout recipient
    (bool successFunds, ) = config.fundsRecipient.call{
      value: funds,
      gas: FUNDS_SEND_GAS_LIMIT
    }("");
    if (!successFunds) {
      revert Withdraw_FundsSendFailure();
    }

    // Emit event for indexing
    emit FundsWithdrawn(_msgSender(), config.fundsRecipient, funds);
  }

  function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  // The following functions are overrides required by Solidity.

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721A, IERC721A, AccessControl) returns (bool) {
    return
      super.supportsInterface(interfaceId) ||
      type(IERC721Sale).interfaceId == interfaceId;
  }
}
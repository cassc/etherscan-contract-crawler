// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {UpdatableOperatorFiltererUpgradeable} from "operator-filter-registry/src/upgradeable/UpdatableOperatorFiltererUpgradeable.sol";
import "erc721a/contracts/IERC721A.sol";

error ReaderTokens__ExternalContractNotSet();
error ReaderTokens__OnlyAllowedMinterCanCall();
error ReaderTokens__PackAlreadyOpened();
error ReaderTokens__MaxSupplyReached();
error ReaderTokens__InvalidAddress();
error ReaderTokens__MustBeGreaterThanZero();
error ReaderTokens__RedemptionsNotAllowed();
error ReaderTokens__PaymentInsufficient();
error ReaderTokens__TransferFailed();
error ReaderTokens__NotEnabled();
error ReaderTokens__MustBeHolder();
error ReaderTokens__ContractsNotSet();
error ReaderTokens__AlreadyClaimed();
error ReaderTokens__QuantityExceedsMax();

contract ReaderTokens1155 is
  Initializable,
  ERC1155Upgradeable,
  OwnableUpgradeable,
  ERC1155SupplyUpgradeable,
  UUPSUpgradeable,
  ReentrancyGuardUpgradeable,
  ERC2981Upgradeable,
  UpdatableOperatorFiltererUpgradeable
{
  /////////////////////
  // State Variables //
  /////////////////////

  uint16 public constant TOKEN_1_MAX_SUPPLY = 4564;

  uint256 public constant GENESIS_ISSUE_01_ID = 1;
  uint256 public constant AGE_OF_VALOR_01_ARTIST_EDITION_ID = 2;
  uint256 public constant AGE_OF_VALOR_01_ID = 3;
  uint256 public constant AGE_OF_VALOR_01_FTR_ID = 4;
  uint256 public constant GENESIS_ISSUE_01_ASHCAN_ID = 5;

  string private s_contractURI;

  /**
   * @notice tokenId -> address that is allowed to mint
   */
  mapping(uint256 => address) private s_allowedMinter;

  /**
   * @notice packId -> address the token was minted to
   */
  mapping(uint256 => address) private s_packIdToAddress;

  /**
   * @notice tokenId -> whether redemptions are currently allowed.
   */
  mapping(uint256 => bool) private s_canRedeem;

  /**
   * @notice address -> tokenId -> number of redemptions
   */
  mapping(address => mapping(uint256 => uint256))
    private s_addressToRedemptions;

  /**
   * @notice tokenId -> number of redemptions
   */
  mapping(uint256 => uint256) private s_tokenIdToRedemptions;

  /**
   * @notice tokenId -> price in wei
   */
  mapping(uint256 => uint256) private s_tokenIdToPrice;

  /**
   * @notice tokenId -> whether token is enabled for minting
   */
  mapping(uint256 => bool) private s_tokenIdToMintEnabled;

  /**
   * @notice studio badge id -> whether AgoOfValorTokens are claimed
   */
  mapping(uint256 => bool) private s_studioBadgeIdToAov01Claimed;

  /**
   * @notice address -> number of AoV Artist Edition tokens minted
   * @dev Only 5 allowed per wallet
   */
  mapping(address => uint256) private s_addressToAovArtistEditionMinted;

  IERC721A private s_azukiContract;
  IERC721A private s_beanzContract;
  IERC721A private s_studioBadgeContract;
  IERC721A private s_biplaneBoboContract;
  IERC1155Upgradeable private s_bobuContract;

  /**
   * @notice tokenId -> whether token has been claimed
   * @dev used in case a claim needs to be tracked for a token
   */
  mapping(uint256 => mapping(address => bool))
    private s_tokenIdToAddressClaimed;

  /**
   * @notice tokenId -> whether the token is claimable
   */
  mapping(uint256 => bool) private s_tokenIdToClaimable;

  /////////////////////
  // Events          //
  /////////////////////

  /**
   * @dev Emitted when a token is minted from a pack
   */
  event MintedFromPack(
    uint256 indexed packId,
    uint256 tokenId,
    address indexed mintedTo
  );

  /**
   * @dev Emitted when a token is minted
   */
  event MintedToken(
    uint256 indexed tokenId,
    uint256 indexed amount,
    address indexed mintedTo
  );

  /**
   * @dev Emitted when a studio badge holder claims
   * their Age of Valor tokens
   */
  event AgeOfValorClaimedByStudioBadge(
    uint256 indexed studioBadgeId,
    address indexed mintedTo
  );

  /**
   * @dev Emitted when a token is redeemed for a physical item
   */
  event RedeemedToken(
    uint256 indexed tokenId,
    uint256 numRedeemed,
    address indexed redeemedBy
  );

  /**
   * @dev Emitted when a token is minted by owner
   */
  event Minted(
    uint256 indexed tokenId,
    uint256 amount,
    address indexed mintedTo
  );

  /**
   * @dev Emitted when a batch of tokens are minted by owner
   */
  event MintedBatch(
    uint256[] tokenIds,
    uint256[] amounts,
    address indexed mintedTo
  );

  /**
   * @dev Emitted when the contract URI is updated
   */
  event ContractURIUpdated(address operator, string newContractURI);

  /**
   * @dev Emitted when the URI is updated
   */
  event URIUpdated(string newuri);

  /**
   * @dev Emitted when the price is updated
   */
  event PriceUpdated(uint256 tokenId, uint256 newPrice);

  ////////////////////
  // Main Functions //
  ////////////////////

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize() public initializer {
    __ERC1155_init("");
    __Ownable_init();
    __ERC1155Supply_init();
    __UUPSUpgradeable_init();
    __ReentrancyGuard_init();
    __ERC2981_init();
    __UpdatableOperatorFiltererUpgradeable_init(
      0x000000000000AAeB6D7670E522A718067333cd4E,
      0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6,
      true
    );
    s_tokenIdToPrice[AGE_OF_VALOR_01_ARTIST_EDITION_ID] = 0.028 ether;
    s_tokenIdToPrice[AGE_OF_VALOR_01_ID] = .00888 ether;
  }

  ////////////////////
  // Mint Functions //
  ////////////////////

  /**
   * @notice mints Genesis Issue 01 token from powerpack contract
   * @dev setPowerPackContract() must be set
   */
  function mintToOpenedPack(
    address to,
    uint256 packId
  ) external virtual nonReentrant {
    if (s_allowedMinter[GENESIS_ISSUE_01_ID] == address(0)) {
      revert ReaderTokens__ExternalContractNotSet();
    }
    if (to == address(0)) {
      revert ReaderTokens__InvalidAddress();
    }
    if (msg.sender != s_allowedMinter[GENESIS_ISSUE_01_ID]) {
      revert ReaderTokens__OnlyAllowedMinterCanCall();
    }
    if (s_packIdToAddress[packId] != address(0)) {
      revert ReaderTokens__PackAlreadyOpened();
    }
    if (
      (totalSupply(GENESIS_ISSUE_01_ID) +
        s_tokenIdToRedemptions[GENESIS_ISSUE_01_ID]) >= TOKEN_1_MAX_SUPPLY
    ) {
      revert ReaderTokens__MaxSupplyReached();
    }

    _mint(to, GENESIS_ISSUE_01_ID, 1, "");
    s_packIdToAddress[packId] = to;
    emit MintedFromPack(packId, 1, to);
  }

  /**
   * @notice checks if account is a holder of Azuki, Beanz, Bobu, BiPlaneBobo, or
   * StudioBadge
   * @dev contract addresses must be set or it will revert
   * @param account address to check
   * @return true if account is a token holder of at least one of the tokens
   */
  function isTokenHolder(address account) public view returns (bool) {
    return (s_azukiContract.balanceOf(account) > 0 ||
      s_beanzContract.balanceOf(account) > 0 ||
      s_bobuContract.balanceOf(account, 1) > 0 ||
      s_biplaneBoboContract.balanceOf(account) > 0 ||
      s_studioBadgeContract.balanceOf(account) > 0);
  }

  /**
   * @notice mints Age of Valor 01 Artist and Open Editions
   * @param quantityArtistEdition number of Artist Edition tokens to mint
   * @param quantityOpenEdition number of Open Edition tokens to mint
   * @dev must be a holder of Azuki, Beanz, Bobu, BiPlaneBobo, or StudioBadge
   */
  function mintAgeOfValorSpecial(
    uint256 quantityArtistEdition,
    uint256 quantityOpenEdition
  ) external payable nonReentrant {
    if (!s_tokenIdToMintEnabled[AGE_OF_VALOR_01_ARTIST_EDITION_ID]) {
      revert ReaderTokens__NotEnabled();
    }
    if (
      s_addressToAovArtistEditionMinted[msg.sender] + quantityArtistEdition > 5
    ) {
      revert ReaderTokens__QuantityExceedsMax();
    }
    if (
      msg.value <
      s_tokenIdToPrice[AGE_OF_VALOR_01_ARTIST_EDITION_ID] *
        quantityArtistEdition +
        s_tokenIdToPrice[AGE_OF_VALOR_01_ID] *
        quantityOpenEdition
    ) {
      revert ReaderTokens__PaymentInsufficient();
    }
    if (!isTokenHolder(msg.sender)) {
      revert ReaderTokens__MustBeHolder();
    }
    _mint(
      msg.sender,
      AGE_OF_VALOR_01_ARTIST_EDITION_ID,
      quantityArtistEdition,
      ""
    );
    s_addressToAovArtistEditionMinted[msg.sender] += quantityArtistEdition;
    _mint(msg.sender, AGE_OF_VALOR_01_ID, quantityOpenEdition, "");
    emit MintedToken(
      AGE_OF_VALOR_01_ARTIST_EDITION_ID,
      quantityArtistEdition,
      msg.sender
    );
    emit MintedToken(AGE_OF_VALOR_01_ID, quantityOpenEdition, msg.sender);
  }

  /**
   * @notice mints tokens for a given token id
   * @param tokenId token ID to mint
   * @param quantity number of tokens to mint
   * @dev MUST set price before enabling,
   * must enable minting for token and payment must be sufficient
   */
  function mintPublic(
    uint256 tokenId,
    uint256 quantity
  ) external payable nonReentrant {
    if (!s_tokenIdToMintEnabled[tokenId]) {
      revert ReaderTokens__NotEnabled();
    }
    if (msg.value < s_tokenIdToPrice[tokenId] * quantity) {
      revert ReaderTokens__PaymentInsufficient();
    }
    _mint(msg.sender, tokenId, quantity, "");
    emit MintedToken(tokenId, quantity, msg.sender);
  }

  /**
   * @notice Claims Age of Valor Artist Edition and Age of Valor tokens for
   * Studio Badge holders
   * @param badgeId Studio Badge token ID
   * @dev Only one claim per badge and only claimable while mint is enabled
   */
  function studioBadgeClaimAgeOfValor(uint256 badgeId) external nonReentrant {
    if (
      !(s_tokenIdToMintEnabled[AGE_OF_VALOR_01_ARTIST_EDITION_ID] ||
        s_tokenIdToMintEnabled[AGE_OF_VALOR_01_ID])
    ) {
      revert ReaderTokens__NotEnabled();
    }
    if (s_studioBadgeIdToAov01Claimed[badgeId]) {
      revert ReaderTokens__AlreadyClaimed();
    }
    if (s_studioBadgeContract.ownerOf(badgeId) != msg.sender) {
      revert ReaderTokens__MustBeHolder();
    }
    s_studioBadgeIdToAov01Claimed[badgeId] = true;
    _mint(msg.sender, AGE_OF_VALOR_01_ARTIST_EDITION_ID, 1, "");
    _mint(msg.sender, AGE_OF_VALOR_01_ID, 1, "");
    emit AgeOfValorClaimedByStudioBadge(badgeId, msg.sender);
    emit MintedToken(AGE_OF_VALOR_01_ARTIST_EDITION_ID, 1, msg.sender);
    emit MintedToken(AGE_OF_VALOR_01_ID, 1, msg.sender);
  }

  /**
   * @notice Mints a given token ID
   * @dev Only one claim per address and only claimable if
   * setTokenIdToClaimable(tokenId, true) has been called
   */
  function claimToken(uint256 tokenId) external nonReentrant {
    if (!s_tokenIdToClaimable[tokenId]) {
      revert ReaderTokens__RedemptionsNotAllowed();
    }
    if (s_tokenIdToAddressClaimed[tokenId][msg.sender]) {
      revert ReaderTokens__AlreadyClaimed();
    }
    s_tokenIdToAddressClaimed[tokenId][msg.sender] = true;
    _mint(msg.sender, tokenId, 1, "");
    emit MintedToken(tokenId, 1, msg.sender);
  }

  //////////////////////
  // Redeem Functions //
  //////////////////////

  function redeemTokens(
    uint256 tokenId,
    uint256 amount
  ) external virtual nonReentrant {
    if (!s_canRedeem[tokenId]) {
      revert ReaderTokens__RedemptionsNotAllowed();
    }
    _burn(msg.sender, tokenId, amount);
    s_addressToRedemptions[msg.sender][tokenId] += amount;
    s_tokenIdToRedemptions[tokenId] += amount;
    emit RedeemedToken(tokenId, amount, msg.sender);
  }

  /////////////////////
  // Admin Functions //
  /////////////////////

  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyOwner {}

  /**
   * @notice Mints a token
   * @param to the address to mint the token to
   * @param id the tokenId to mint
   * @param amount the amount to mint
   * @param data any data to send along with this mint
   */
  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external onlyOwner {
    if (amount == 0) {
      revert ReaderTokens__MustBeGreaterThanZero();
    }
    _mint(to, id, amount, data);
    emit Minted(id, amount, to);
  }

  /**
   * @notice Mints a batch of tokens
   * @param to the address to mint the token to
   * @param ids the tokenIds to mint
   * @param amounts the amounts to mint
   * @param data any data to send along with this mint
   */
  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external onlyOwner {
    for (uint256 i = 0; i < ids.length; i++) {
      if (amounts[i] == 0) {
        revert ReaderTokens__MustBeGreaterThanZero();
      }
    }
    _mintBatch(to, ids, amounts, data);
    emit MintedBatch(ids, amounts, to);
  }

  /**
   * @notice Sets the address that is allowed to mint a token
   * @param tokenId the tokenId that will be minted
   * @param allowedMinter the address that is allowed to mint that token
   */
  function setAllowedMinter(
    uint256 tokenId,
    address allowedMinter
  ) external onlyOwner {
    if (allowedMinter == address(0)) {
      revert ReaderTokens__InvalidAddress();
    }
    s_allowedMinter[tokenId] = allowedMinter;
  }

  /**
   * @notice Sets whether redemptions are allowed for a token
   * @param tokenId the tokenId that will be redeemed
   * @param canRedeem whether redemptions are allowed for that token
   */
  function setCanRedeem(uint256 tokenId, bool canRedeem) external onlyOwner {
    s_canRedeem[tokenId] = canRedeem;
  }

  /**
   * @notice Sets the contract URI for OpenSea listings
   * @param newContractURI new contract URI
   */
  function setContractURI(string memory newContractURI) external onlyOwner {
    if (bytes(newContractURI).length == 0) {
      revert ReaderTokens__InvalidAddress();
    }
    s_contractURI = newContractURI;
    emit ContractURIUpdated(msg.sender, newContractURI);
  }

  /**
   * @notice Sets the price of a token
   * @param tokenId the tokenId that will be updated
   * @param price the new price of the token
   */
  function setTokenPrice(uint256 tokenId, uint256 price) external onlyOwner {
    s_tokenIdToPrice[tokenId] = price;
    emit PriceUpdated(tokenId, price);
  }

  /**
   * @notice Sets whether a token is claimable
   * @param tokenId the tokenId that will be updated
   * @param claimable whether the token is claimable
   */
  function setTokenIdToClaimable(
    uint256 tokenId,
    bool claimable
  ) external onlyOwner {
    s_tokenIdToClaimable[tokenId] = claimable;
  }

  /**
   * @notice Sets whether a token is enabled for minting
   * @param tokenId the tokenId that will be updated
   * @param enabled whether the token is enabled for minting
   */
  function setTokenIdToMintEnabled(
    uint256 tokenId,
    bool enabled
  ) external onlyOwner {
    if (
      address(s_azukiContract) == address(0) ||
      address(s_beanzContract) == address(0) ||
      address(s_bobuContract) == address(0) ||
      address(s_studioBadgeContract) == address(0) ||
      address(s_biplaneBoboContract) == address(0)
    ) {
      revert ReaderTokens__ContractsNotSet();
    }
    s_tokenIdToMintEnabled[tokenId] = enabled;
  }

  /**
   * @notice Sets the contract addresses for holder checks
   * @param newAddresses array of addresses to set
   */
  function setContractAddresses(
    address[] memory newAddresses
  ) external onlyOwner {
    if (newAddresses.length != 5) {
      revert ReaderTokens__ContractsNotSet();
    }
    for (uint256 i = 0; i < newAddresses.length; i++) {
      if (newAddresses[i] == address(0)) {
        revert ReaderTokens__InvalidAddress();
      }
    }
    s_azukiContract = IERC721A(newAddresses[0]);
    s_beanzContract = IERC721A(newAddresses[1]);
    s_bobuContract = IERC1155Upgradeable(newAddresses[2]);
    s_studioBadgeContract = IERC721A(newAddresses[3]);
    s_biplaneBoboContract = IERC721A(newAddresses[4]);
  }

  function setURI(string memory newuri) external onlyOwner {
    if (bytes(newuri).length == 0) {
      revert ReaderTokens__InvalidAddress();
    }
    _setURI(newuri);
    emit URIUpdated(newuri);
  }

  /**
   * @notice Withdraws funds to owner
   */
  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    if (!success) revert ReaderTokens__TransferFailed();
  }

  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  ////////////////////
  // View Functions //
  ////////////////////

  /**
   * @notice Returns the contract URI for OpenSea
   */
  function contractURI() external view returns (string memory) {
    return s_contractURI;
  }

  /**
   * @notice Returns number of AOV Artist Edition tokens minted for an address
   * @param account the address to check
   * @dev Maximum 5 AOV Artist Edition tokens can be minted per address
   */
  function getAovArtistEditionMinted(
    address account
  ) external view returns (uint8) {
    return uint8(s_addressToAovArtistEditionMinted[account]);
  }

  /**
   * @notice Returns the address allowed to mint a token.
   * @param tokenId the tokenId to check
   */
  function getAllowedMinter(uint256 tokenId) external view returns (address) {
    return s_allowedMinter[tokenId];
  }

  /**
   * @notice Returns the addresses of the Azuki, Beanz, Bobu, Studio Badge,
   * and Biplane Bobo contracts.
   */
  function getContractAddresses() external view returns (address[5] memory) {
    return [
      address(s_azukiContract),
      address(s_beanzContract),
      address(s_bobuContract),
      address(s_studioBadgeContract),
      address(s_biplaneBoboContract)
    ];
  }

  /**
   * @notice Returns whether a token can be redeemed.
   * @param tokenId the tokenId to check
   */
  function getCanRedeem(uint256 tokenId) external view returns (bool) {
    return s_canRedeem[tokenId];
  }

  /**
   * @notice Returns the address a token was minted to for a given packId.
   * @param packId the packId to check
   */
  function getAddressFromPackId(
    uint256 packId
  ) external view returns (address) {
    return s_packIdToAddress[packId];
  }

  /**
   * @notice Returns whether a studio badge has claimed their
   * Age of Valor tokens.
   * @param badgeId the studio badge token Id to check
   */
  function getAov01Claimed(uint256 badgeId) external view returns (bool) {
    return s_studioBadgeIdToAov01Claimed[badgeId];
  }

  /**
   * @notice Returns the price of a token.
   * @param tokenId tokenId to check
   */
  function getTokenPrice(uint256 tokenId) external view returns (uint256) {
    return s_tokenIdToPrice[tokenId];
  }

  /**
   * @notice Returns whether a token has been claimed by an address
   * @param tokenId id of token to check
   * @param addr address to check
   */
  function getTokenIdToAddressClaimed(
    uint256 tokenId,
    address addr
  ) external view returns (bool) {
    return s_tokenIdToAddressClaimed[tokenId][addr];
  }

  /**
   * @notice Returns whether a token Id is claimable
   * @param tokenId id of token to check
   */
  function getTokenIdToClaimable(uint256 tokenId) external view returns (bool) {
    return s_tokenIdToClaimable[tokenId];
  }

  /**
   * @notice Returns whether a token is enabled for minting.
   * @param tokenId the tokenId to check
   */
  function getTokenIdToMintEnabled(
    uint256 tokenId
  ) external view returns (bool) {
    return s_tokenIdToMintEnabled[tokenId];
  }

  /**
   * @notice Returns the number of redemptions for a given account and tokenId.
   * @param account the account to check
   * @param tokenId the tokenId to check
   */
  function getRedemptionsByAddress(
    address account,
    uint256 tokenId
  ) external view returns (uint256) {
    return s_addressToRedemptions[account][tokenId];
  }

  /**
   * @notice Returns the total number of redemptions for a given tokenId.
   * @param tokenId the tokenId to check
   */
  function getTotalRedemptions(
    uint256 tokenId
  ) external view returns (uint256) {
    return s_tokenIdToRedemptions[tokenId];
  }

  ///////////////////////
  // Royalty Functions //
  ///////////////////////

  function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function deleteDefaultRoyalty() external onlyOwner {
    _deleteDefaultRoyalty();
  }

  function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) external onlyOwner {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    virtual
    override(ERC1155Upgradeable, ERC2981Upgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  ///////////////////////
  // OpenSea Functions //
  ///////////////////////

  /**
   * @dev Returns the owner of the ERC1155 token contract.
   */
  function owner()
    public
    view
    virtual
    override(OwnableUpgradeable, UpdatableOperatorFiltererUpgradeable)
    returns (address)
  {
    return OwnableUpgradeable.owner();
  }

  /**
   * @dev See {IERC1155-setApprovalForAll}.
   * Added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
   */
  function setApprovalForAll(
    address operator,
    bool approved
  ) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  /**
   * @dev See {IERC1155-safeTransferFrom}.
   * Added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, amount, data);
  }

  /**
   * @dev See {IERC1155-safeBatchTransferFrom}.
   * Added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override onlyAllowedOperator(from) {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }
}
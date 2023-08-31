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
import "./test/IDelegationRegistry.sol";

error ReaderTokens__ExternalContractNotSet();
error ReaderTokens__OnlyAllowedMinterCanCall();
error ReaderTokens__PackAlreadyOpened();
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
error ReaderTokens__PriceCannotBeZero();

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
  uint16 public constant APO_01_ARTIST_MAX_SUPPLY = 420;
  uint8 public constant APO_01_GOLD_MAX_SUPPLY = 69;
  uint8 public constant APO_01_SILVER_MAX_SUPPLY = 247;

  uint256 public constant GENESIS_ISSUE_01_ID = 1;
  uint256 public constant AGE_OF_VALOR_01_ARTIST_EDITION_ID = 2;
  uint256 public constant AGE_OF_VALOR_01_ID = 3;
  uint256 public constant AGE_OF_VALOR_01_FTR_ID = 4;
  uint256 public constant GENESIS_ISSUE_01_ASHCAN_ID = 5;
  uint256 public constant APPLIED_PRIMATE_ORIGINS_01_ID = 6;
  uint256 public constant APPLIED_PRIMATE_ORIGINS_01_ARTIST_ID = 7;
  uint256 public constant APPLIED_PRIMATE_ORIGINS_01_GOLD_ID = 8;
  uint256 public constant APPLIED_PRIMATE_ORIGINS_01_SILVER_ID = 9;
  uint256 public constant APPLIED_PRIMATE_ORIGINS_01_TOXIC_ID = 10;

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

  /**
   * @notice tokenId -> studio badge id -> whether token has been claimed
   * @dev tracks whether a studio badge claim has been made for a token
   */
  mapping(uint256 => mapping(uint256 => bool))
    private s_tokenIdToStudioBadgeClaimed;

  IERC721A private s_sentinelsContract;
  IERC721A private s_keycardContract;
  IERC721A private s_baycContract;
  IERC721A private s_maycContract;
  IERC721A private s_bakcContract;
  IERC1155Upgradeable private s_tasteMakerzContract;
  IDelegationRegistry private s_delegationRegistry;

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
    uint256 indexed numRedeemed,
    address indexed redeemedBy
  );

  /**
   * @dev Emitted when a token is minted by owner
   */
  event Minted(
    uint256 indexed tokenId,
    uint256 indexed amount,
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
      revert ReaderTokens__QuantityExceedsMax();
    }

    _mint(to, GENESIS_ISSUE_01_ID, 1, "");
    s_packIdToAddress[packId] = to;
    emit MintedFromPack(packId, 1, to);
  }

  /**
   * @notice checks if account is a holder of Sentinels, Keycard, BiPlaneBobo,
   * StudioBadge, or TasteMakerz
   * @dev contract addresses must be set or it will revert
   * @param account address to check
   * @return true if account is a token holder of at least one of the tokens
   */
  function isTokenHolder(address account) public view returns (bool) {
    return (s_sentinelsContract.balanceOf(account) > 0 ||
      s_keycardContract.balanceOf(account) > 0 ||
      s_biplaneBoboContract.balanceOf(account) > 0 ||
      s_studioBadgeContract.balanceOf(account) > 0 ||
      s_tasteMakerzContract.balanceOf(account, 1) > 0);
  }

  /**
   * @notice checks if account is a holder of BAYC, MAYC, or BAKC
   * @dev contract addresses must be set or it will revert
   * @param account address to check
   * @return true if account is a token holder of at least one of the tokens
   */
  function isApeHolder(address account) public view returns (bool) {
    return (s_baycContract.balanceOf(account) > 0 ||
      s_maycContract.balanceOf(account) > 0 ||
      s_bakcContract.balanceOf(account) > 0);
  }

  /**
   * @notice mints Applied Primate Origins 01 and Artist Edition tokens.
   * A silver token is rewarded for every 10 tokens purchased and
   * a gold token is rewarded for every 25 tokens purchased in this transaction.
   * As a bonus, a toxic edition is included for free for eligible holders.
   * @param quantityArtistEdition number of Artist Edition tokens to mint
   * @param quantityOpenEdition number of Open Edition tokens to mint
   * @param vault address used as a cold wallet in delegate.xyz or address(0)
   */
  function mintApoPrivate(
    uint256 quantityArtistEdition,
    uint256 quantityOpenEdition,
    address vault
  ) external payable {
    if (!s_tokenIdToMintEnabled[APPLIED_PRIMATE_ORIGINS_01_TOXIC_ID]) {
      revert ReaderTokens__NotEnabled();
    }

    address requester = msg.sender;
    if (vault != address(0)) {
      if (
        !s_delegationRegistry.checkDelegateForContract(
          msg.sender,
          vault,
          address(this)
        )
      ) {
        revert ReaderTokens__InvalidAddress();
      }
      requester = vault;
    }

    if (!isTokenHolder(requester)) {
      revert ReaderTokens__MustBeHolder();
    }

    _mintApo(quantityArtistEdition, quantityOpenEdition, requester);
  }

  /**
   * @notice mints Applied Primate Origins 01 and Artist Edition tokens.
   * A silver token is rewarded for every 10 tokens purchased and
   * a gold token is rewarded for every 25 tokens purchased in this transaction.
   * @param quantityArtistEdition number of Artist Edition tokens to mint
   * @param quantityOpenEdition number of Open Edition tokens to mint
   * @param vault address used as a cold wallet in delegate.xyz or address(0)
   */
  function mintApoApe(
    uint256 quantityArtistEdition,
    uint256 quantityOpenEdition,
    address vault
  ) external payable {
    if (!s_tokenIdToMintEnabled[APPLIED_PRIMATE_ORIGINS_01_ARTIST_ID]) {
      revert ReaderTokens__NotEnabled();
    }
    address requester = msg.sender;
    if (vault != address(0)) {
      if (
        !s_delegationRegistry.checkDelegateForContract(
          msg.sender,
          vault,
          address(this)
        )
      ) {
        revert ReaderTokens__InvalidAddress();
      }
      requester = vault;
    }

    if (!isApeHolder(requester)) {
      revert ReaderTokens__MustBeHolder();
    }
    _mintApo(quantityArtistEdition, quantityOpenEdition, requester);
  }

  /**
   * @notice mints Applied Primate Origins 01 and Artist Edition tokens.
   * A silver token is rewarded for every 10 tokens purchased and
   * a gold token is rewarded for every 25 tokens purchased in this transaction.
   * @param quantityArtistEdition number of Artist Edition tokens to mint
   * @param quantityOpenEdition number of Open Edition tokens to mint
   * @param vault address used as a cold wallet in delegate.xyz or address(0)
   */
  function mintApoPublic(
    uint256 quantityArtistEdition,
    uint256 quantityOpenEdition,
    address vault
  ) external payable {
    if (!s_tokenIdToMintEnabled[APPLIED_PRIMATE_ORIGINS_01_ID]) {
      revert ReaderTokens__NotEnabled();
    }
    address requester = msg.sender;
    if (vault != address(0)) {
      if (
        !s_delegationRegistry.checkDelegateForContract(
          msg.sender,
          vault,
          address(this)
        )
      ) {
        revert ReaderTokens__InvalidAddress();
      }
      requester = vault;
    }
    _mintApo(quantityArtistEdition, quantityOpenEdition, requester);
  }

  function _mintApo(
    uint256 quantityArtistEdition,
    uint256 quantityOpenEdition,
    address requester
  ) private nonReentrant {
    if (
      totalSupply(APPLIED_PRIMATE_ORIGINS_01_ARTIST_ID) +
        quantityArtistEdition >
      APO_01_ARTIST_MAX_SUPPLY
    ) {
      revert ReaderTokens__QuantityExceedsMax();
    }
    if (
      msg.value <
      s_tokenIdToPrice[APPLIED_PRIMATE_ORIGINS_01_ARTIST_ID] *
        quantityArtistEdition +
        s_tokenIdToPrice[APPLIED_PRIMATE_ORIGINS_01_ID] *
        quantityOpenEdition
    ) {
      revert ReaderTokens__PaymentInsufficient();
    }
    if (quantityArtistEdition > 0) {
      _mint(
        requester,
        APPLIED_PRIMATE_ORIGINS_01_ARTIST_ID,
        quantityArtistEdition,
        ""
      );
      emit MintedToken(
        APPLIED_PRIMATE_ORIGINS_01_ARTIST_ID,
        quantityArtistEdition,
        requester
      );
    }
    if (quantityOpenEdition > 0) {
      _mint(requester, APPLIED_PRIMATE_ORIGINS_01_ID, quantityOpenEdition, "");
      emit MintedToken(
        APPLIED_PRIMATE_ORIGINS_01_ID,
        quantityOpenEdition,
        requester
      );
    }

    uint256 totalQuantity = quantityArtistEdition + quantityOpenEdition;
    if (totalQuantity >= 10) {
      uint256 quantitySilver = totalQuantity / 10;
      if (
        totalSupply(APPLIED_PRIMATE_ORIGINS_01_SILVER_ID) + quantitySilver >
        APO_01_SILVER_MAX_SUPPLY
      ) {
        quantitySilver =
          APO_01_SILVER_MAX_SUPPLY -
          totalSupply(APPLIED_PRIMATE_ORIGINS_01_SILVER_ID);
      }
      if (quantitySilver > 0) {
        _mint(
          requester,
          APPLIED_PRIMATE_ORIGINS_01_SILVER_ID,
          quantitySilver,
          ""
        );
        emit MintedToken(
          APPLIED_PRIMATE_ORIGINS_01_SILVER_ID,
          quantitySilver,
          requester
        );
      }
    }
    if (totalQuantity >= 25) {
      uint256 quantityGold = totalQuantity / 25;
      if (
        totalSupply(APPLIED_PRIMATE_ORIGINS_01_GOLD_ID) + quantityGold >
        APO_01_GOLD_MAX_SUPPLY
      ) {
        quantityGold =
          APO_01_GOLD_MAX_SUPPLY -
          totalSupply(APPLIED_PRIMATE_ORIGINS_01_GOLD_ID);
      }
      if (quantityGold > 0) {
        _mint(requester, APPLIED_PRIMATE_ORIGINS_01_GOLD_ID, quantityGold, "");
        emit MintedToken(
          APPLIED_PRIMATE_ORIGINS_01_GOLD_ID,
          quantityGold,
          requester
        );
      }
    }
  }

  /**
   * @notice claim toxic edition for studio badge and keycard holders
   * @dev To avoid creating a new storage slot, we are using s_tokenIdToStudioBadgeClaimed
   * with the apo silver token ID to track whether a keycard holder has claimed
   * @param badgeIds token IDs to claim for
   * @param keycardIds token IDs to claim for
   * @param vault address used as a cold wallet in delegate.xyz or address(0)
   */
  function claimToxic(
    uint256[] calldata badgeIds,
    uint256[] calldata keycardIds,
    address vault
  ) external nonReentrant {
    if (!s_tokenIdToMintEnabled[APPLIED_PRIMATE_ORIGINS_01_TOXIC_ID]) {
      revert ReaderTokens__NotEnabled();
    }

    uint256 badgesLength = badgeIds.length;
    uint256 keycardsLength = keycardIds.length;
    if (badgesLength == 0 && keycardsLength == 0) {
      revert ReaderTokens__MustBeGreaterThanZero();
    }

    address requester = msg.sender;
    if (vault != address(0)) {
      if (
        !s_delegationRegistry.checkDelegateForContract(
          msg.sender,
          vault,
          address(this)
        )
      ) {
        revert ReaderTokens__InvalidAddress();
      }
      requester = vault;
    }

    for (uint256 i = 0; i < badgesLength; i++) {
      if (s_studioBadgeContract.ownerOf(badgeIds[i]) != requester) {
        revert ReaderTokens__MustBeHolder();
      }
      if (
        s_tokenIdToStudioBadgeClaimed[APPLIED_PRIMATE_ORIGINS_01_TOXIC_ID][
          badgeIds[i]
        ]
      ) {
        revert ReaderTokens__AlreadyClaimed();
      }

      s_tokenIdToStudioBadgeClaimed[APPLIED_PRIMATE_ORIGINS_01_TOXIC_ID][
        badgeIds[i]
      ] = true;
    }

    for (uint256 i = 0; i < keycardsLength; i++) {
      if (s_keycardContract.ownerOf(keycardIds[i]) != requester) {
        revert ReaderTokens__MustBeHolder();
      }
      if (
        s_tokenIdToStudioBadgeClaimed[APPLIED_PRIMATE_ORIGINS_01_SILVER_ID][
          keycardIds[i]
        ]
      ) {
        revert ReaderTokens__AlreadyClaimed();
      }

      s_tokenIdToStudioBadgeClaimed[APPLIED_PRIMATE_ORIGINS_01_SILVER_ID][
        keycardIds[i]
      ] = true;
    }

    _mint(
      requester,
      APPLIED_PRIMATE_ORIGINS_01_TOXIC_ID,
      badgesLength + keycardsLength,
      ""
    );
    emit MintedToken(
      APPLIED_PRIMATE_ORIGINS_01_TOXIC_ID,
      badgesLength + keycardsLength,
      requester
    );
  }

  /**
   * @notice claim APO for studio badge holders
   * @param badgeId studio badge token ID to claim for
   * @param vault address used as a cold wallet in delegate.xyz or address(0)
   */
  function studioBadgeClaimApo(
    uint256 badgeId,
    address vault
  ) external nonReentrant {
    if (
      !(s_tokenIdToMintEnabled[APPLIED_PRIMATE_ORIGINS_01_TOXIC_ID] ||
        s_tokenIdToMintEnabled[APPLIED_PRIMATE_ORIGINS_01_ARTIST_ID] ||
        s_tokenIdToMintEnabled[APPLIED_PRIMATE_ORIGINS_01_ID])
    ) {
      revert ReaderTokens__NotEnabled();
    }
    if (
      s_tokenIdToStudioBadgeClaimed[APPLIED_PRIMATE_ORIGINS_01_ARTIST_ID][
        badgeId
      ]
    ) {
      revert ReaderTokens__AlreadyClaimed();
    }

    address requester = msg.sender;
    if (vault != address(0)) {
      if (
        !s_delegationRegistry.checkDelegateForContract(
          msg.sender,
          vault,
          address(this)
        )
      ) {
        revert ReaderTokens__InvalidAddress();
      }
      requester = vault;
    }
    if (s_studioBadgeContract.ownerOf(badgeId) != requester) {
      revert ReaderTokens__MustBeHolder();
    }
    s_tokenIdToStudioBadgeClaimed[APPLIED_PRIMATE_ORIGINS_01_ARTIST_ID][
      badgeId
    ] = true;
    _mint(requester, APPLIED_PRIMATE_ORIGINS_01_ID, 1, "");
    _mint(requester, APPLIED_PRIMATE_ORIGINS_01_ARTIST_ID, 1, "");
    emit MintedToken(APPLIED_PRIMATE_ORIGINS_01_ID, 1, requester);
    emit MintedToken(APPLIED_PRIMATE_ORIGINS_01_ARTIST_ID, 1, requester);
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
   * @notice Sets the delegation registry
   * @param delegationRegistry the delegation registry
   */
  function setDelegationRegistry(
    address delegationRegistry
  ) external onlyOwner {
    if (delegationRegistry == address(0)) {
      revert ReaderTokens__InvalidAddress();
    }
    s_delegationRegistry = IDelegationRegistry(delegationRegistry);
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
   * @dev contract addresses must be set and the token must have a price
   */
  function setTokenIdToMintEnabled(
    uint256 tokenId,
    bool enabled
  ) external onlyOwner {
    if (
      s_tokenIdToPrice[APPLIED_PRIMATE_ORIGINS_01_ARTIST_ID] == 0 ||
      s_tokenIdToPrice[APPLIED_PRIMATE_ORIGINS_01_ID] == 0
    ) {
      revert ReaderTokens__PriceCannotBeZero();
    }
    if (
      address(s_azukiContract) == address(0) ||
      address(s_beanzContract) == address(0) ||
      address(s_bobuContract) == address(0) ||
      address(s_studioBadgeContract) == address(0) ||
      address(s_biplaneBoboContract) == address(0) ||
      address(s_sentinelsContract) == address(0) ||
      address(s_keycardContract) == address(0) ||
      address(s_baycContract) == address(0) ||
      address(s_maycContract) == address(0) ||
      address(s_bakcContract) == address(0)
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

  /**
   * @notice Sets the contract addresses for holder checks
   * @param newAddresses array of addresses to set
   */
  function setApoContractAddresses(
    address[] memory newAddresses
  ) external onlyOwner {
    if (newAddresses.length != 6) {
      revert ReaderTokens__ContractsNotSet();
    }
    for (uint256 i = 0; i < newAddresses.length; i++) {
      if (newAddresses[i] == address(0)) {
        revert ReaderTokens__InvalidAddress();
      }
    }
    s_sentinelsContract = IERC721A(newAddresses[0]);
    s_keycardContract = IERC721A(newAddresses[1]);
    s_baycContract = IERC721A(newAddresses[2]);
    s_maycContract = IERC721A(newAddresses[3]);
    s_bakcContract = IERC721A(newAddresses[4]);
    s_tasteMakerzContract = IERC1155Upgradeable(newAddresses[5]);
  }

  function setURI(string memory newuri) external onlyOwner {
    if (bytes(newuri).length == 0) {
      revert ReaderTokens__InvalidAddress();
    }
    _setURI(newuri);
    emit URIUpdated(newuri);
  }

  /**
   * @notice Withdraws funds to address
   * @param addr the address to withdraw to
   */
  function withdraw(address addr) external onlyOwner {
    uint256 balance = address(this).balance;
    payable(addr).transfer(balance);
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
   * Biplane Bobo, Sentinels, Keycard, BAYC, MAYC, and BAKC contracts.
   */
  function getContractAddresses() external view returns (address[12] memory) {
    return [
      address(s_delegationRegistry),
      address(s_azukiContract),
      address(s_beanzContract),
      address(s_bobuContract),
      address(s_studioBadgeContract),
      address(s_biplaneBoboContract),
      address(s_sentinelsContract),
      address(s_keycardContract),
      address(s_baycContract),
      address(s_maycContract),
      address(s_bakcContract),
      address(s_tasteMakerzContract)
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
   * @notice Returns whether a studio badge claim has been made for a given
   * tokenId and badgeId.
   * @param tokenId the tokenId to check
   * @param badgeId the badgeId to check
   */
  function getTokenIdToStudioBadgeClaimed(
    uint256 tokenId,
    uint256 badgeId
  ) external view returns (bool) {
    return s_tokenIdToStudioBadgeClaimed[tokenId][badgeId];
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
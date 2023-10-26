// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                    
*/

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "../interfaces/IInsuranceRegistry.sol";
import "../interfaces/ITokenContract.sol";
import "../interfaces/ITokenRegistry.sol";
import "../libraries/GrtLibrary.sol";

/// @title TokenContract
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor Sean L (slongdotexe)
/// @custom:contributor mfbevan (mfbevan.eth)
/// @custom:contributor Brodie S
/// @notice Implementation to be used for the Liquid and Redeemed editions of each token
/// @dev  The GRT Wines architecture uses a dual ERC721 token system. When releases are created the `LiquidToken`
///       is minted and can be purchased through various listing mechanisms via the Drop Manager. When a user
///       wishes to redeem their token for a physical asset, the `LiquidToken` is burned, and a `RedeemedToken` is
///       minted. The same `TokenContract` implementation is deployed twice, once for each edition. The metadata
///       for both the Liquid and Redeemed editions of each token is set when a release is created, and manage by
///       the `TokenRegistry`
contract TokenContract is
  DefaultOperatorFilterer,
  ITokenContract,
  AccessControl,
  ERC721Royalty
{
  using Counters for Counters.Counter;
  using Strings for uint256;

  //#########################
  //#### STATE VARIABLES ####

  Counters.Counter private _tokenIdCounter;

  bytes32 public constant override PLATFORM_ADMIN_ROLE =
    keccak256("PLATFORM_ADMIN_ROLE");
  bytes32 public constant override MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant override BURNER_ROLE = keccak256("BURNER_ROLE");

  ITokenRegistry public override tokenRegistry;
  IInsuranceRegistry public override insuranceRegistry;
  address public override redemptionManager;

  bool public immutable useRedeemedUri;

  //#########################
  //#### IMPLEMENTATION ####

  constructor(
    string memory _name,
    string memory _symbol,
    address _platformAdmin,
    address _superUser,
    address _insuranceRegistry,
    address _tokenRegistry,
    bool _useRedeemedUri,
    address _secondaryRoyaltyReceiver,
    uint96 _secondaryRoyaltyFee
  ) ERC721(_name, _symbol) {
    GrtLibrary.checkZeroAddress(_platformAdmin, "platform admin");
    GrtLibrary.checkZeroAddress(_superUser, "super user");
    GrtLibrary.checkZeroAddress(_insuranceRegistry, "insurance registry");
    GrtLibrary.checkZeroAddress(_tokenRegistry, "token registry");
    GrtLibrary.checkZeroAddress(_secondaryRoyaltyReceiver, "secondary royalty");

    insuranceRegistry = IInsuranceRegistry(_insuranceRegistry);
    tokenRegistry = ITokenRegistry(_tokenRegistry);
    _setupRole(PLATFORM_ADMIN_ROLE, _platformAdmin);
    _setupRole(DEFAULT_ADMIN_ROLE, _superUser);
    _setRoleAdmin(MINTER_ROLE, PLATFORM_ADMIN_ROLE);
    _setRoleAdmin(BURNER_ROLE, PLATFORM_ADMIN_ROLE);

    useRedeemedUri = _useRedeemedUri;
    _setDefaultRoyalty(_secondaryRoyaltyReceiver, _secondaryRoyaltyFee);
  }

  /// @dev If either of the from or to fields are 0 address, this is a mint or burn, return early to continue without storage read
  /// @dev See @openzeppelin ERC721.sol for further details
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 /* batch size -- not used in standard ERC721 */
  ) internal view override {
    if (from == address(0) || to == address(0)) {
      return;
    }
    if (
      insuranceRegistry.checkTokenStatus(tokenId) &&
      msg.sender != redemptionManager
    ) {
      revert InsuranceEventRegistered(tokenId);
    }
  }

  /// @dev Overrides standard tokenURI method to retrieve the URI from the Token Registry based on the token type (liquid or redeemed)
  /// @param tokenId The id of the token to retrieve a URI for
  /// @return The token URI
  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    _requireMinted(tokenId);

    ITokenRegistry.TokenKey memory tokenKey = tokenRegistry.getTokenKey(
      tokenId
    );

    string memory baseURI = useRedeemedUri
      ? tokenKey.redeemedUri
      : tokenKey.liquidUri;

    uint256 tokenIndex = tokenId - tokenKey.key + 1;

    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenIndex.toString()))
        : "";
  }

  function mint(
    address receiver,
    uint128 qty,
    string memory liquidUri,
    string memory redeemedUri
  ) external override returns (uint256 mintCount) {
    bool canMint = hasRole(MINTER_ROLE, msg.sender) ||
      hasRole(PLATFORM_ADMIN_ROLE, msg.sender);
    if (!canMint) {
      revert IncorrectAccess(msg.sender);
    }
    uint256 startToken = _tokenIdCounter.current() + 1;
    for (uint16 i = 0; i < qty; i++) {
      _tokenIdCounter.increment();
      uint256 currentToken = _tokenIdCounter.current();
      _safeMint(receiver, currentToken);
    }

    tokenRegistry.addBatchMetadata(
      ITokenRegistry.TokenKey(
        liquidUri,
        redeemedUri,
        startToken,
        SafeCast.toUint16(qty),
        false
      )
    );
    return _tokenIdCounter.current();
  }

  function mintWithId(MintWithIdArgs[] calldata mintWithIdArgs)
    external
    override
  {
    if (!hasRole(MINTER_ROLE, msg.sender)) {
      revert IncorrectAccess(msg.sender);
    }
    for (uint16 i = 0; i < mintWithIdArgs.length; i++) {
      _safeMint(mintWithIdArgs[i].to, mintWithIdArgs[i].tokenId);
    }
  }

  function burn(uint256[] calldata tokens) external override {
    bool canBurn = hasRole(BURNER_ROLE, msg.sender) ||
      hasRole(PLATFORM_ADMIN_ROLE, msg.sender);
    if (!canBurn) {
      revert IncorrectAccess(msg.sender);
    }
    for (uint16 i = 0; i < tokens.length; i++) {
      _burn(tokens[i]);
    }
  }

  function changeTokenMetadata(
    uint256 batchIndex,
    string memory liquidUri,
    string memory redeemedUri
  ) external override {
    if (!hasRole(PLATFORM_ADMIN_ROLE, msg.sender)) {
      revert IncorrectAccess(msg.sender);
    }
    tokenRegistry.updateBatchMetadata(batchIndex, liquidUri, redeemedUri);
  }

  function lockTokenMetadata(uint256 batchIndex) external override {
    if (!hasRole(PLATFORM_ADMIN_ROLE, msg.sender)) {
      revert IncorrectAccess(msg.sender);
    }
    tokenRegistry.lockBatchMetadata(batchIndex);
  }

  function tokenLocked(uint256 tokenId)
    external
    view
    override
    returns (bool hasUpdated)
  {
    return tokenRegistry.getTokenKey(tokenId).locked;
  }

  function setInsuranceRegistry(address _registryAddress)
    external
    override
    onlyRole(PLATFORM_ADMIN_ROLE)
  {
    GrtLibrary.checkZeroAddress(_registryAddress, "insurance registry");
    insuranceRegistry = IInsuranceRegistry(_registryAddress);
  }

  function setRedemptionManager(address _managerAddress)
    external
    override
    onlyRole(PLATFORM_ADMIN_ROLE)
  {
    GrtLibrary.checkZeroAddress(_managerAddress, "platform manager");
    redemptionManager = _managerAddress;
  }

  function setSecondaryRoyalties(address receiver, uint96 feeNumerator)
    external
    override
    onlyRole(PLATFORM_ADMIN_ROLE)
  {
    GrtLibrary.checkZeroAddress(receiver, "secondary royalty");
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  /// @dev Due to multiple inhereted Open Zeppelin contracts implementing supportsInterface we must provide an override as
  /// below so Solidity knows how to resolve conflicted inheretence
  /// see https://github.com/OpenZeppelin/openzeppelin-contracts/issues/3107
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(IERC165, ERC721Royalty, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /// @dev Overrides required for the Operator Filter Registry
  /// see https://github.com/ProjectOpenSea/operator-filter-registry
  function setApprovalForAll(address operator, bool approved)
    public
    override(ERC721, IERC721)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
    public
    override(ERC721, IERC721)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}
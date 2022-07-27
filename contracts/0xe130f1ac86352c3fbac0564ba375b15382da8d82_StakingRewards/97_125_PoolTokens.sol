// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../external/ERC721PresetMinterPauserAutoId.sol";
import "./GoldfinchConfig.sol";
import "./ConfigHelper.sol";
import "./HasAdmin.sol";
import "./ConfigurableRoyaltyStandard.sol";
import "../../interfaces/IERC2981.sol";
import "../../interfaces/ITranchedPool.sol";
import "../../interfaces/IPoolTokens.sol";

/**
 * @title PoolTokens
 * @notice PoolTokens is an ERC721 compliant contract, which can represent
 *  junior tranche or senior tranche shares of any of the borrower pools.
 * @author Goldfinch
 */
contract PoolTokens is IPoolTokens, ERC721PresetMinterPauserAutoIdUpgradeSafe, HasAdmin, IERC2981 {
  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
  bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  struct PoolInfo {
    uint256 totalMinted;
    uint256 totalPrincipalRedeemed;
    bool created;
  }

  // tokenId => tokenInfo
  mapping(uint256 => TokenInfo) public tokens;
  // poolAddress => poolInfo
  mapping(address => PoolInfo) public pools;

  ConfigurableRoyaltyStandard.RoyaltyParams public royaltyParams;
  using ConfigurableRoyaltyStandard for ConfigurableRoyaltyStandard.RoyaltyParams;

  event TokenMinted(
    address indexed owner,
    address indexed pool,
    uint256 indexed tokenId,
    uint256 amount,
    uint256 tranche
  );

  event TokenRedeemed(
    address indexed owner,
    address indexed pool,
    uint256 indexed tokenId,
    uint256 principalRedeemed,
    uint256 interestRedeemed,
    uint256 tranche
  );

  event TokenPrincipalWithdrawn(
    address indexed owner,
    address indexed pool,
    uint256 indexed tokenId,
    uint256 principalWithdrawn,
    uint256 tranche
  );

  event TokenBurned(address indexed owner, address indexed pool, uint256 indexed tokenId);

  event GoldfinchConfigUpdated(address indexed who, address configAddress);

  event RoyaltyParamsSet(address indexed sender, address newReceiver, uint256 newRoyaltyPercent);

  /*
    We are using our own initializer function so that OZ doesn't automatically
    set owner as msg.sender. Also, it lets us set our config contract
  */
  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(address owner, GoldfinchConfig _config) external initializer {
    require(owner != address(0) && address(_config) != address(0), "Owner and config addresses cannot be empty");

    __Context_init_unchained();
    __AccessControl_init_unchained();
    __ERC165_init_unchained();
    // This is setting name and symbol of the NFT's
    __ERC721_init_unchained("Goldfinch V2 Pool Tokens", "GFI-V2-PT");
    __Pausable_init_unchained();
    __ERC721Pausable_init_unchained();

    config = _config;

    _setupRole(PAUSER_ROLE, owner);
    _setupRole(OWNER_ROLE, owner);

    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  /**
   * @notice Called by pool to create a debt position in a particular tranche and amount
   * @param params Struct containing the tranche and the amount
   * @param to The address that should own the position
   * @return tokenId The token ID (auto-incrementing integer across all pools)
   */
  function mint(MintParams calldata params, address to)
    external
    virtual
    override
    onlyPool
    whenNotPaused
    returns (uint256 tokenId)
  {
    address poolAddress = _msgSender();
    tokenId = _createToken(params, poolAddress);
    _mint(to, tokenId);
    config.getBackerRewards().setPoolTokenAccRewardsPerPrincipalDollarAtMint(_msgSender(), tokenId);
    emit TokenMinted(to, poolAddress, tokenId, params.principalAmount, params.tranche);
    return tokenId;
  }

  /**
   * @notice Updates a token to reflect the principal and interest amounts that have been redeemed.
   * @param tokenId The token id to update (must be owned by the pool calling this function)
   * @param principalRedeemed The incremental amount of principal redeemed (cannot be more than principal deposited)
   * @param interestRedeemed The incremental amount of interest redeemed
   */
  function redeem(
    uint256 tokenId,
    uint256 principalRedeemed,
    uint256 interestRedeemed
  ) external virtual override onlyPool whenNotPaused {
    TokenInfo storage token = tokens[tokenId];
    address poolAddr = token.pool;
    require(token.pool != address(0), "Invalid tokenId");
    require(_msgSender() == poolAddr, "Only the token's pool can redeem");

    PoolInfo storage pool = pools[poolAddr];
    pool.totalPrincipalRedeemed = pool.totalPrincipalRedeemed.add(principalRedeemed);
    require(pool.totalPrincipalRedeemed <= pool.totalMinted, "Cannot redeem more than we minted");

    token.principalRedeemed = token.principalRedeemed.add(principalRedeemed);
    require(
      token.principalRedeemed <= token.principalAmount,
      "Cannot redeem more than principal-deposited amount for token"
    );
    token.interestRedeemed = token.interestRedeemed.add(interestRedeemed);

    emit TokenRedeemed(ownerOf(tokenId), poolAddr, tokenId, principalRedeemed, interestRedeemed, token.tranche);
  }

  /** @notice reduce a given pool token's principalAmount and principalRedeemed by a specified amount
   *  @dev uses safemath to prevent underflow
   *  @dev this function is only intended for use as part of the v2.6.0 upgrade
   *    to rectify a bug that allowed users to create a PoolToken that had a
   *    larger amount of principal than they actually made available to the
   *    borrower.  This bug is fixed in v2.6.0 but still requires past pool tokens
   *    to have their principal redeemed and deposited to be rectified.
   *  @param tokenId id of token to decrease
   *  @param amount amount to decrease by
   */
  function reducePrincipalAmount(uint256 tokenId, uint256 amount) external onlyAdmin {
    TokenInfo storage tokenInfo = tokens[tokenId];
    tokenInfo.principalAmount = tokenInfo.principalAmount.sub(amount);
    tokenInfo.principalRedeemed = tokenInfo.principalRedeemed.sub(amount);
  }

  /**
   * @notice Decrement a token's principal amount. This is different from `redeem`, which captures changes to
   *   principal and/or interest that occur when a loan is in progress.
   * @param tokenId The token id to update (must be owned by the pool calling this function)
   * @param principalAmount The incremental amount of principal redeemed (cannot be more than principal deposited)
   */
  function withdrawPrincipal(uint256 tokenId, uint256 principalAmount)
    external
    virtual
    override
    onlyPool
    whenNotPaused
  {
    TokenInfo storage token = tokens[tokenId];
    address poolAddr = token.pool;
    require(_msgSender() == poolAddr, "Invalid sender");
    require(token.principalRedeemed == 0, "Token redeemed");
    require(token.principalAmount >= principalAmount, "Insufficient principal");

    PoolInfo storage pool = pools[poolAddr];
    pool.totalMinted = pool.totalMinted.sub(principalAmount);
    require(pool.totalPrincipalRedeemed <= pool.totalMinted, "Cannot withdraw more than redeemed");

    token.principalAmount = token.principalAmount.sub(principalAmount);

    emit TokenPrincipalWithdrawn(ownerOf(tokenId), poolAddr, tokenId, principalAmount, token.tranche);
  }

  /**
   * @dev Burns a specific ERC721 token, and removes the data from our mappings
   * @param tokenId uint256 id of the ERC721 token to be burned.
   */
  function burn(uint256 tokenId) external virtual override whenNotPaused {
    TokenInfo memory token = _getTokenInfo(tokenId);
    bool canBurn = _isApprovedOrOwner(_msgSender(), tokenId);
    bool fromTokenPool = _validPool(_msgSender()) && token.pool == _msgSender();
    address owner = ownerOf(tokenId);
    require(canBurn || fromTokenPool, "ERC721Burnable: caller cannot burn this token");
    require(token.principalRedeemed == token.principalAmount, "Can only burn fully redeemed tokens");
    _destroyAndBurn(tokenId);
    emit TokenBurned(owner, token.pool, tokenId);
  }

  function getTokenInfo(uint256 tokenId) external view virtual override returns (TokenInfo memory) {
    return _getTokenInfo(tokenId);
  }

  /**
   * @notice Called by the GoldfinchFactory to register the pool as a valid pool. Only valid pools can mint/redeem
   * tokens
   * @param newPool The address of the newly created pool
   */
  function onPoolCreated(address newPool) external override onlyGoldfinchFactory {
    pools[newPool].created = true;
  }

  /**
   * @notice Returns a boolean representing whether the spender is the owner or the approved spender of the token
   * @param spender The address to check
   * @param tokenId The token id to check for
   * @return True if approved to redeem/transfer/burn the token, false if not
   */
  function isApprovedOrOwner(address spender, uint256 tokenId) external view override returns (bool) {
    return _isApprovedOrOwner(spender, tokenId);
  }

  function validPool(address sender) public view virtual override returns (bool) {
    return _validPool(sender);
  }

  function _createToken(MintParams calldata params, address poolAddress) internal returns (uint256 tokenId) {
    PoolInfo storage pool = pools[poolAddress];

    _tokenIdTracker.increment();
    tokenId = _tokenIdTracker.current();
    tokens[tokenId] = TokenInfo({
      pool: poolAddress,
      tranche: params.tranche,
      principalAmount: params.principalAmount,
      principalRedeemed: 0,
      interestRedeemed: 0
    });
    pool.totalMinted = pool.totalMinted.add(params.principalAmount);
    return tokenId;
  }

  function _destroyAndBurn(uint256 tokenId) internal {
    delete tokens[tokenId];
    _burn(tokenId);
  }

  function _validPool(address poolAddress) internal view virtual returns (bool) {
    return pools[poolAddress].created;
  }

  function _getTokenInfo(uint256 tokenId) internal view returns (TokenInfo memory) {
    return tokens[tokenId];
  }

  /// @notice Called with the sale price to determine how much royalty
  //    is owed and to whom.
  /// @param _tokenId The NFT asset queried for royalty information
  /// @param _salePrice The sale price of the NFT asset specified by _tokenId
  /// @return receiver Address that should receive royalties
  /// @return royaltyAmount The royalty payment amount for _salePrice
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address, uint256) {
    return royaltyParams.royaltyInfo(_tokenId, _salePrice);
  }

  /// @notice Set royalty params used in `royaltyInfo`. This function is only callable by
  ///   an address with `OWNER_ROLE`.
  /// @param newReceiver The new address which should receive royalties. See `receiver`.
  /// @param newRoyaltyPercent The new percent of `salePrice` that should be taken for royalties.
  ///   See `royaltyPercent`.
  function setRoyaltyParams(address newReceiver, uint256 newRoyaltyPercent) external onlyAdmin {
    royaltyParams.setRoyaltyParams(newReceiver, newRoyaltyPercent);
  }

  function setBaseURI(string calldata baseURI_) external onlyAdmin {
    _setBaseURI(baseURI_);
  }

  function supportsInterface(bytes4 id) public view override(ERC165UpgradeSafe, IERC165) returns (bool) {
    return (id == _INTERFACE_ID_ERC721 ||
      id == _INTERFACE_ID_ERC721_METADATA ||
      id == _INTERFACE_ID_ERC721_ENUMERABLE ||
      id == _INTERFACE_ID_ERC165 ||
      id == ConfigurableRoyaltyStandard._INTERFACE_ID_ERC2981);
  }

  modifier onlyGoldfinchFactory() {
    require(_msgSender() == config.goldfinchFactoryAddress(), "Only Goldfinch factory is allowed");
    _;
  }

  modifier onlyPool() {
    require(_validPool(_msgSender()), "Invalid pool!");
    _;
  }
}
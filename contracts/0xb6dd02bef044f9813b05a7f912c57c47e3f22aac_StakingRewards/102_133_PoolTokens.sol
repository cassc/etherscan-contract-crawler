// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ERC721PresetMinterPauserAutoIdUpgradeSafe} from "../../external/ERC721PresetMinterPauserAutoId.sol";
import {ERC165UpgradeSafe} from "../../external/ERC721PresetMinterPauserAutoId.sol";
import {IERC165} from "../../external/ERC721PresetMinterPauserAutoId.sol";
import {GoldfinchConfig} from "./GoldfinchConfig.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {HasAdmin} from "./HasAdmin.sol";
import {ConfigurableRoyaltyStandard} from "./ConfigurableRoyaltyStandard.sol";
import {IERC2981} from "../../interfaces/IERC2981.sol";
import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";
import {IPoolTokens} from "../../interfaces/IPoolTokens.sol";
import {IBackerRewards} from "../../interfaces/IBackerRewards.sol";

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

  // tokenId => tokenInfo
  mapping(uint256 => TokenInfo) public tokens;
  // poolAddress => poolInfo
  mapping(address => PoolInfo) public pools;

  ConfigurableRoyaltyStandard.RoyaltyParams public royaltyParams;
  using ConfigurableRoyaltyStandard for ConfigurableRoyaltyStandard.RoyaltyParams;

  /*
    We are using our own initializer function so that OZ doesn't automatically
    set owner as msg.sender. Also, it lets us set our config contract
  */
  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(address owner, GoldfinchConfig _config) external initializer {
    require(
      owner != address(0) && address(_config) != address(0),
      "Owner and config addresses cannot be empty"
    );

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

  /// @inheritdoc IPoolTokens
  function mint(
    MintParams calldata params,
    address to
  ) external virtual override onlyPool whenNotPaused returns (uint256 tokenId) {
    address poolAddress = _msgSender();

    PoolInfo storage pool = pools[poolAddress];
    pool.totalMinted = pool.totalMinted.add(params.principalAmount);

    tokenId = _createToken({
      principalAmount: params.principalAmount,
      tranche: params.tranche,
      principalRedeemed: 0,
      interestRedeemed: 0,
      poolAddress: poolAddress,
      mintTo: to
    });

    config.getBackerRewards().setPoolTokenAccRewardsPerPrincipalDollarAtMint(_msgSender(), tokenId);
  }

  /// @inheritdoc IPoolTokens
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

    emit TokenRedeemed(
      ownerOf(tokenId),
      poolAddr,
      tokenId,
      principalRedeemed,
      interestRedeemed,
      token.tranche
    );
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

  /// @inheritdoc IPoolTokens
  function withdrawPrincipal(
    uint256 tokenId,
    uint256 principalAmount
  ) external virtual override onlyPool whenNotPaused {
    TokenInfo storage token = tokens[tokenId];
    address poolAddr = token.pool;
    require(_msgSender() == poolAddr, "Invalid sender");
    require(token.principalRedeemed == 0, "Token redeemed");
    require(token.principalAmount >= principalAmount, "Insufficient principal");

    PoolInfo storage pool = pools[poolAddr];
    pool.totalMinted = pool.totalMinted.sub(principalAmount);
    require(pool.totalPrincipalRedeemed <= pool.totalMinted, "Cannot withdraw more than redeemed");

    token.principalAmount = token.principalAmount.sub(principalAmount);

    emit TokenPrincipalWithdrawn(
      ownerOf(tokenId),
      poolAddr,
      tokenId,
      principalAmount,
      token.tranche
    );
  }

  /// @inheritdoc IPoolTokens
  function burn(uint256 tokenId) external virtual override whenNotPaused {
    TokenInfo memory token = _getTokenInfo(tokenId);
    bool canBurn = _isApprovedOrOwner(_msgSender(), tokenId);
    bool fromTokenPool = _validPool(_msgSender()) && token.pool == _msgSender();
    address owner = ownerOf(tokenId);
    require(canBurn || fromTokenPool, "ERC721Burnable: caller cannot burn this token");
    require(
      token.principalRedeemed == token.principalAmount,
      "Can only burn fully redeemed tokens"
    );
    // If we let you burn with claimable backer rewards then it would blackhole your rewards,
    // so you must claim all rewards before burning
    require(config.getBackerRewards().poolTokenClaimableRewards(tokenId) == 0, "rewards>0");
    _destroyAndBurn(owner, address(token.pool), tokenId);
  }

  function getTokenInfo(uint256 tokenId) external view virtual override returns (TokenInfo memory) {
    return _getTokenInfo(tokenId);
  }

  function getPoolInfo(address pool) external view override returns (PoolInfo memory) {
    return pools[pool];
  }

  /// @inheritdoc IPoolTokens
  function onPoolCreated(address newPool) external override onlyGoldfinchFactory {
    pools[newPool].created = true;
  }

  /**
   * @notice Returns a boolean representing whether the spender is the owner or the approved spender of the token
   * @param spender The address to check
   * @param tokenId The token id to check for
   * @return True if approved to redeem/transfer/burn the token, false if not
   */
  function isApprovedOrOwner(
    address spender,
    uint256 tokenId
  ) external view override returns (bool) {
    return _isApprovedOrOwner(spender, tokenId);
  }

  /**
   * @inheritdoc IPoolTokens
   * @dev NA: Not Authorized
   * @dev IA: Invalid Amount - newPrincipal1 not in range (0, principalAmount)
   */
  function splitToken(
    uint256 tokenId,
    uint256 newPrincipal1
  ) external override returns (uint256 tokenId1, uint256 tokenId2) {
    require(_isApprovedOrOwner(msg.sender, tokenId), "NA");
    TokenInfo memory tokenInfo = _getTokenInfo(tokenId);
    require(0 < newPrincipal1 && newPrincipal1 < tokenInfo.principalAmount, "IA");

    IBackerRewards.BackerRewardsTokenInfo memory backerRewardsTokenInfo = config
      .getBackerRewards()
      .getTokenInfo(tokenId);

    IBackerRewards.StakingRewardsTokenInfo memory backerStakingRewardsTokenInfo = config
      .getBackerRewards()
      .getStakingRewardsTokenInfo(tokenId);

    // Burn the original token before calling out to other contracts to prevent possible reentrancy attacks.
    // A reentrancy guard on this function alone is insufficient because someone may be able to reenter the
    // protocol through a different contract that reads pool token metadata. Following checks-effects-interactions
    // here leads to a clunky implementation (fn's with many params) but guarding against potential reentrancy
    // is more important.
    address tokenOwner = ownerOf(tokenId);
    _destroyAndBurn(tokenOwner, address(tokenInfo.pool), tokenId);

    (tokenId1, tokenId2) = _createSplitTokens(tokenInfo, tokenOwner, newPrincipal1);
    _setBackerRewardsForSplitTokens(
      tokenInfo,
      backerRewardsTokenInfo,
      backerStakingRewardsTokenInfo,
      tokenId1,
      tokenId2,
      newPrincipal1
    );

    emit TokenSplit({
      owner: tokenOwner,
      pool: tokenInfo.pool,
      tokenId: tokenId,
      newTokenId1: tokenId1,
      newPrincipal1: newPrincipal1,
      newTokenId2: tokenId2,
      newPrincipal2: tokenInfo.principalAmount.sub(newPrincipal1)
    });
  }

  /// @notice Initialize the backer rewards metadata for split tokens
  function _setBackerRewardsForSplitTokens(
    TokenInfo memory tokenInfo,
    IBackerRewards.BackerRewardsTokenInfo memory backerRewardsTokenInfo,
    IBackerRewards.StakingRewardsTokenInfo memory stakingRewardsTokenInfo,
    uint256 newTokenId1,
    uint256 newTokenId2,
    uint256 newPrincipal1
  ) internal {
    uint256 rewardsClaimed1 = backerRewardsTokenInfo.rewardsClaimed.mul(newPrincipal1).div(
      tokenInfo.principalAmount
    );

    config.getBackerRewards().setBackerAndStakingRewardsTokenInfoOnSplit({
      originalBackerRewardsTokenInfo: backerRewardsTokenInfo,
      originalStakingRewardsTokenInfo: stakingRewardsTokenInfo,
      newTokenId: newTokenId1,
      newRewardsClaimed: rewardsClaimed1
    });

    config.getBackerRewards().setBackerAndStakingRewardsTokenInfoOnSplit({
      originalBackerRewardsTokenInfo: backerRewardsTokenInfo,
      originalStakingRewardsTokenInfo: stakingRewardsTokenInfo,
      newTokenId: newTokenId2,
      newRewardsClaimed: backerRewardsTokenInfo.rewardsClaimed.sub(rewardsClaimed1)
    });
  }

  /// @notice Split tokenId into two new tokens. Assumes that newPrincipal1 is valid for the token's principalAmount
  function _createSplitTokens(
    TokenInfo memory tokenInfo,
    address tokenOwner,
    uint256 newPrincipal1
  ) internal returns (uint256 newTokenId1, uint256 newTokenId2) {
    // All new vals are proportional to the new token's principal
    uint256 principalRedeemed1 = tokenInfo.principalRedeemed.mul(newPrincipal1).div(
      tokenInfo.principalAmount
    );
    uint256 interestRedeemed1 = tokenInfo.interestRedeemed.mul(newPrincipal1).div(
      tokenInfo.principalAmount
    );

    newTokenId1 = _createToken(
      newPrincipal1,
      tokenInfo.tranche,
      principalRedeemed1,
      interestRedeemed1,
      tokenInfo.pool,
      tokenOwner
    );

    newTokenId2 = _createToken(
      tokenInfo.principalAmount.sub(newPrincipal1),
      tokenInfo.tranche,
      tokenInfo.principalRedeemed.sub(principalRedeemed1),
      tokenInfo.interestRedeemed.sub(interestRedeemed1),
      tokenInfo.pool,
      tokenOwner
    );
  }

  /// @inheritdoc IPoolTokens
  function validPool(address sender) public view virtual override returns (bool) {
    return _validPool(sender);
  }

  /**
   * @notice Mint the token and save its metadata to storage
   * @param principalAmount token principal
   * @param tranche tranche of the pool to which the token belongs
   * @param principalRedeemed amount of principal already redeemed for the token. This is
   *  0 for tokens created from a deposit, and could be non-zero for tokens created from a split
   * @param interestRedeemed amount of interest already redeemed for the token. This is
   *  0 for tokens created from a deposit, and could be non-zero for tokens created from a split
   * @param poolAddress pool to which the token belongs
   * @param mintTo the token owner
   * @return tokenId id of the created token
   */
  function _createToken(
    uint256 principalAmount,
    uint256 tranche,
    uint256 principalRedeemed,
    uint256 interestRedeemed,
    address poolAddress,
    address mintTo
  ) internal returns (uint256 tokenId) {
    _tokenIdTracker.increment();
    tokenId = _tokenIdTracker.current();

    tokens[tokenId] = TokenInfo({
      pool: poolAddress,
      tranche: tranche,
      principalAmount: principalAmount,
      principalRedeemed: principalRedeemed,
      interestRedeemed: interestRedeemed
    });

    _mint(mintTo, tokenId);

    emit TokenMinted({
      owner: mintTo,
      pool: poolAddress,
      tokenId: tokenId,
      amount: principalAmount,
      tranche: tranche
    });
  }

  function _destroyAndBurn(address owner, address pool, uint256 tokenId) internal {
    delete tokens[tokenId];
    _burn(tokenId);
    config.getBackerRewards().clearTokenInfo(tokenId);
    emit TokenBurned(owner, pool, tokenId);
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
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view override returns (address, uint256) {
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

  function supportsInterface(
    bytes4 id
  ) public view override(ERC165UpgradeSafe, IERC165) returns (bool) {
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
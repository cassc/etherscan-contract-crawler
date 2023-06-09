// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../../goldfinch/interfaces/ITranchedPool.sol";
import "../../goldfinch/interfaces/IPoolTokens.sol";
import "../interfaces/IGoldfinchDesk.sol";
import "../config/ConfigHelper.sol";
import "../config/AlloyxConfig.sol";
import "../utils/AdminUpgradeable.sol";

/**
 * @title GoldfinchDesk
 * @notice All transactions or statistics related to Goldfinch
 * @author AlloyX
 */
contract GoldfinchDesk is IGoldfinchDesk, AdminUpgradeable, ERC721HolderUpgradeable {
  using SafeMath for uint256;
  using ConfigHelper for AlloyxConfig;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeERC20Upgradeable for IERC20Token;
  using EnumerableSet for EnumerableSet.UintSet;

  AlloyxConfig public config;
  // Alloyx Pool => tokenId
  mapping(address => EnumerableSet.UintSet) internal vaultToTokenIds;
  // Alloyx Pool => Fidu Amount
  mapping(address => uint256) internal vaultToFidu;

  event PurchaseSenior(uint256 amount);
  event Mint(address _tokenReceiver, uint256 _tokenAmount);
  event Burn(address _tokenReceiver, uint256 _tokenAmount);
  event DepositDURA(address _tokenSender, uint256 _duraAmount, uint256 _usdcAmount, uint256 _fee);
  event TransferUSDC(address _to, uint256 _amount);
  event WithdrawPoolTokens(address _withdrawer, uint256 _tokenID);
  event DepositPoolTokens(address _depositor, uint256 _tokenID);
  event PurchasePoolTokensByUSDC(uint256 _amount);
  event PurchaseFiduByUsdc(uint256 _amount);
  event SellFIDU(uint256 _amount);
  event WithdrawPoolTokenByUSDCAmount(address indexed _vaultAddress, uint256 _amount);
  event AlloyxConfigUpdated(address indexed who, address configAddress);
  event WithdrawGfiFromPoolTokens(address indexed _vaultAddress, uint256 _tokenID);

  /**
   * @notice Initialize the contract
   * @param _configAddress the address of configuration contract
   */
  function initialize(address _configAddress) external initializer {
    __AdminUpgradeable_init(msg.sender);
    config = AlloyxConfig(_configAddress);
  }

  /**
   * @notice If user operation is paused
   */
  modifier isPaused() {
    require(config.isPaused(), "all user operations should be paused");
    _;
  }

  /**
   * @notice If the transaction is triggered from operator contract
   */
  modifier onlyOperator() {
    require(msg.sender == config.operatorAddress(), "only operator");
    _;
  }

  /**
   * @notice Update configuration contract address
   */
  function updateConfig() external onlyAdmin isPaused {
    config = AlloyxConfig(config.configAddress());
    emit AlloyxConfigUpdated(msg.sender, address(config));
  }

  /**
   * @notice Purchase pool token to get pooltoken
   * @param _vaultAddress the vault address
   * @param _amount the amount of usdc to purchase by
   * @param _poolAddress the pool address to buy from
   * @param _tranche the tranch id
   */
  function purchasePoolToken(
    address _vaultAddress,
    uint256 _amount,
    address _poolAddress,
    uint256 _tranche
  ) public override onlyOperator {
    ITranchedPool juniorPool = ITranchedPool(_poolAddress);
    config.getUSDC().approve(_poolAddress, _amount);
    uint256 tokenID = juniorPool.deposit(_tranche, _amount);
    vaultToTokenIds[_vaultAddress].add(tokenID);
    emit PurchasePoolTokensByUSDC(_amount);
  }

  /**
   * @notice Widthdraw from junior token to get repayments
   * @param _vaultAddress the vault address
   * @param _tokenID the ID of token to sell
   * @param _amount the amount to withdraw
   * @param _poolAddress the pool address to withdraw from
   */
  function withdrawFromJuniorToken(
    address _vaultAddress,
    uint256 _tokenID,
    uint256 _amount,
    address _poolAddress
  ) external override onlyOperator {
    require(vaultToTokenIds[_vaultAddress].contains(_tokenID), "the tokenID does not belong to this vault");
    ITranchedPool juniorPool = ITranchedPool(_poolAddress);
    (uint256 principal, uint256 interest) = juniorPool.withdraw(_tokenID, _amount);
    withdrawGfiFromMultiplePoolTokens(_tokenID);
    config.getUSDC().safeTransfer(_vaultAddress, principal.add(interest));
    emit WithdrawPoolTokenByUSDCAmount(_vaultAddress, principal.add(interest));
  }

  /**
   * @notice Widthdraw GFI from pool token
   * @param _tokenID the ID of token to sell
   */
  function withdrawGfiFromMultiplePoolTokens(uint256 _tokenID) internal {
    config.getBackerRewards().withdraw(_tokenID);
    uint256 usdcFromGfi = convertGfiToUsdc();
    config.getUSDC().safeTransfer(msg.sender, usdcFromGfi);
    emit WithdrawGfiFromPoolTokens(msg.sender, _tokenID);
  }

  /**
   * @notice Claim the reward tokens and convert back to USDC
   */
  function convertGfiToUsdc() internal returns (uint256) {
    uniswapSingle(config.gfiAddress(), config.wethAddress(), config.getGFI().balanceOf(address(this)), 0, uint24(config.getUniswapFeeBasePoint()));
    uint256 usdcAmount = uniswapSingle(config.wethAddress(), config.usdcAddress(), config.getWETH().balanceOf(address(this)), 0, uint24(config.getUniswapFeeBasePoint()));
    return usdcAmount;
  }

  /**
   * @notice Use uniswap to swap token
   * @param _tokenIn the token address to swap from
   * @param _tokenOut the token address to swap to
   * @param _amountIn the amount of tokens to convert from
   * @param _amountOutMin the min amount of output tokens
   * @param _poolFee normally set to 3000 which is 0.3%
   */
  function uniswapSingle(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _amountOutMin,
    uint24 _poolFee
  ) internal returns (uint256 amountOut) {
    // approve router to spend tokenIn
    IERC20Upgradeable(_tokenIn).safeApprove(config.swapRouterAddress(), _amountIn);
    // swap input params
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
      tokenIn: _tokenIn,
      tokenOut: _tokenOut,
      fee: _poolFee,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: _amountIn,
      amountOutMinimum: _amountOutMin,
      sqrtPriceLimitX96: 0
    });
    amountOut = config.getSwapRouter().exactInputSingle(params);
  }

  /**
   * @notice Purchase FIDU
   * @param _vaultAddress the vault address
   * @param _amount the amount of usdc to purchase by
   */
  function purchaseFIDU(address _vaultAddress, uint256 _amount) external override onlyOperator {
    config.getUSDC().approve(config.seniorPoolAddress(), _amount);
    uint256 fiduAmount = config.getSeniorPool().deposit(_amount);
    vaultToFidu[_vaultAddress] = vaultToFidu[_vaultAddress].add(fiduAmount);
    emit PurchaseFiduByUsdc(_amount);
  }

  /**
   * @notice Sell senior token to redeem FIDU
   * @param _vaultAddress the vault address
   * @param _amount the amount of FIDU to sell
   */
  function sellFIDU(address _vaultAddress, uint256 _amount) external override onlyOperator {
    require(vaultToFidu[_vaultAddress] >= _amount, "vault does not have sufficient FIDU");
    uint256 usdcAmount = config.getSeniorPool().withdrawInFidu(_amount);
    config.getUSDC().safeTransfer(_vaultAddress, usdcAmount);
    vaultToFidu[_vaultAddress] = vaultToFidu[_vaultAddress].sub(_amount);
    emit SellFIDU(_amount);
  }

  /**
   * @notice Using the Goldfinch contracts, read the principal, redeemed and redeemable values
   * @param _tokenID The backer NFT id
   */
  function getJuniorTokenValue(uint256 _tokenID) public view override returns (uint256) {
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(_tokenID);
    // now get the redeemable values for the given token
    address tranchedPoolAddress = tokenInfo.pool;
    ITranchedPool tranchedTokenContract = ITranchedPool(tranchedPoolAddress);
    (uint256 interestRedeemable, ) = tranchedTokenContract.availableToWithdraw(_tokenID);
    return tokenInfo.principalAmount.add(interestRedeemable).sub(tokenInfo.principalRedeemed);
  }

  /**
   * @notice GoldFinch PoolToken Value in Value in term of USDC
   * @param _vaultAddress the vault address of which we calculate the balance
   */
  function getGoldFinchPoolTokenBalanceInUsdc(address _vaultAddress) external view override returns (uint256) {
    uint256 total = 0;
    EnumerableSet.UintSet storage tokenIds = vaultToTokenIds[_vaultAddress];
    for (uint256 i = 0; i < tokenIds.length(); i++) {
      uint256 tokenId = tokenIds.at(i);
      total = total.add(getJuniorTokenValue(tokenIds.at(i)));
    }
    return total;
  }

  /**
   * @notice GoldFinch PoolToken IDs
   * @param _vaultAddress the vault address of which we calculate the balance
   */
  function getGoldFinchPoolTokenIds(address _vaultAddress) external view override returns (uint256[] memory) {
    EnumerableSet.UintSet storage tokenIds = vaultToTokenIds[_vaultAddress];
    return tokenIds.values();
  }

  /**
   * @notice GoldFinch PoolToken Value in Value in term of USDC
   * @param _vaultAddress the vault address of which we calculate the balance
   * @param _poolAddress the pool address of which we calculate the balance
   * @param _tranche the tranche
   */
  function getGoldFinchPoolTokenBalanceInUsdcForPool(
    address _vaultAddress,
    address _poolAddress,
    uint256 _tranche
  ) external view override returns (uint256) {
    uint256 total = 0;
    EnumerableSet.UintSet storage tokenIds = vaultToTokenIds[_vaultAddress];
    for (uint256 i = 0; i < tokenIds.length(); i++) {
      uint256 tokenId = tokenIds.at(i);
      IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
      if (tokenInfo.tranche == _tranche && tokenInfo.pool == _poolAddress) {
        total = total.add(getJuniorTokenValue(tokenIds.at(i)));
      }
    }
    return total;
  }

  /**
   * @notice Widthdraw GFI from pool token
   * @param _vaultAddress the vault address
   * @param _tokenIDs the IDs of token to sell
   */
  function withdrawGfiFromMultiplePoolTokens(address _vaultAddress, uint256[] calldata _tokenIDs) external override onlyOperator {
    config.getBackerRewards().withdrawMultiple(_tokenIDs);
    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      config.getPoolTokens().safeTransferFrom(address(this), config.treasuryAddress(), _tokenIDs[i]);
    }
    config.getGFI().safeTransfer(config.treasuryAddress(), config.getGFI().balanceOf(address(this)));
    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      emit WithdrawGfiFromPoolTokens(_vaultAddress, _tokenIDs[i]);
    }
  }

  /**
   * @notice Fidu Value in Vault in term of USDC
   * @param _vaultAddress the pool address of which we calculate the balance
   */
  function getFiduBalanceInUsdc(address _vaultAddress) public view override returns (uint256) {
    return fiduToUsdc(vaultToFidu[_vaultAddress].mul(config.getSeniorPool().sharePrice()).div(fiduMantissa()));
  }

  /**
   * @notice Fidu Balance in Vault
   * @param _vaultAddress the pool address of which we calculate the balance
   */
  function getFiduBalance(address _vaultAddress) public view override returns (uint256) {
    return vaultToFidu[_vaultAddress];
  }

  /**
   * @notice Convert FIDU coins to USDC
   */
  function fiduToUsdc(uint256 amount) internal pure returns (uint256) {
    return amount.div(fiduMantissa().div(usdcMantissa()));
  }

  /**
   * @notice Fidu mantissa with 18 decimals
   */
  function fiduMantissa() internal pure returns (uint256) {
    return uint256(10)**uint256(18);
  }

  /**
   * @notice USDC mantissa with 6 decimals
   */
  function usdcMantissa() internal pure returns (uint256) {
    return uint256(10)**uint256(6);
  }
}
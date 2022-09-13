// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "../goldfinch/interfaces/ITranchedPool.sol";
import "../goldfinch/interfaces/IPoolTokens.sol";
import "./interfaces/IGoldfinchDesk.sol";
import "./ConfigHelper.sol";
import "./AlloyxConfig.sol";
import "./AdminUpgradeable.sol";

/**
 * @title GoldfinchDesk
 * @notice All transactions or statistics related to Goldfinch
 * @author AlloyX
 */
contract GoldfinchDesk is IGoldfinchDesk, AdminUpgradeable, ERC721HolderUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMath for uint256;

  AlloyxConfig public config;
  using ConfigHelper for AlloyxConfig;

  event PurchaseSenior(uint256 amount);
  event Mint(address _tokenReceiver, uint256 _tokenAmount);
  event Burn(address _tokenReceiver, uint256 _tokenAmount);
  event DepositDURA(address _tokenSender, uint256 _tokenAmount);
  event TransferUSDC(address _to, uint256 _amount);
  event WithdrawPoolTokens(address _withdrawer, uint256 _tokenID);
  event DepositPoolTokens(address _depositor, uint256 _tokenID);
  event PurchasePoolTokensByUSDC(uint256 _amount);
  event PurchaseFiduByUsdc(uint256 _amount);
  event Stake(address _staker, uint256 _amount);
  event SellFIDU(uint256 _amount);
  event WithdrawPoolTokenByUSDCAmount(uint256 _amount);
  event AlloyxConfigUpdated(address indexed who, address configAddress);

  mapping(uint256 => address) tokenDepositorMap;

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
   * @notice If operation is not paused
   */
  modifier notPaused() {
    require(!config.isPaused(), "the user operation should be unpaused first");
    _;
  }

  /**
   * @notice If address is whitelisted
   * @param _address The address to verify.
   */
  modifier isWhitelisted(address _address) {
    require(config.getWhitelist().isUserWhitelisted(_address), "user is not whitelisted");
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
   * @notice An Alloy token holder can deposit their tokens and buy FIDU
   * @param _tokenAmount Number of Alloy Tokens
   */
  function depositDuraForFidu(uint256 _tokenAmount) external isWhitelisted(msg.sender) notPaused {
    uint256 amountToWithdraw = config.getExchange().alloyxDuraToUsdc(_tokenAmount);
    uint256 withdrawalFee = amountToWithdraw.mul(config.getPermillageDuraToFiduFee()).div(1000);
    uint256 totalUsdcValueOfFidu = amountToWithdraw.sub(withdrawalFee);
    config.getDURA().burn(msg.sender, _tokenAmount);
    config.getTreasury().addDuraToFiduFee(withdrawalFee);
    config.getTreasury().transferERC20(config.usdcAddress(), address(this), totalUsdcValueOfFidu);
    config.getUSDC().approve(config.seniorPoolAddress(), totalUsdcValueOfFidu);
    uint256 fiduAmount = config.getSeniorPool().deposit(totalUsdcValueOfFidu);
    config.getFIDU().safeTransfer(msg.sender, fiduAmount);
    emit PurchaseSenior(fiduAmount);
    emit DepositDURA(msg.sender, _tokenAmount);
    emit Burn(msg.sender, _tokenAmount);
  }

  /**
   * @notice An Alloy token holder can deposit their tokens and buy back their previously deposited Pooltoken
   * @param _tokenId Pooltoken of ID
   */
  function depositDuraForPoolToken(uint256 _tokenId) external isWhitelisted(msg.sender) notPaused {
    uint256 purchaseAmount = getJuniorTokenValue(_tokenId);
    uint256 withdrawalFee = purchaseAmount.mul(config.getPermillageJuniorRedemption()).div(1000);
    uint256 duraAmount = config.getExchange().usdcToAlloyxDura(purchaseAmount.add(withdrawalFee));
    config.getTreasury().addRedemptionFee(withdrawalFee);
    config.getDURA().burn(msg.sender, duraAmount);
    transferTokenToDepositor(msg.sender, _tokenId);
    emit Burn(msg.sender, duraAmount);
    emit DepositDURA(msg.sender, duraAmount);
    emit WithdrawPoolTokens(msg.sender, _tokenId);
  }

  /**
   * @notice A Junior token holder can deposit their NFT for dura
   * @param _tokenID NFT ID
   * @param _toStake whether to stake the dura
   */
  function depositPoolTokenForDura(uint256 _tokenID, bool _toStake)
    external
    isWhitelisted(msg.sender)
    notPaused
  {
    require(isValidPool(_tokenID) == true, "Not a valid pool");
    uint256 purchasePrice = getJuniorTokenValue(_tokenID);
    uint256 amountToMint = config.getExchange().usdcToAlloyxDura(purchasePrice);
    config.getTreasury().transferERC721From(
      msg.sender,
      config.poolTokensAddress(),
      config.treasuryAddress(),
      _tokenID
    );
    tokenDepositorMap[_tokenID] = msg.sender;
    if (_toStake) {
      config.getDURA().mint(config.treasuryAddress(), amountToMint);
      config.getAlloyxStakeInfo().addStake(msg.sender, amountToMint);
      emit Mint(config.treasuryAddress(), amountToMint);
      emit Stake(msg.sender, amountToMint);
    } else {
      config.getDURA().mint(msg.sender, amountToMint);
      emit Mint(msg.sender, amountToMint);
    }
    emit DepositPoolTokens(msg.sender, _tokenID);
  }

  /**
   * @notice A Junior token holder can deposit their NFT for stable coin
   * @param _tokenID NFT ID
   */
  function depositPoolTokensForUsdc(uint256 _tokenID) external isWhitelisted(msg.sender) notPaused {
    require(isValidPool(_tokenID) == true, "Not a valid pool");
    uint256 purchasePrice = getJuniorTokenValue(_tokenID);
    tokenDepositorMap[_tokenID] = msg.sender;
    config.getTreasury().transferERC721From(
      msg.sender,
      config.poolTokensAddress(),
      config.treasuryAddress(),
      _tokenID
    );
    config.getTreasury().transferERC20(config.usdcAddress(), msg.sender, purchasePrice);
    emit DepositPoolTokens(msg.sender, _tokenID);
    emit TransferUSDC(msg.sender, purchasePrice);
  }

  /**
   * @notice Purchase pool token to get pooltoken
   * @param _amount the amount of usdc to purchase by
   * @param _poolAddress the pool address to buy from
   * @param _tranche the tranch id
   */
  function purchasePoolToken(
    uint256 _amount,
    address _poolAddress,
    uint256 _tranche
  ) public onlyAdmin {
    require(_poolAddress != address(0));
    ITranchedPool juniorPool = ITranchedPool(_poolAddress);
    config.getTreasury().transferERC20(config.usdcAddress(), address(this), _amount);
    config.getUSDC().approve(_poolAddress, _amount);
    uint256 tokenID = juniorPool.deposit(_amount, _tranche);
    config.getPoolTokens().safeTransferFrom(address(this), config.treasuryAddress(), tokenID);
    emit PurchasePoolTokensByUSDC(_amount);
  }

  /**
   * @notice Purchase pool token when usdc is beyond threshold
   */
  function purchaseJuniorTokenBeyondUsdcThreshold() external onlyAdmin {
    uint256 totalValue = config.getExchange().getTreasuryTotalBalanceInUsdc();
    uint256 totalUsdcFee = config.getTreasury().getAllUsdcFees();
    require(
      totalValue.sub(totalUsdcFee).mul(1000).div(totalValue) > config.getPermillageInvestJunior(),
      "usdc token must reach certain permillage"
    );
    purchasePoolTokenOnBestTranch(totalValue.sub(totalUsdcFee));
  }

  /**
   * @notice Purchase pool token on the best tranch
   * @param _amount the amount of usdc to purchase with
   */
  function purchasePoolTokenOnBestTranch(uint256 _amount) public onlyAdmin {
    address tranchAddress = config.getSortedGoldfinchTranches().getTop(1)[0];
    purchasePoolToken(_amount, tranchAddress, 1);
  }

  /**
   * @notice Widthdraw from junior token to get repayments
   * @param _tokenID the ID of token to sell
   * @param _amount the amount to withdraw
   * @param _poolAddress the pool address to withdraw from
   */
  function withdrawFromJuniorToken(
    uint256 _tokenID,
    uint256 _amount,
    address _poolAddress
  ) external onlyAdmin {
    require(_poolAddress != address(0));
    ITranchedPool juniorPool = ITranchedPool(_poolAddress);
    config.getTreasury().transferERC721(config.poolTokensAddress(), address(this), _tokenID);
    (uint256 principal, uint256 interest) = juniorPool.withdraw(_tokenID, _amount);
    uint256 fee = principal.add(interest).mul(config.getPermillageDuraRepayment()).div(1000);
    config.getTreasury().addRepaymentFee(fee);
    config.getPoolTokens().safeTransferFrom(address(this), config.treasuryAddress(), _tokenID);
    config.getUSDC().safeTransfer(config.treasuryAddress(), _amount);
    emit WithdrawPoolTokenByUSDCAmount(_amount);
  }

  /**
   * @notice Purchase FIDU
   * @param _amount the amount of usdc to purchase by
   */
  function purchaseFIDU(uint256 _amount) external onlyAdmin {
    config.getTreasury().transferERC20(config.usdcAddress(), address(this), _amount);
    config.getUSDC().approve(config.seniorPoolAddress(), _amount);
    uint256 fiduAmount = config.getSeniorPool().deposit(_amount);
    config.getFIDU().safeTransfer(config.treasuryAddress(), fiduAmount);
    emit PurchaseFiduByUsdc(_amount);
  }

  /**
   * @notice Sell senior token to redeem FIDU
   * @param _amount the amount of FIDU to sell
   */
  function sellFIDU(uint256 _amount) external onlyAdmin {
    config.getTreasury().transferERC20(config.fiduAddress(), address(this), _amount);
    uint256 usdcAmount = config.getSeniorPool().withdrawInFidu(_amount);
    uint256 fee = usdcAmount.mul(config.getPermillageDuraRepayment()).div(1000);
    config.getTreasury().addRepaymentFee(fee);
    config.getUSDC().safeTransfer(config.treasuryAddress(), usdcAmount);
    emit SellFIDU(_amount);
  }

  /**
   * @notice Using the Goldfinch contracts, read the principal, redeemed and redeemable values
   * @param _tokenID The backer NFT id
   */
  function getJuniorTokenValue(uint256 _tokenID) public view returns (uint256) {
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(_tokenID);
    // now get the redeemable values for the given token
    address tranchedPoolAddress = tokenInfo.pool;
    ITranchedPool tranchedTokenContract = ITranchedPool(tranchedPoolAddress);
    (uint256 interestRedeemable, uint256 principalRedeemable) = tranchedTokenContract
      .availableToWithdraw(_tokenID);
    return tokenInfo.principalAmount.add(interestRedeemable).sub(tokenInfo.principalRedeemed);
  }

  /**
   * @notice GoldFinch PoolToken Value in Value in term of USDC
   */
  function getGoldFinchPoolTokenBalanceInUsdc() external view override returns (uint256) {
    uint256 total = 0;
    uint256 balance = config.getPoolTokens().balanceOf(config.treasuryAddress());
    for (uint256 i = 0; i < balance; i++) {
      total = total.add(
        getJuniorTokenValue(config.getPoolTokens().tokenOfOwnerByIndex(config.treasuryAddress(), i))
      );
    }
    return total;
  }

  /**
   * @notice Send the token of the ID to address
   * @param _depositor The address to send to
   * @param _tokenId The token ID to deposit
   */
  function transferTokenToDepositor(address _depositor, uint256 _tokenId) internal {
    require(tokenDepositorMap[_tokenId] == _depositor, "The token is not deposited by this user");
    delete tokenDepositorMap[_tokenId];
    config.getTreasury().transferERC721(config.poolTokensAddress(), _depositor, _tokenId);
  }

  /**
   * @notice Using the PoolTokens interface, check if this is a valid pool
   * @param _tokenID The backer NFT id
   */
  function isValidPool(uint256 _tokenID) public view returns (bool) {
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(_tokenID);
    address tranchedPool = tokenInfo.pool;
    return
      config.getPoolTokens().validPool(tranchedPool) &&
      config.getSortedGoldfinchTranches().isTranchInside(tranchedPool);
  }

  /**
   * @notice Get the tokenID array of depositor
   * @param _depositor The address of the depositor
   */
  function getTokensAvailableForWithdrawal(address _depositor)
    external
    view
    returns (uint256[] memory)
  {
    require(_depositor != address(0));
    uint256 count = config.getPoolTokens().balanceOf(config.treasuryAddress());
    uint256[] memory ids = new uint256[](getTokensAvailableCountForWithdrawal(_depositor));
    uint256 index = 0;
    for (uint256 i = 0; i < count; i++) {
      uint256 id = config.getPoolTokens().tokenOfOwnerByIndex(config.treasuryAddress(), i);
      if (tokenDepositorMap[id] == _depositor) {
        ids[index] = id;
        index += 1;
      }
    }
    return ids;
  }

  /**
   * @notice Get the token count of depositor
   * @param _depositor The address of the depositor
   */
  function getTokensAvailableCountForWithdrawal(address _depositor) public view returns (uint256) {
    require(_depositor != address(0));
    uint256 count = config.getPoolTokens().balanceOf(config.treasuryAddress());
    uint256 numOfTokens = 0;
    for (uint256 i = 0; i < count; i++) {
      uint256 id = config.getPoolTokens().tokenOfOwnerByIndex(config.treasuryAddress(), i);
      if (tokenDepositorMap[id] == _depositor) {
        numOfTokens += 1;
      }
    }
    return numOfTokens;
  }
}
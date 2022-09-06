// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;
pragma abicoder v2;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IERC721} from '../../dependencies/openzeppelin/contracts/IERC721.sol';
import {SafeERC721} from '../libraries/helpers/SafeERC721.sol';
import {Address} from '../../dependencies/openzeppelin/contracts/Address.sol';
import {ILendingPoolAddressesProvider} from '../../interfaces/ILendingPoolAddressesProvider.sol';
import {IVToken} from '../../interfaces/IVToken.sol';
import {INToken} from '../../interfaces/INToken.sol';
import {IERC721WithStat} from '../../interfaces/IERC721WithStat.sol';
import {INFTFlashLoanReceiver} from '../../flashloan/interfaces/INFTFlashLoanReceiver.sol';
import {IVariableDebtToken} from '../../interfaces/IVariableDebtToken.sol';
import {IPriceOracleGetter} from '../../interfaces/IPriceOracleGetter.sol';
import {INFTXEligibility} from '../../interfaces/INFTXEligibility.sol';
//import {IStableDebtToken} from '../../interfaces/IStableDebtToken.sol';
import {ILendingPool} from '../../interfaces/ILendingPool.sol';
import {VersionedInitializable} from '../libraries/aave-upgradeability/VersionedInitializable.sol';
import {Helpers} from '../libraries/helpers/Helpers.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {PercentageMath} from '../libraries/math/PercentageMath.sol';
import {ReserveLogic} from '../libraries/logic/ReserveLogic.sol';
import {NFTVaultLogic} from '../libraries/logic/NFTVaultLogic.sol';
import {GenericLogic} from '../libraries/logic/GenericLogic.sol';
import {ValidationLogic} from '../libraries/logic/ValidationLogic.sol';
import {ReserveConfiguration} from '../libraries/configuration/ReserveConfiguration.sol';
import {NFTVaultConfiguration} from '../libraries/configuration/NFTVaultConfiguration.sol';
import {UserConfiguration} from '../libraries/configuration/UserConfiguration.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import {LendingPoolStorage} from './LendingPoolStorage.sol';

/**
 * @title LendingPool contract
 * @dev Main point of interaction with a Vinci protocol's market
 * - Users can:
 *   # Deposit
 *   # Withdraw
 *   # Deposit NFT
 *   # Withdraw NFT
 *   # Borrow
 *   # Repay
 *   # Enable/disable their NFTs as collateral
 *   # Liquidate positions
 * - To be covered by a proxy contract, owned by the LendingPoolAddressesProvider of the specific market
 * - All admin functions are callable by the LendingPoolConfigurator contract defined also in the
 *   LendingPoolAddressesProvider
 * @author Aave
 * @author Vinci
 **/
contract LendingPool is VersionedInitializable, ILendingPool, LendingPoolStorage {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using GPv2SafeERC20 for IERC20;
  using SafeERC721 for IERC721;
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NFTVaultLogic for DataTypes.NFTVaultData;
  using NFTVaultConfiguration for DataTypes.NFTVaultConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  uint256 public constant LENDINGPOOL_REVISION = 0x4;

  modifier whenNotPaused() {
    _whenNotPaused();
    _;
  }

  modifier onlyLendingPoolConfigurator() {
    _onlyLendingPoolConfigurator();
    _;
  }

  function _whenNotPaused() internal view {
    require(!_paused, Errors.LP_IS_PAUSED);
  }

  function _onlyLendingPoolConfigurator() internal view {
    require(
      _addressesProvider.getLendingPoolConfigurator() == msg.sender,
      Errors.LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR
    );
  }

  function getRevision() internal pure override returns (uint256) {
    return LENDINGPOOL_REVISION;
  }

  /**
   * @dev Function is invoked by the proxy contract when the LendingPool contract is added to the
   * LendingPoolAddressesProvider of the market.
   * - Caching the address of the LendingPoolAddressesProvider in order to reduce gas consumption
   *   on subsequent operations
   * @param provider The address of the LendingPoolAddressesProvider
   **/
  function initialize(ILendingPoolAddressesProvider provider) public initializer {
    _addressesProvider = provider;
    _maxStableRateBorrowSizePercent = 2500;
    _flashLoanPremiumTotal = 0;
    _maxNumberOfReserves = 128;
    _maxNumberOfNFTVaults = 256;
  }

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying vTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the vTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of vTokens
   *   is a different wallet
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external override whenNotPaused {
    DataTypes.ReserveData storage reserve = _reserves.data[asset];

    ValidationLogic.validateDeposit(reserve, amount);

    address vToken = reserve.vTokenAddress;

    reserve.updateState();
    reserve.updateInterestRates(asset, vToken, amount, 0);

    IERC20(asset).safeTransferFrom(msg.sender, vToken, amount);

    IVToken(vToken).mint(onBehalfOf, amount, reserve.liquidityIndex);

    emit Deposit(asset, msg.sender, onBehalfOf, amount, referralCode);
  }

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 vUSDC, calls withdraw() and receives 100 USDC, burning the 100 vUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole vToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external override whenNotPaused returns (uint256) {
    DataTypes.ReserveData storage reserve = _reserves.data[asset];

    address vToken = reserve.vTokenAddress;

    uint256 userBalance = IVToken(vToken).balanceOf(msg.sender);

    uint256 amountToWithdraw = amount;

    if (amount == type(uint256).max) {
      amountToWithdraw = userBalance;
    }

    ValidationLogic.validateWithdraw(
      asset,
      amountToWithdraw,
      userBalance,
      _reserves,
      _usersConfig[msg.sender],
      _addressesProvider.getPriceOracle()
    );

    reserve.updateState();

    reserve.updateInterestRates(asset, vToken, 0, amountToWithdraw);

    IVToken(vToken).burn(msg.sender, to, amountToWithdraw, reserve.liquidityIndex);

    emit Withdraw(asset, msg.sender, to, amountToWithdraw);

    return amountToWithdraw;
  }

  /**
   * @dev Deposits NFTs with given `tokenIds` and `amounts` into the vault, receiving in return overlying nTokens.
   * E.g. User deposits an MAYC with tokenid 1234 and gets in return 1 vnMAYC with tokenid 1234
   * @param nft The address of the underlying asset to deposit
   * @param tokenIds The array of token ids to deposit
   * @param amounts The array of amounts to deposit. 
   * - Must be the same length with `tokenIds`. 
   * - All elements must be 1 for ERC721 NFT.
   * @param onBehalfOf The address that will receive the vnTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of vnTokens
   *   is a different wallet
   **/
  function depositNFT(
    address nft,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    address onBehalfOf,
    uint16 referralCode
  ) external override whenNotPaused {
    require(tokenIds.length == amounts.length, Errors.LP_TOKEN_AND_AMOUNT_LENGTH_NOT_MATCH);
    DataTypes.NFTVaultData storage vault = _nftVaults.data[nft];

    ValidationLogic.validateDepositNFT(
      vault,
      tokenIds,
      amounts
    );

    address nToken = vault.nTokenAddress;
    for(uint256 i = 0; i < tokenIds.length; ++i){
      IERC721(nft).safeTransferFrom(msg.sender, nToken, tokenIds[i]);
      bool isFirstDeposit = INToken(nToken).mint(onBehalfOf, tokenIds[i], 1);
      if (isFirstDeposit) {
        _usersConfig[onBehalfOf].setUsingNFTVaultAsCollateral(vault.id, true);
        emit NFTVaultUsedAsCollateralEnabled(nft, onBehalfOf);
      }
    }

    emit DepositNFT(nft, msg.sender, onBehalfOf, tokenIds, amounts, referralCode);

  }

  function depositAndLockNFT(
    address nft,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    address onBehalfOf,
    uint16 lockType,
    uint16 referralCode
  ) external override whenNotPaused {
    require(tokenIds.length == amounts.length, Errors.LP_TOKEN_AND_AMOUNT_LENGTH_NOT_MATCH);
    DataTypes.NFTVaultData storage vault = _nftVaults.data[nft];

    ValidationLogic.validateDepositNFT(
      vault,
      tokenIds,
      amounts
    );

    ValidationLogic.validateLockNFT(
      vault,
      uint40(block.timestamp)
    );    

    address nToken = vault.nTokenAddress;
    for(uint256 i = 0; i < tokenIds.length; ++i){
      IERC721(nft).safeTransferFrom(msg.sender, nToken, tokenIds[i]);
      bool isFirstDeposit = INToken(nToken).mint(onBehalfOf, tokenIds[i], 1);
      if(lockType != 0) {
        INToken(nToken).lock(tokenIds[i], lockType);
      }
      if (isFirstDeposit) {
        _usersConfig[onBehalfOf].setUsingNFTVaultAsCollateral(vault.id, true);
        emit NFTVaultUsedAsCollateralEnabled(nft, onBehalfOf);
      }
    }

    emit DepositNFT(nft, msg.sender, onBehalfOf, tokenIds, amounts, referralCode);

  }

  /**
   * @dev Withdraws underlying NFTs with given `tokenIds` and `amounts` from the vault, burning the equivalent nTokens owned
   * E.g. User has vnMAYC with token id 1234, calls withdraw() and receives the MAYC with token id 1234, burning the vUSDC with token id 1234.
   * @param nft The address of the underlying NFT to withdraw
   * @param tokenIds The array of token ids to withdraw
   * @param amounts The array of amounts to withdraw. 
   * - Must be the same length with `tokenIds`. 
   * - All elements must be 1 for ERC721 NFT.
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdrawNFT(
    address nft,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    address to
  ) external override whenNotPaused returns (uint256[] memory) {
    require(tokenIds.length == amounts.length, Errors.LP_TOKEN_AND_AMOUNT_LENGTH_NOT_MATCH);
    DataTypes.NFTVaultData storage vault = _nftVaults.data[nft];

    address nToken = vault.nTokenAddress;

    uint256[] memory userBalances = INToken(nToken).unlockedBalanceOfBatch(msg.sender, tokenIds);

    uint256[] memory amountsToWithdraw = amounts;

    uint256 amountToWithdraw = 0;

    for(uint256 i = 0; i < tokenIds.length; ++i){
      if (amounts[i] == type(uint256).max) {
        amountsToWithdraw[i] = userBalances[i];
      }
      amountToWithdraw = amountToWithdraw + amountsToWithdraw[i];
    }

    ValidationLogic.validateWithdrawNFT(
      nft,
      tokenIds,
      amountsToWithdraw,
      userBalances,
      _reserves,
      _nftVaults,
      _usersConfig[msg.sender],
      _addressesProvider.getPriceOracle()
    );

    if (amountToWithdraw == IERC721(nToken).balanceOf(msg.sender)) {
      _usersConfig[msg.sender].setUsingNFTVaultAsCollateral(vault.id, false);
      emit NFTVaultUsedAsCollateralDisabled(nft, msg.sender);
    }

    INFTXEligibility(vault.nftEligibility).afterRedeemHook(tokenIds);

    INToken(nToken).burnBatch(msg.sender, to, tokenIds, amountsToWithdraw);
    
    emit WithdrawNFT(nft, msg.sender, to, tokenIds, amountsToWithdraw);

    return amountsToWithdraw;
  }

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 variable debt tokens.
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow. Unused currently, must be > 0
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external override whenNotPaused {
    DataTypes.ReserveData storage reserve = _reserves.data[asset];

    _executeBorrow(
      ExecuteBorrowParams(
        asset,
        msg.sender,
        onBehalfOf,
        amount,
        interestRateMode,
        reserve.vTokenAddress,
        referralCode,
        true
      )
    );
  }

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay. Unused Currently, must be > 0
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external override whenNotPaused returns (uint256) {
    DataTypes.ReserveData storage reserve = _reserves.data[asset];

    (, uint256 variableDebt) = Helpers.getUserCurrentDebt(onBehalfOf, reserve);

    DataTypes.InterestRateMode interestRateMode = DataTypes.InterestRateMode(rateMode);

    ValidationLogic.validateRepay(
      reserve,
      amount,
      interestRateMode,
      onBehalfOf,
      0,
      variableDebt
    );

    uint256 paybackAmount = variableDebt;

    if (amount < paybackAmount) {
      paybackAmount = amount;
    }

    reserve.updateState();

    /*if (interestRateMode == DataTypes.InterestRateMode.STABLE) {
      IStableDebtToken(reserve.stableDebtTokenAddress).burn(onBehalfOf, paybackAmount);
    } else {*/
      IVariableDebtToken(reserve.variableDebtTokenAddress).burn(
        onBehalfOf,
        paybackAmount,
        reserve.variableBorrowIndex
      );
    //}

    address vToken = reserve.vTokenAddress;
    reserve.updateInterestRates(asset, vToken, paybackAmount, 0);

    if (variableDebt - paybackAmount == 0) {
      _usersConfig[onBehalfOf].setBorrowing(reserve.id, false);
    }

    IERC20(asset).safeTransferFrom(msg.sender, vToken, paybackAmount);

    IVToken(vToken).handleRepayment(msg.sender, paybackAmount);

    emit Repay(asset, onBehalfOf, msg.sender, paybackAmount);

    return paybackAmount;
  }

  struct NFTLiquidationCallParameters {
    address collateralAsset;
    address debtAsset;
    address user;
    uint256[] tokenIds;
    uint256[] amounts;
    bool receiveNToken;
  }

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) chooses `tokenIds` and `amounts` of the `collateralAsset` NFTs of the 
   *   user getting liquidated, and pays the corrensponding discounted `debtAsset` price
   *   to cover the debt of the user getting liquidated. 
   * - If there is any `debtAsset` left after repayment of the debt, it will be converted to vToken
   *   and transferred to the user getting liquidated.
   * @param collateralAsset The address of the underlying NFT used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param tokenIds The array of token ids of the NFTs that the liquidator wants to receive
   * - Starting from the front, only the portion that covers 50% of the debt of the user get liquidating will be liquidated
   * @param amounts The array of ammounts of the NFTs that the liquidator wants to receive
   * - Must be the same length with `tokenIds`
   * @param receiveNToken `true` if the liquidators wants to receive the collateral nTokens, `false` if he wants
   * to receive the underlying collateral NFT directly
   **/
  function nftLiquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bool receiveNToken
  ) external override whenNotPaused {
    address collateralManager = _addressesProvider.getLendingPoolCollateralManager();
    NFTLiquidationCallParameters memory params;
    params.collateralAsset = collateralAsset;
    params.debtAsset = debtAsset;
    params.user = user;
    params.tokenIds = tokenIds;
    params.amounts = amounts;
    params.receiveNToken = receiveNToken;
    //solium-disable-next-line
    (bool success, bytes memory result) =
      collateralManager.delegatecall(
        abi.encodeWithSignature(
          'nftLiquidationCall((address,address,address,uint256[],uint256[],bool))',
          params
        )
      );

    require(success, Errors.LP_LIQUIDATION_CALL_FAILED);

    (uint256 returnCode, string memory returnMessage) = abi.decode(result, (uint256, string));

    require(returnCode == 0, string(abi.encodePacked(returnMessage)));
  }

  struct NFTFlashLoanLocalVars {
    INFTFlashLoanReceiver receiver;
    uint256 i;
    address asset;
    address nTokenAddress;
    uint256 currentAmount;
    uint256 currentPremium;
    uint256 currentAmountPlusPremium;
  }

  /**
   * @dev Allows smartcontracts to access the nft vault of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the INFTFlashLoanReceiver interface
   * @param asset The addresses of the assets being flash-borrowed
   * @param tokenIds The tokenIds of the NFTs being flash-borrowed
   * @param amounts For ERC1155 only: The amounts of NFTs being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   **/
  function nftFlashLoan(
    address receiverAddress,
    address asset,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata params,
    uint16 referralCode
  ) external override whenNotPaused 
  {
    NFTFlashLoanLocalVars memory vars;

    vars.nTokenAddress = _nftVaults.data[asset].nTokenAddress;
    // uint256 premium = tokenIds.length * _flashLoadPremiumTotal / 10000;
    uint256 premium = 0;

    uint256[] memory userBalances = IERC721WithStat(vars.nTokenAddress).balanceOfBatch(msg.sender, tokenIds);
    ValidationLogic.validateNFTFlashloan(asset, tokenIds, amounts, userBalances);

    vars.receiver = INFTFlashLoanReceiver(receiverAddress);
    for (vars.i = 0; vars.i < tokenIds.length; vars.i++) {
      INToken(vars.nTokenAddress).transferUnderlyingTo(receiverAddress, tokenIds[vars.i], amounts[vars.i]);
    }
    require(
      vars.receiver.executeOperation(asset, tokenIds, amounts, premium, msg.sender, params),
      Errors.LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN
    );

    for (vars.i = 0; vars.i < tokenIds.length; vars.i++) {
      IERC721(asset).safeTransferFrom(receiverAddress, vars.nTokenAddress, tokenIds[vars.i]);
    }
    emit NFTFlashLoan(
      receiverAddress,
      msg.sender,
      asset,
      tokenIds,
      amounts,
      0,
      referralCode
    );
  }

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset)
    external
    view
    override
    returns (DataTypes.ReserveData memory)
  {
    return _reserves.data[asset];
  }

  /**
   * @dev Returns the state and configuration of the vault
   * @param asset The address of the underlying NFT of the vault
   * @return The state of the vault
   **/
  function getNFTVaultData(address asset) 
    external 
    view 
    override
    returns (DataTypes.NFTVaultData memory)
  {
    return _nftVaults.data[asset];
  }

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    override
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    )
  {
    (
      totalCollateralETH,
      totalDebtETH,
      ltv,
      currentLiquidationThreshold,
      healthFactor
    ) = GenericLogic.calculateUserAccountData(
      user,
      _reserves,
      _nftVaults,
      _usersConfig[user],
      _addressesProvider.getPriceOracle()
    );

    availableBorrowsETH = GenericLogic.calculateAvailableBorrowsETH(
      totalCollateralETH,
      totalDebtETH,
      ltv
    );
  }

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    override
    returns (DataTypes.ReserveConfigurationMap memory)
  {
    return _reserves.data[asset].configuration;
  }

  /**
   * @dev Returns the configuration of the vault
   * @param asset The address of the underlying nft of the vault
   * @return The configuration of the vault
   **/
  function getNFTVaultConfiguration(address asset)
    external
    view
    override
    returns (DataTypes.NFTVaultConfigurationMap memory)
  {
    return _nftVaults.data[asset].configuration;
  }

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    override
    returns (DataTypes.UserConfigurationMap memory)
  {
    return _usersConfig[user];
  }

  /**
   * @dev Returns the normalized income per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return _reserves.data[asset].getNormalizedIncome();
  }

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset)
    external
    view
    override
    returns (uint256)
  {
    return _reserves.data[asset].getNormalizedDebt();
  }

  /**
   * @dev Returns if the LendingPool is paused
   */
  function paused() external view override returns (bool) {
    return _paused;
  }

  /**
   * @dev Returns the list of the initialized reserves
   **/
  function getReservesList() external view override returns (address[] memory) {
    address[] memory _activeReserves = new address[](_reserves.count);

    for (uint256 i = 0; i < _reserves.count; i++) {
      _activeReserves[i] = _reserves.list[i];
    }
    return _activeReserves;
  }

  /**
   * @dev Returns the list of the initialized vaults
   **/
  function getNFTVaultsList() external view override returns (address[] memory) {
    address[] memory _activeVaults = new address[](_nftVaults.count);

    for (uint256 i = 0; i < _nftVaults.count; i++) {
      _activeVaults[i] = _nftVaults.list[i];
    }
    return _activeVaults;
  }

  /**
   * @dev Returns the cached LendingPoolAddressesProvider connected to this contract
   **/
  function getAddressesProvider() external view override returns (ILendingPoolAddressesProvider) {
    return _addressesProvider;
  }

  /**
   * @dev Returns the percentage of available liquidity that can be borrowed at once at stable rate
   */
  function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() public view returns (uint256) {
    return _maxStableRateBorrowSizePercent;
  }

  /**
   * @dev Returns the fee on flash loans 
   */
  function FLASHLOAN_PREMIUM_TOTAL() public view returns (uint256) {
    return _flashLoanPremiumTotal;
  }

  /**
   * @dev Returns the maximum number of reserves supported to be listed in this LendingPool
   */
  function MAX_NUMBER_RESERVES() public view returns (uint256) {
    return _maxNumberOfReserves;
  }

  /**
   * @dev Validates and finalizes a vToken transfer
   * - Only callable by the overlying vToken of the `asset`
   * @param asset The address of the underlying asset of the vToken
   * @param from The user from which the vTokens are transferred
   * @param to The user receiving the vTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The vToken balance of the `from` user before the transfer
   * @param balanceToBefore The vToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external override whenNotPaused {
    require(msg.sender == _reserves.data[asset].vTokenAddress, Errors.LP_CALLER_MUST_BE_AN_VTOKEN);

    ValidationLogic.validateTransfer(
      from,
      _reserves,
      _nftVaults,
      _usersConfig[from],
      _addressesProvider.getPriceOracle()
    );
  }

  /**
   * @dev Validates and finalizes a nToken transfer
   * - Only callable by the overlying nToken of the `asset`
   * @param asset The address of the underlying NFT of the nToken
   * @param from The user from which the nTokens are transferred
   * @param to The user receiving the nTokens
   * @param tokenId The token id of the NFT being transferred/withdrawn
   * @param amount The amount of the NFT with `tokenId` being transferred/withdrawn
   * @param balanceFromBefore The vToken balance of the `from` user before the transfer
   * @param balanceToBefore The vToken balance of the `to` user before the transfer
   */
  function finalizeNFTSingleTransfer(
    address asset,
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external override whenNotPaused {
    require(msg.sender == _nftVaults.data[asset].nTokenAddress, Errors.LP_CALLER_MUST_BE_AN_VTOKEN);

    ValidationLogic.validateTransfer(
      from,
      _reserves,
      _nftVaults,
      _usersConfig[from],
      _addressesProvider.getPriceOracle()
    );

    uint256 vaultId = _nftVaults.data[asset].id;

    if (from != to) {
      if (balanceFromBefore -amount == 0) {
        DataTypes.UserConfigurationMap storage fromConfig = _usersConfig[from];
        fromConfig.setUsingNFTVaultAsCollateral(vaultId, false);
        emit NFTVaultUsedAsCollateralDisabled(asset, from);
      }

      if (balanceToBefore == 0 && amount != 0) {
        DataTypes.UserConfigurationMap storage toConfig = _usersConfig[to];
        toConfig.setUsingNFTVaultAsCollateral(vaultId, true);
        emit NFTVaultUsedAsCollateralEnabled(asset, to);
      }
    }

  }

  /**
   * @dev Validates and finalizes a batch nToken transfer
   * - Only callable by the overlying nToken of the `asset`
   * @param asset The address of the underlying NFT of the nTokens
   * @param from The user from which the nTokens are transferred
   * @param to The user receiving the vTokens
   * @param tokenIds The array of token ids of the NFTs being transferred/withdrawn
   * @param amounts The array of amounts of the NFTs being transferred/withdrawn
   * - Must be the same length with `tokenIds`
   * @param balanceFromBefore The vToken balance of the `from` user before the transfer
   * @param balanceToBefore The vToken balance of the `to` user before the transfer
   */
  function finalizeNFTBatchTransfer(
    address asset,
    address from,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external override whenNotPaused {
    require(msg.sender == _nftVaults.data[asset].nTokenAddress, Errors.LP_CALLER_MUST_BE_AN_VTOKEN);

    ValidationLogic.validateTransfer(
      from,
      _reserves,
      _nftVaults,
      _usersConfig[from],
      _addressesProvider.getPriceOracle()
    );

    uint256 vaultId = _nftVaults.data[asset].id;
    uint256 amount = 0;
    for(uint256 i = 0; i < amounts.length; ++i){
      amount = amount + amounts[i];
    }

    if (from != to) {
      if (balanceFromBefore - amount == 0) {
        DataTypes.UserConfigurationMap storage fromConfig = _usersConfig[from];
        fromConfig.setUsingNFTVaultAsCollateral(vaultId, false);
        emit NFTVaultUsedAsCollateralDisabled(asset, from);
      }

      if (balanceToBefore == 0 && amount != 0) {
        DataTypes.UserConfigurationMap storage toConfig = _usersConfig[to];
        toConfig.setUsingNFTVaultAsCollateral(vaultId, true);
        emit NFTVaultUsedAsCollateralEnabled(asset, to);
      }
    }

  }

  /**
   * @dev Initializes a reserve, activating it, assigning a vToken and debt tokens and an
   * interest rate strategy
   * - Only callable by the LendingPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param vTokenAddress The address of the vToken that will be assigned to the reserve
   * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
   * @param vTokenAddress The address of the VariableDebtToken that will be assigned to the reserve
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   **/
  function initReserve(
    address asset,
    address vTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external override onlyLendingPoolConfigurator {
    require(Address.isContract(asset), Errors.LP_NOT_CONTRACT);
    _reserves.data[asset].init(
      vTokenAddress,
      stableDebtAddress,
      variableDebtAddress,
      interestRateStrategyAddress
    );
    _addReserveToList(asset);
  }

  /**
   * @dev Initializes a vault, activating it, assigning a nToken and an eligibility checker
   * - Only callable by the LendingPoolConfigurator contract
   * @param nft The address of the underlying NFT of the vault
   * @param nTokenAddress The address of the nToken that will be assigned to the vault
   * @param nftEligibility The address of the NFTXEligibility contract that will be used for checking NFT eligibility
   **/
  function initNFTVault(
    address nft,
    address nTokenAddress,
    address nftEligibility
  ) external override onlyLendingPoolConfigurator {
    require(Address.isContract(nft), Errors.LP_NOT_CONTRACT);
    _nftVaults.data[nft].init(
      nTokenAddress,
      nftEligibility
    );
    _addNFTVaultToList(nft);
  }

  /**
   * @dev Updates the address of the interest rate strategy contract
   * - Only callable by the LendingPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The address of the interest rate strategy contract
   **/
  function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
    external
    override
    onlyLendingPoolConfigurator
  {
    _reserves.data[asset].interestRateStrategyAddress = rateStrategyAddress;
  }

  /**
   * @dev Sets the configuration bitmap of the reserve as a whole
   * - Only callable by the LendingPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
  function setConfiguration(address asset, uint256 configuration)
    external
    override
    onlyLendingPoolConfigurator
  {
    _reserves.data[asset].configuration.data = configuration;
  }

  /**
   * @dev Sets the configuration bitmap of the vault as a whole
   * - Only callable by the LendingPoolConfigurator contract
   * @param vault The address of the underlying NFT of the vault
   * @param configuration The new configuration bitmap
   **/
  function setNFTVaultConfiguration(address vault, uint256 configuration)
   external
   override
   onlyLendingPoolConfigurator
  {
    _nftVaults.data[vault].configuration.data = configuration;
  }

  function setNFTVaultActionExpiration(address vault, uint40 expiration)
   external
   override
   onlyLendingPoolConfigurator
  {
    _nftVaults.data[vault].expiration = expiration;
  }

  function setNFTVaultEligibility(address vault, address eligibility)
   external
   override
   onlyLendingPoolConfigurator
  {
    _nftVaults.data[vault].nftEligibility = eligibility;
  }

  /**
   * @dev Set the _pause state of a reserve
   * - Only callable by the LendingPoolConfigurator contract
   * @param val `true` to pause the reserve, `false` to un-pause it
   */
  function setPause(bool val) external override onlyLendingPoolConfigurator {
    _paused = val;
    if (_paused) {
      emit Paused();
    } else {
      emit Unpaused();
    }
  }

  struct ExecuteBorrowParams {
    address asset;
    address user;
    address onBehalfOf;
    uint256 amount;
    uint256 interestRateMode;
    address vTokenAddress;
    uint16 referralCode;
    bool releaseUnderlying;
  }

  function _executeBorrow(ExecuteBorrowParams memory vars) internal {
    DataTypes.ReserveData storage reserve = _reserves.data[vars.asset];
    DataTypes.UserConfigurationMap storage userConfig = _usersConfig[vars.onBehalfOf];

    address oracle = _addressesProvider.getPriceOracle();

    uint256 amountInETH =
      IPriceOracleGetter(oracle).getAssetPrice(vars.asset) * vars.amount
        / (10**reserve.configuration.getDecimals());

    ValidationLogic.validateBorrow(
      vars.asset,
      reserve,
      vars.onBehalfOf,
      vars.amount,
      amountInETH,
      vars.interestRateMode,
      0, //_maxStableRateBorrowSizePercent,
      _reserves,
      _nftVaults,
      userConfig,
      oracle
    );

    reserve.updateState();

    //uint256 currentStableRate = 0;

    bool isFirstBorrowing = false;
    /*if (DataTypes.InterestRateMode(vars.interestRateMode) == DataTypes.InterestRateMode.STABLE) {
      currentStableRate = reserve.currentStableBorrowRate;

      isFirstBorrowing = IStableDebtToken(reserve.stableDebtTokenAddress).mint(
        vars.user,
        vars.onBehalfOf,
        vars.amount,
        currentStableRate
      );
    } else {*/
      isFirstBorrowing = IVariableDebtToken(reserve.variableDebtTokenAddress).mint(
        vars.user,
        vars.onBehalfOf,
        vars.amount,
        reserve.variableBorrowIndex
      );
    //}

    if (isFirstBorrowing) {
      userConfig.setBorrowing(reserve.id, true);
    }

    reserve.updateInterestRates(
      vars.asset,
      vars.vTokenAddress,
      0,
      vars.releaseUnderlying ? vars.amount : 0
    );

    if (vars.releaseUnderlying) {
      IVToken(vars.vTokenAddress).transferUnderlyingTo(vars.user, vars.amount);
    }

    emit Borrow(
      vars.asset,
      vars.user,
      vars.onBehalfOf,
      vars.amount,
      vars.interestRateMode,
      //DataTypes.InterestRateMode(vars.interestRateMode) == DataTypes.InterestRateMode.STABLE
      //  ? currentStableRate
      reserve.currentVariableBorrowRate,
      vars.referralCode
    );
  }

  function _addReserveToList(address asset) internal {
    uint256 reservesCount = _reserves.count;

    require(reservesCount < _maxNumberOfReserves, Errors.LP_NO_MORE_RESERVES_ALLOWED);

    bool reserveAlreadyAdded = _reserves.data[asset].id != 0 || _reserves.list[0] == asset;

    if (!reserveAlreadyAdded) {
      _reserves.data[asset].id = uint8(reservesCount);
      _reserves.list[reservesCount] = asset;

      _reserves.count = reservesCount + 1;
    }
  }

  function _addNFTVaultToList(address nft) internal {
    uint256 nftVaultsCount = _nftVaults.count;

    require(nftVaultsCount < _maxNumberOfNFTVaults, Errors.LP_NO_MORE_NFT_VAULTS_ALLOWED);

    bool vaultAlreadyAdded = _nftVaults.data[nft].id != 0 || _nftVaults.list[0] == nft;

    if (!vaultAlreadyAdded) {
      _nftVaults.data[nft].id = uint8(nftVaultsCount);
      _nftVaults.list[nftVaultsCount] = nft;

      _nftVaults.count = nftVaultsCount + 1;
    }
  }
}
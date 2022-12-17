// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;
pragma abicoder v2;

import {IERC20} from './dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from './dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {Address} from './dependencies/openzeppelin/contracts/Address.sol';
import {IVaultAddressesProvider} from './interfaces/IVaultAddressesProvider.sol';
import {IInitializableOToken} from './interfaces/IInitializableOToken.sol';
import {IOToken} from './interfaces/IOToken.sol';
import {IVault} from './interfaces/IVault.sol';
import {VersionedInitializable} from './libraries/aave-upgradeability/VersionedInitializable.sol';
import {Errors} from './libraries/helpers/Errors.sol';
import {WadRayMath} from './libraries/math/WadRayMath.sol';
import {PercentageMath} from './libraries/math/PercentageMath.sol';
import {ReserveLogic} from './libraries/logic/ReserveLogic.sol';
import {ReserveConfiguration} from './libraries/configuration/ReserveConfiguration.sol';
import {DataTypes} from './libraries/types/DataTypes.sol';
import {VaultStorage} from './VaultStorage.sol';
import {InitializableImmutableAdminUpgradeabilityProxy} from './libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol';
import "hardhat/console.sol";

/**
 * @title Vault contract
 * @dev Main point of interaction with a Onebit protocol's market
 * - Users can:
 *   # Deposit
 *   # Withdraw
 * - To be covered by a proxy contract, owned by the VaultAddressesProvider of the specific market
 * - All admin functions are callable by the VaultOperator contract defined also in the
 *   VaultAddressesProvider
 * @author Aave
 * @author Onebit
 **/
contract Vault is VersionedInitializable, IVault, VaultStorage {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using GPv2SafeERC20 for IERC20;
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  uint256 public constant VAULT_REVISION = 0x2;

  modifier whenNotPaused() {
    require(!_paused, Errors.V_IS_PAUSED);
    _;
  }

  modifier onlyVaultOperator() {
    require(
      _addressesProvider.getVaultOperator() == msg.sender
      || _addressesProvider.getVaultAdmin() == msg.sender,
      Errors.V_CALLER_NOT_VAULT_OPERATOR
    );
    _;
  }

  modifier onlyVaultAdmin() {
    require(
      _addressesProvider.getVaultAdmin() == msg.sender,
      Errors.CALLER_NOT_VAULT_ADMIN
    );
    _;
  }

  modifier onlyVaultConfigurator() {
    require(
      _addressesProvider.getVaultConfigurator() == msg.sender,
      Errors.V_CALLER_NOT_VAULT_CONFIGURATOR
    );
    _;
  }

  constructor () {
    _addressesProvider = IVaultAddressesProvider(address(0));
  }

  function getRevision() internal pure override returns (uint256) {
    return VAULT_REVISION;
  }

  /**
   * @dev Function is invoked by the proxy contract when the Vault contract is added to the
   * VaultAddressesProvider of the market.
   * - Caching the address of the VaultAddressesProvider in order to reduce gas consumption
   *   on subsequent operations
   * @param provider The address of the VaultAddressesProvider
   **/
  function initialize(IVaultAddressesProvider provider) public initializer {
    _addressesProvider = provider;
  }

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying oTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the oTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of oTokens
   *   is a different wallet
   **/
  function deposit(
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external override whenNotPaused returns(uint256) {
    require(amount != 0, Errors.VL_INVALID_AMOUNT);
    uint40 currentTimestamp = uint40(block.timestamp);
    require (_whitelist[msg.sender] > block.timestamp, Errors.V_NOT_IN_WHITELIST);

    (bool isActive, bool isFrozen) = _reserve.configuration.getFlags();
    require((currentTimestamp >= _reserve.purchaseBeginTimestamp) 
             && ((currentTimestamp < _reserve.purchaseEndTimestamp) 
                  || (currentTimestamp >= _reserve.redemptionBeginTimestamp)),
            Errors.VL_NOT_IN_PURCHASE_OR_REDEMPTION_PERIOD);
    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
    require(!isFrozen, Errors.VL_RESERVE_FROZEN);

    address oTokenAddress = _reserve.oTokenAddress;

    IOToken oToken = IOToken(oTokenAddress);

    uint256 availableFund = _reserve.purchaseUpperLimit - oToken.totalSupply();

    if(amount > availableFund){
      amount = availableFund;
    }

    oToken.mint(onBehalfOf, amount, _reserve.getNormalizedIncome());

    IERC20(oToken.UNDERLYING_ASSET_ADDRESS()).safeTransferFrom(msg.sender, oTokenAddress, amount);

    emit Deposit(msg.sender, onBehalfOf, amount, referralCode);

    return amount;
  }

  function depositFund(
    uint256 amount
  ) external override onlyVaultAdmin {
    require(amount != 0, Errors.VL_INVALID_AMOUNT);
    address oTokenAddress = _reserve.oTokenAddress;
    IERC20 asset = IERC20(IOToken(oTokenAddress).UNDERLYING_ASSET_ADDRESS());
    asset.safeTransferFrom(msg.sender, oTokenAddress, amount);
    emit FundDeposit(msg.sender, amount);
  }

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 vUSDC, calls withdraw() and receives 100 USDC, burning the 100 vUSDC
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole oToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    uint256 amount,
    address to
  ) external override whenNotPaused returns (uint256) {
    require (_whitelist[msg.sender] > block.timestamp, Errors.V_NOT_IN_WHITELIST);

    address oToken = _reserve.oTokenAddress;

    uint256 userBalance = IOToken(oToken).balanceOf(msg.sender);

    uint256 amountToWithdraw = amount;

    if (amount == type(uint256).max) {
      amountToWithdraw = userBalance;
    }

    uint40 currentTimestamp = uint40(block.timestamp);

    require(amount != 0, Errors.VL_INVALID_AMOUNT);
    require(amount <= userBalance, Errors.VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE);
    require((currentTimestamp >= _reserve.purchaseBeginTimestamp) 
             && ((currentTimestamp < _reserve.purchaseEndTimestamp) 
                  || (currentTimestamp >= _reserve.redemptionBeginTimestamp)),
            Errors.VL_NOT_IN_PURCHASE_OR_REDEMPTION_PERIOD);
    (bool isActive, ) = _reserve.configuration.getFlags();
    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);

    IOToken(oToken).burn(msg.sender, to, amountToWithdraw, _reserve.getNormalizedIncome());

    emit Withdraw(msg.sender, to, amountToWithdraw);

    return amountToWithdraw;
  }

  function withdrawFund(uint256 amount) external override whenNotPaused onlyVaultAdmin returns (uint256) {
    uint256 currentTimestamp = block.timestamp;
    require(amount > 0, Errors.VL_INVALID_AMOUNT);
    require((currentTimestamp >= _reserve.purchaseEndTimestamp) && (currentTimestamp < _reserve.redemptionBeginTimestamp), Errors.VL_NOT_IN_LOCK_PERIOD);
    uint256 amountToWithdraw = amount;
    address oTokenAddress = _reserve.oTokenAddress;
    IOToken oToken = IOToken(oTokenAddress);
    IERC20 asset = IERC20(oToken.UNDERLYING_ASSET_ADDRESS());
    if (amount == type(uint256).max) {
      amountToWithdraw = asset.balanceOf(oTokenAddress);
    }
    oToken.transferUnderlyingTo(_reserve.fundAddress, amountToWithdraw);

    emit FundWithdraw(_reserve.fundAddress, amountToWithdraw);

    return amountToWithdraw;
  }

  /**
   * @dev Returns the state and configuration of the reserve
   * @return The state of the reserve
   **/
  function getReserveData()
    external
    view
    override
    returns (DataTypes.ReserveData memory)
  {
    return _reserve;
  }

  function updateNetValue(uint256 netValue)
    external
    onlyVaultOperator
  {
    require(netValue > 0, Errors.VL_INVALID_AMOUNT);
    uint256 currentTimestamp = block.timestamp;
    require((uint40(currentTimestamp) >= _reserve.purchaseEndTimestamp) && (uint40(currentTimestamp) < _reserve.redemptionBeginTimestamp), Errors.VL_NOT_IN_LOCK_PERIOD);
    address oToken = _reserve.oTokenAddress;
    uint256 totalSupply = IOToken(oToken).scaledTotalSupply();
    uint256 oldNetValue = IOToken(oToken).totalSupply();
    _reserve.updateNetValue(netValue, totalSupply, currentTimestamp);
    
    emit NetValueUpdated(oldNetValue, IOToken(oToken).totalSupply(), _reserve.previousLiquidityIndex, _reserve.liquidityIndex, _reserve.currentLiquidityRate);
  }

  function initializeNextPeriod(uint16 managementFeeRate, uint16 performanceFeeRate, 
    uint128 purchaseUpperLimit,
    uint128 softUpperLimit,
    uint40 purchaseBeginTimestamp, uint40 purchaseEndTimestamp, 
    uint40 redemptionBeginTimestamp)
    external
    override
    onlyVaultConfigurator
  {
    require(uint40(block.timestamp) >= _reserve.redemptionBeginTimestamp, Errors.VL_NOT_FINISHED);
    require((purchaseBeginTimestamp >= _reserve.redemptionBeginTimestamp)
            &&(purchaseBeginTimestamp < purchaseEndTimestamp)
            && (purchaseEndTimestamp < redemptionBeginTimestamp),
      Errors.VL_INVALID_TIMESTAMP);
    _reserve.managementFeeRate = managementFeeRate;
    _reserve.performanceFeeRate = performanceFeeRate;
    _reserve.purchaseUpperLimit = purchaseUpperLimit;
    _reserve.previousLiquidityIndex = uint128(_reserve.getNormalizedIncome());
    _reserve.liquidityIndex = _reserve.previousLiquidityIndex;
    _reserve.currentLiquidityRate = int128( - int256(PercentageMath.percentMul(WadRayMath.ray(), managementFeeRate)));
    _reserve.purchaseBeginTimestamp = purchaseBeginTimestamp;
    _reserve.purchaseEndTimestamp = purchaseEndTimestamp;
    _reserve.redemptionBeginTimestamp = redemptionBeginTimestamp;
    _reserve.lastUpdateTimestamp = purchaseEndTimestamp;
    _reserve.softUpperLimit = softUpperLimit;

    emit PeriodInitialized(_reserve.previousLiquidityIndex, purchaseBeginTimestamp, purchaseEndTimestamp, redemptionBeginTimestamp, managementFeeRate, performanceFeeRate);
  }

  function moveTheLockPeriod(uint40 newPurchaseEndTimestamp) external override onlyVaultConfigurator
  {
    require(newPurchaseEndTimestamp < _reserve.purchaseEndTimestamp);
    require(newPurchaseEndTimestamp > _reserve.purchaseBeginTimestamp);
    require(newPurchaseEndTimestamp >= uint40(block.timestamp));
    uint40 previousTimestamp = _reserve.purchaseEndTimestamp;
    _reserve.purchaseEndTimestamp = newPurchaseEndTimestamp;
    emit PurchaseEndTimestampMoved(previousTimestamp, newPurchaseEndTimestamp);
  }

  function moveTheRedemptionPeriod(uint40 newRedemptionBeginTimestamp) external override onlyVaultConfigurator
  {
    require(newRedemptionBeginTimestamp > _reserve.purchaseEndTimestamp);
    require(newRedemptionBeginTimestamp >= uint40(block.timestamp));
    uint40 previousTimestamp = _reserve.redemptionBeginTimestamp;
    _reserve.redemptionBeginTimestamp = newRedemptionBeginTimestamp;
    emit RedemptionBeginTimestampMoved(previousTimestamp, newRedemptionBeginTimestamp);
  }

  function moveThePurchasePeriod(uint40 newPurchaseBeginTimestamp) external override onlyVaultConfigurator
  {
    require(newPurchaseBeginTimestamp < _reserve.purchaseEndTimestamp);
    uint40 previousTimestamp = _reserve.purchaseBeginTimestamp;
    _reserve.purchaseBeginTimestamp = newPurchaseBeginTimestamp;
    emit PurchaseBeginTimestampMoved(previousTimestamp, newPurchaseBeginTimestamp);
  }

  /**
   * @dev Returns the configuration of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration()
    external
    view
    override
    returns (DataTypes.ReserveConfigurationMap memory)
  {
    return _reserve.configuration;
  }

  /**
   * @dev Returns the normalized income per unit of asset
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome()
    external
    view
    virtual
    override
    returns (uint256)
  {
    return _reserve.getNormalizedIncome();
  }

  /**
   * @dev Returns if the Vault is paused
   */
  function paused() external view override returns (bool) {
    return _paused;
  }

  /**
   * @dev Returns the cached VaultAddressesProvider connected to this contract
   **/
  function getAddressesProvider() external view override returns (IVaultAddressesProvider) {
    return _addressesProvider;
  }

  /**
   * @dev Set the _pause state of a reserve
   * - Only callable by the VaultOperator contract
   * @param val `true` to pause the reserve, `false` to un-pause it
   */
  function setPause(bool val) external override onlyVaultConfigurator {
    _paused = val;
    if (_paused) {
      emit Paused();
    } else {
      emit Unpaused();
    }
  }

  function setFuncAddress(address fundAddress) external override onlyVaultConfigurator {
    require(fundAddress != address(0), Errors.VPC_INVALID_ADDRESSES_PROVIDER_ID);
    _reserve.fundAddress = fundAddress;
    emit FundAddressUpdated(fundAddress);
  }

  function initReserve(address oToken, address fundAddress) external override onlyVaultConfigurator {
    _reserve.init(oToken, fundAddress);
  }

  /**
   * @dev Sets the configuration bitmap of the reserve as a whole
   * - Only callable by the VaultConfigurator contract
   * @param configuration The new configuration bitmap
   **/
  function setConfiguration(uint256 configuration)
    external
    override
    onlyVaultConfigurator
  {
    _reserve.configuration.data = configuration;
  }

  function addToWhitelist(address user) external override onlyVaultConfigurator
  {
    uint256 expiration = block.timestamp + _whitelistExpiration;
    _whitelist[user] = expiration;
    emit AddedToWhitelist(user, expiration);
  }

  function batchAddToWhitelist(address[] calldata users) external override onlyVaultConfigurator
  {
    for(uint256 i = 0; i < users.length; ++i){
      uint256 expiration = block.timestamp + _whitelistExpiration;
      _whitelist[users[i]] = expiration;
      emit AddedToWhitelist(users[i], expiration);
    }
  }

  function removeFromWhitelist(address user) external override onlyVaultConfigurator
  {
    _whitelist[user] = 0;
    emit RemoveFromWhitelist(user);
  }

  function batchRemoveFromWhitelist(address[] calldata users) external override onlyVaultConfigurator
  {
    for(uint256 i = 0; i < users.length; ++i){
      _whitelist[users[i]] = 0;
      emit RemoveFromWhitelist(users[i]);
    }
  }

  function isInWhitelist(address user) external view override returns(bool)
  {
    return _whitelist[user] > block.timestamp;
  }

  function getUserExpirationTimestamp(address user) external view override returns(uint256)
  {
    return _whitelist[user];
  }

  function getWhitelistExpiration() external override returns(uint256)
  {
    return _whitelistExpiration;
  }

  function setWhitelistExpiration(uint256 expiration) external override onlyVaultConfigurator
  {
    _whitelistExpiration = expiration;
    emit WhitelistExpirationUpdated(expiration);
  }
}
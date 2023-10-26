// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {ILendPoolConfigurator} from "../interfaces/ILendPoolConfigurator.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {IBurnLockMToken} from "../interfaces/IBurnLockMToken.sol";
import {IIncentivesController} from "../interfaces/IIncentivesController.sol";
import {IncentivizedERC20} from "./IncentivizedERC20.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title ERC20 MToken
 * @dev Implementation of the interest bearing token for the MetaFire protocol
 * @author MetaFire
 */
contract BurnLockMToken is Initializable, IBurnLockMToken, IncentivizedERC20 {
  using WadRayMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  ILendPoolAddressesProvider internal _addressProvider;
  address internal _treasury;
  address internal _underlyingAsset;

  struct Deposit {
      uint256 amount;
      uint256 unlockTimestamp;
  }

  mapping(address => Deposit) private _deposits;
  uint256 public LOCK_PERIOD;

  modifier onlyLendPool() {
    require(_msgSender() == address(_getLendPool()), Errors.CT_CALLER_MUST_BE_LEND_POOL);
    _;
  }

  modifier onlyLendPoolConfigurator() {
    require(_msgSender() == address(_getLendPoolConfigurator()), Errors.LP_CALLER_NOT_LEND_POOL_CONFIGURATOR);
    _;
  }

  modifier onlyPoolAdmin() {
    require(_addressProvider.getPoolAdmin() == msg.sender, Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  /**
   * @dev Initializes the mToken
   * @param addressProvider The address of the address provider where this mToken will be used
   * @param treasury The address of the MetaFire treasury, receiving the fees on this mToken
   * @param underlyingAsset The address of the underlying asset of this mToken
   */
  function initialize(
    ILendPoolAddressesProvider addressProvider,
    address treasury,
    address underlyingAsset,
    uint8 mTokenDecimals,
    string calldata mTokenName,
    string calldata mTokenSymbol,
    uint256 lockPeriod
  ) external override initializer {
    __IncentivizedERC20_init(mTokenName, mTokenSymbol, mTokenDecimals);

    _treasury = treasury;
    _underlyingAsset = underlyingAsset;

    _addressProvider = addressProvider;
    LOCK_PERIOD = lockPeriod;

    emit Initialized(
      underlyingAsset,
      _addressProvider.getLendPool(),
      treasury,
      _addressProvider.getIncentivesController()
    );
  }

  /**
   * @dev Burns mTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * - Only callable by the LendPool, as extra state updates there need to be managed
   * @param user The owner of the mTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external override onlyLendPool {
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.CT_INVALID_BURN_AMOUNT);
    _burn(user, amountScaled);
    // _deposits[user].amount -= amountScaled;
    // IERC20Upgradeable(_underlyingAsset).safeTransfer(receiverOfUnderlying, amount);

    emit Burn(user, receiverOfUnderlying, amount, index);
  }

  /**
   * @dev Mints `amount` mTokens to `user`
   * - Only callable by the LendPool, as extra state updates there need to be managed
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address user,
    uint256 amount,
    uint256 index
  ) external override onlyLendPool returns (bool) {
    uint256 previousBalance = super.balanceOf(user);

    // index is expressed in Ray, so:
    // amount.wadToRay().rayDiv(index).rayToWad() => amount.rayDiv(index)
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.CT_INVALID_MINT_AMOUNT);
    _mint(user, amountScaled);
    // _deposits[user].amount += amountScaled;
    _deposits[user].unlockTimestamp = block.timestamp + LOCK_PERIOD;

    emit Mint(user, amount, index);

    return previousBalance == 0;
  }

  /**
   * @dev Mints mTokens to the reserve treasury
   * - Only callable by the LendPool
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external override onlyLendPool {
    if (amount == 0) {
      return;
    }

    address treasury = _treasury;

    // Compared to the normal mint, we don't check for rounding errors.
    // The amount to mint can easily be very small since it is a fraction of the interest ccrued.
    // In that case, the treasury will experience a (very small) loss, but it
    // wont cause potentially valid transactions to fail.
    _mint(treasury, amount.rayDiv(index));

    emit Transfer(address(0), treasury, amount);
    emit Mint(treasury, amount, index);
  }

  /**
   * @dev Calculates the balance of the user: principal balance + interest generated by the principal
   * @param user The user whose balance is calculated
   * @return The balance of the user
   **/
  function balanceOf(address user, DataTypes.Period period) public view override returns (uint256) {
    ILendPool pool = _getLendPool();
    return super.balanceOf(user).rayMul(pool.getReserveNormalizedIncome(_underlyingAsset, period));
  }

  /**
   * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
   * updated stored balance divided by the reserve's liquidity index at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   **/
  function scaledBalanceOf(address user) external view override returns (uint256) {
    return super.balanceOf(user);
  }

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user) external view override returns (uint256, uint256) {
    return (super.balanceOf(user), super.totalSupply());
  }

  /**
   * @dev calculates the total supply of the specific mToken
   * since the balance of every single user increases over time, the total supply
   * does that too.
   * @return the current total supply
   **/
  function totalSupply(DataTypes.Period period) public view returns (uint256) {
    uint256 currentSupplyScaled = super.totalSupply();

    if (currentSupplyScaled == 0) {
      return 0;
    }

    ILendPool pool = _getLendPool();
    return currentSupplyScaled.rayMul(pool.getReserveNormalizedIncome(_underlyingAsset, period));
  }

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return the scaled total supply
   **/
  function scaledTotalSupply() public view virtual override returns (uint256) {
    return super.totalSupply();
  }

  /**
   * @dev Returns the address of the MetaFire treasury, receiving the fees on this mToken
   **/
  function RESERVE_TREASURY_ADDRESS() public view returns (address) {
    return _treasury;
  }

  /**
   * @dev Returns the address of the underlying asset of this mToken
   **/
  function UNDERLYING_ASSET_ADDRESS() public view override returns (address) {
    return _underlyingAsset;
  }

  /**
   * @dev Returns the address of the lending pool where this mToken is used
   **/
  function POOL() public view returns (ILendPool) {
    return _getLendPool();
  }

  /**
   * @dev For internal usage in the logic of the parent contract IncentivizedERC20
   **/
  function _getIncentivesController() internal view override returns (IIncentivesController) {
    return IIncentivesController(_addressProvider.getIncentivesController());
  }

  function _getUnderlyingAssetAddress() internal view override returns (address) {
    return _underlyingAsset;
  }

  /**
   * @dev Returns the address of the incentives controller contract
   **/
  function getIncentivesController() external view override returns (IIncentivesController) {
    return _getIncentivesController();
  }

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendPool to transfer
   * assets in borrow(), withdraw() and flashLoan()
   * @param target The recipient of the mTokens
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address target, uint256 amount) external override onlyLendPool returns (uint256) {
    IERC20Upgradeable(_underlyingAsset).safeTransfer(target, amount);
    return amount;
  }

  function _getLendPool() internal view returns (ILendPool) {
    return ILendPool(_addressProvider.getLendPool());
  }

  function _getLendPoolConfigurator() internal view returns (ILendPoolConfigurator) {
    return ILendPoolConfigurator(_addressProvider.getLendPoolConfigurator());
  }

  /**
   * @dev Transfers the mTokens between two users. Validates the transfer
   * (ie checks for valid HF after the transfer) if required
   * @param from The source address
   * @param to The destination address
   * @param amount The amount getting transferred
   * @param validate `true` if the transfer needs to be validated
   **/
  function _transfer(
    address from,
    address to,
    uint256 amount,
    bool validate,
    DataTypes.Period period
  ) internal {
    address underlyingAsset = _underlyingAsset;
    ILendPool pool = _getLendPool();

    uint256 index = pool.getReserveNormalizedIncome(underlyingAsset,period);

    uint256 fromBalanceBefore = super.balanceOf(from).rayMul(index);
    uint256 toBalanceBefore = super.balanceOf(to).rayMul(index);

    super._transfer(from, to, amount.rayDiv(index));

    if (validate) {
      pool.finalizeTransfer(underlyingAsset, from, to, amount, fromBalanceBefore, toBalanceBefore, period);
    }

    emit BalanceTransfer(from, to, amount, index);
  }

  /**
   * @dev Overrides the parent _transfer to force validated transfer() and transferFrom()
   * @param from The source address
   * @param to The destination address
   * @param amount The amount getting transferred
   **/
  function _transfer(
    address from,
    address to,
    uint256 amount,
    DataTypes.Period period
  ) internal {
    _transfer(from, to, amount, true, period);
  }

  function transferFrom(address from, address to, uint256 value, DataTypes.Period period) override public returns (bool) {
      address spender = _msgSender();
      _spendAllowance(from, spender, value);
      _transfer(from, to, value, period);
      return true;
  }

  // function getUnlockedAmount(address sender) public view returns (uint256) {
  //   uint256 unlockedAmount;
  //   for (uint256 i = 0; i < _deposits[sender].length; i++) {
  //       Deposit memory deposit = _deposits[sender][i];
  //       if (block.timestamp >= deposit.timestamp + LOCK_PERIOD) {
  //           unlockedAmount = unlockedAmount + deposit.amount;
  //       }
  //   }
  //   return unlockedAmount;
  // }

  function canTransfer(address sender, uint256 amount) public view returns (bool) {

    if(sender == address(0)){
      return true;
    }

    uint256 unlockTimestamp = _deposits[sender].unlockTimestamp;
    require(unlockTimestamp <= block.timestamp , "ERC20: token transfer is locked");
    // uint256 unlockedAmount = _deposits[sender].amount;
    // require(unlockedAmount >= amount, "ERC20: insufficient balance");
    return true;
  }

  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 amount
  ) internal virtual override {
      super._beforeTokenTransfer(from, to, amount);

      require(canTransfer(from, amount), "ERC20: token transfer is locked");
  }

  //@TODO: remove this function after testing
  function setLockPeriod(uint256 lockPeriod) external onlyPoolAdmin {
    LOCK_PERIOD = lockPeriod;
  }
}
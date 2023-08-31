// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {ILendPoolConfigurator} from "../interfaces/ILendPoolConfigurator.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {IUToken} from "../interfaces/IUToken.sol";
import {IYVault} from "../interfaces/yearn/IYVault.sol";
import {IIncentivesController} from "../interfaces/IIncentivesController.sol";
import {IncentivizedERC20} from "./IncentivizedERC20.sol";

import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {LendingLogic} from "../libraries/logic/LendingLogic.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title ERC20 UToken
 * @dev Implementation of the interest bearing token for the Unlockd protocol
 * @author BendDao; Forked and edited by Unlockd
 */
contract UToken is Initializable, IUToken, IncentivizedERC20 {
  using WadRayMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  /*//////////////////////////////////////////////////////////////
                        GENERAL VARIABLES
  //////////////////////////////////////////////////////////////*/
  ILendPoolAddressesProvider internal _addressProvider;
  address internal _treasury;
  address internal _underlyingAsset;
  mapping(address => bool) internal _uTokenManagers;
  /*//////////////////////////////////////////////////////////////
                          MODIFIERS
  //////////////////////////////////////////////////////////////*/
  modifier onlyLendPool() {
    require(_msgSender() == address(_getLendPool()), Errors.CT_CALLER_MUST_BE_LEND_POOL);
    _;
  }

  modifier onlyPoolAdmin() {
    require(_msgSender() == _addressProvider.getPoolAdmin(), Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  modifier onlyUTokenManager() {
    require(_uTokenManagers[_msgSender()], Errors.CALLER_NOT_UTOKEN_MANAGER);
    _;
  }

  /*//////////////////////////////////////////////////////////////
                          INITIALIZERS
  //////////////////////////////////////////////////////////////*/
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  /**
   * @dev Initializes the uToken
   * @param addressProvider The address of the address provider where this uToken will be used
   * @param treasury The address of the Unlockd treasury, receiving the fees on this uToken
   * @param underlyingAsset The address of the underlying asset of this uToken
   */
  function initialize(
    ILendPoolAddressesProvider addressProvider,
    address treasury,
    address underlyingAsset,
    uint8 uTokenDecimals,
    string calldata uTokenName,
    string calldata uTokenSymbol
  ) external override initializer {
    __IncentivizedERC20_init(uTokenName, uTokenSymbol, uTokenDecimals);

    _treasury = treasury;
    _underlyingAsset = underlyingAsset;

    _addressProvider = addressProvider;

    emit Initialized(
      underlyingAsset,
      _addressProvider.getLendPool(),
      treasury,
      _addressProvider.getIncentivesController()
    );
  }

  /*//////////////////////////////////////////////////////////////
                        MAIN LOGIC
  //////////////////////////////////////////////////////////////*/
  /**
   * @dev Burns uTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * - Only callable by the LendPool, as extra state updates there need to be managed
   * @param user The owner of the uTokens, getting them burned
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

    IERC20Upgradeable(_underlyingAsset).safeTransfer(receiverOfUnderlying, amount);

    emit Burn(user, receiverOfUnderlying, amount, index);
  }

  /**
   * @dev Mints `amount` uTokens to `user`
   * - Only callable by the LendPool, as extra state updates there need to be managed
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(address user, uint256 amount, uint256 index) external override onlyLendPool returns (bool) {
    uint256 previousBalance = super.balanceOf(user);

    // index is expressed in Ray, so:
    // amount.wadToRay().rayDiv(index).rayToWad() => amount.rayDiv(index)
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.CT_INVALID_MINT_AMOUNT);
    _mint(user, amountScaled);

    emit Mint(user, amount, index);

    return previousBalance == 0;
  }

  /**
   * @dev Deposits `amount` to the lending protocol currently active
   * @param amount The amount of tokens to deposit
   */
  function depositReserves(uint256 amount) public override onlyUTokenManager {
    LendingLogic.executeDepositYearn(
      _addressProvider,
      DataTypes.ExecuteYearnParams({underlyingAsset: _underlyingAsset, amount: amount})
    );
  }

  /**
   * @dev Withdraws `amount` from the lending protocol currently active
   * @param amount The amount of tokens to withdraw
   */
  function withdrawReserves(uint256 amount) public override onlyUTokenManager returns (uint256) {
    uint256 value = LendingLogic.executeWithdrawYearn(
      _addressProvider,
      DataTypes.ExecuteYearnParams({underlyingAsset: _underlyingAsset, amount: amount})
    );
    return value;
  }

  /**
   * @dev Takes reserve liquidity from uToken and deposits it to external lening protocol
   **/
  function sweepUToken() external override onlyPoolAdmin {
    IERC20Upgradeable underlyingAsset = IERC20Upgradeable(_underlyingAsset);

    uint256 amount = underlyingAsset.balanceOf(address(this));

    LendingLogic.executeDepositYearn(
      _addressProvider,
      DataTypes.ExecuteYearnParams({underlyingAsset: _underlyingAsset, amount: amount})
    );

    emit UTokenSwept(address(this), address(underlyingAsset), amount);
  }

  /**
   * @dev Mints uTokens to the reserve treasury
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
   * @dev Transfers the underlying asset to `target`. Used by the LendPool to transfer
   * assets in borrow() and withdraw()
   * @param target The recipient of the uTokens
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address target, uint256 amount) external override onlyLendPool returns (uint256) {
    IERC20Upgradeable(_underlyingAsset).safeTransfer(target, amount);
    return amount;
  }

  function updateUTokenManagers(address[] calldata managers, bool flag) external override onlyPoolAdmin {
    uint256 cachedLength = managers.length;
    for (uint256 i; i < cachedLength; ) {
      require(managers[i] != address(0), Errors.INVALID_ZERO_ADDRESS);
      _uTokenManagers[managers[i]] = flag;
      unchecked {
        ++i;
      }
    }
    emit UTokenManagersUpdated(managers, flag);
  }

  /*//////////////////////////////////////////////////////////////
                          INTERNALS
  //////////////////////////////////////////////////////////////*/
  /**
   * @dev Transfers the uTokens between two users. Validates the transfer
   * (ie checks for valid HF after the transfer) if required
   * @param from The source address
   * @param to The destination address
   * @param amount The amount getting transferred
   * @param validate `true` if the transfer needs to be validated
   **/
  function _transfer(address from, address to, uint256 amount, bool validate) internal {
    address underlyingAsset = _underlyingAsset;
    ILendPool pool = _getLendPool();

    uint256 index = pool.getReserveNormalizedIncome(underlyingAsset);

    uint256 fromBalanceBefore = super.balanceOf(from).rayMul(index);
    uint256 toBalanceBefore = super.balanceOf(to).rayMul(index);

    super._transfer(from, to, amount.rayDiv(index));

    if (validate) {
      pool.finalizeTransfer(underlyingAsset, from, to, amount, fromBalanceBefore, toBalanceBefore);
    }

    emit BalanceTransfer(from, to, amount, index);
  }

  /**
   * @dev Overrides the parent _transfer to force validated transfer() and transferFrom()
   * @param from The source address
   * @param to The destination address
   * @param amount The amount getting transferred
   **/
  function _transfer(address from, address to, uint256 amount) internal override {
    _transfer(from, to, amount, true);
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

  function _getLendPool() internal view returns (ILendPool) {
    return ILendPool(_addressProvider.getLendPool());
  }

  function _getLendPoolConfigurator() internal view returns (ILendPoolConfigurator) {
    return ILendPoolConfigurator(_addressProvider.getLendPoolConfigurator());
  }

  /*//////////////////////////////////////////////////////////////
                      GETTERS & SETTERS
  //////////////////////////////////////////////////////////////*/
  /**
   * @dev Calculates the balance of the user: principal balance + interest generated by the principal
   * @param user The user whose balance is calculated
   * @return The balance of the user
   **/
  function balanceOf(address user) public view override returns (uint256) {
    ILendPool pool = _getLendPool();
    return super.balanceOf(user).rayMul(pool.getReserveNormalizedIncome(_underlyingAsset));
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
   * @dev Returns the available liquidity for the UToken's reserve
   * @return The available liquidity in reserve
   **/
  function getAvailableLiquidity() public view override returns (uint256) {
    return LendingLogic.calculateYearnAvailableLiquidityInReserve(_addressProvider);
  }

  /**
   * @dev calculates the total supply of the specific uToken
   * since the balance of every single user increases over time, the total supply
   * does that too.
   * @return the current total supply
   **/
  function totalSupply() public view override returns (uint256) {
    uint256 currentSupplyScaled = super.totalSupply();

    if (currentSupplyScaled == 0) {
      return 0;
    }

    ILendPool pool = _getLendPool();
    return currentSupplyScaled.rayMul(pool.getReserveNormalizedIncome(_underlyingAsset));
  }

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return the scaled total supply
   **/
  function scaledTotalSupply() public view virtual override returns (uint256) {
    return super.totalSupply();
  }

  /**
   * @dev Returns the address of the Unlockd treasury, receiving the fees on this uToken
   **/
  function RESERVE_TREASURY_ADDRESS() public view override returns (address) {
    return _treasury;
  }

  /**
   * @dev Sets new treasury to the specified UToken
   * @param treasury the new treasury address
   **/
  function setTreasuryAddress(address treasury) external override onlyPoolAdmin {
    require(treasury != address(0), Errors.INVALID_ZERO_ADDRESS);
    _treasury = treasury;
    emit TreasuryAddressUpdated(treasury);
  }

  /**
   * @dev Returns the address of the underlying asset of this uToken
   **/
  function UNDERLYING_ASSET_ADDRESS() public view override returns (address) {
    return _underlyingAsset;
  }

  /**
   * @dev Returns the address of the lending pool where this uToken is used
   **/
  function POOL() public view returns (ILendPool) {
    return _getLendPool();
  }

  /**
   * @dev Returns the address of the incentives controller contract
   **/
  function getIncentivesController() external view override returns (IIncentivesController) {
    return _getIncentivesController();
  }
}
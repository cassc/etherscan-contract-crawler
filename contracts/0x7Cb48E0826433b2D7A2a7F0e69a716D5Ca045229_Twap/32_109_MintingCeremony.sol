// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "./interfaces/basket/IBasketReader.sol";
import "./interfaces/IMintingCeremony.sol";

import "../external-lib/SafeDecimalMath.sol";
import "../lib/Recoverable.sol";
import "../lib/Windowed.sol";
import "../tokens/SafeSupplyControlledERC20.sol";
import "../tokens/interfaces/ISupplyControlledERC20.sol";
import "../policy/interfaces/IMonetaryPolicy.sol";

/**
 * @title Minting Ceremony
 * @dev Note that this is recoverable as it should never store any tokens.
 */
contract MintingCeremony is
  IMintingCeremony,
  Windowed,
  Recoverable,
  ReentrancyGuard
{
  using SafeMath for uint256;
  using SafeDecimalMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for ISupplyControlledERC20;
  using SafeSupplyControlledERC20 for ISupplyControlledERC20;

  /* ========== CONSTANTS ========== */
  uint8 public constant ALLOWANCE_FACTOR = 100;
  uint32 private constant CEREMONY_DURATION = 6 days;

  /* ========== STATE VARIABLES ========== */
  // Monetary Policy Contract that decides the target price
  IMonetaryPolicy internal immutable monetaryPolicy;
  ISupplyControlledERC20 internal immutable float;
  IBasketReader internal immutable basket;

  // Tokens that set allowance
  IERC20[] internal allowanceTokens;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  /**
   * @notice Constructs a new Minting Ceremony
   */
  constructor(
    address governance_,
    address monetaryPolicy_,
    address basket_,
    address float_,
    address[] memory allowanceTokens_,
    uint256 ceremonyStart
  ) Windowed(ceremonyStart, ceremonyStart + CEREMONY_DURATION) {
    require(governance_ != address(0), "MC/ZeroAddress");
    require(monetaryPolicy_ != address(0), "MC/ZeroAddress");
    require(basket_ != address(0), "MC/ZeroAddress");
    require(float_ != address(0), "MC/ZeroAddress");

    monetaryPolicy = IMonetaryPolicy(monetaryPolicy_);
    basket = IBasketReader(basket_);
    float = ISupplyControlledERC20(float_);

    for (uint256 i = 0; i < allowanceTokens_.length; i++) {
      IERC20 allowanceToken = IERC20(allowanceTokens_[i]);
      allowanceToken.balanceOf(address(0)); // Check that this is a valid token

      allowanceTokens.push(allowanceToken);
    }

    _setupRole(RECOVER_ROLE, governance_);
  }

  /* ========== EVENTS ========== */

  event Committed(address indexed user, uint256 amount);
  event Minted(address indexed user, uint256 amount);

  /* ========== VIEWS ========== */

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function underlying()
    public
    view
    override(IMintingCeremony)
    returns (address)
  {
    return basket.underlying();
  }

  /**
   * @notice The allowance remaining for an account.
   * @dev Based on the current staked balance in `allowanceTokens` and the existing allowance.
   */
  function allowance(address account)
    public
    view
    override(IMintingCeremony)
    returns (uint256 remainingAllowance)
  {
    uint256 stakedBalance = 0;
    for (uint256 i = 0; i < allowanceTokens.length; i++) {
      stakedBalance = stakedBalance.add(allowanceTokens[i].balanceOf(account));
    }
    remainingAllowance = stakedBalance.mul(ALLOWANCE_FACTOR).sub(
      _balances[account]
    );
  }

  /**
   * @notice Simple conversion using monetary policy.
   */
  function quote(uint256 wethIn) public view returns (uint256) {
    uint256 targetPriceInEth = monetaryPolicy.consult();

    require(targetPriceInEth != 0, "MC/MPFailure");

    return wethIn.divideDecimalRoundPrecise(targetPriceInEth);
  }

  /**
   * @notice The amount out accounting for quote & allowance.
   */
  function amountOut(address recipient, uint256 underlyingIn)
    public
    view
    returns (uint256 floatOut)
  {
    // External calls occur here, but trusted
    uint256 floatOutFromPrice = quote(underlyingIn);
    uint256 floatOutFromAllowance = allowance(recipient);

    floatOut = Math.min(floatOutFromPrice, floatOutFromAllowance);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Commit a quanity of wETH at the current price
   * @dev This is marked non-reentrancy to protect against a malicious
   * allowance token or monetary policy (these are trusted however).
   *
   * - Expects `msg.sender` to give approval to this contract from `basket.underlying()` for at least `underlyingIn`
   *
   * @param recipient The eventual receiver of the float
   * @param underlyingIn The underlying token amount to commit to mint
   * @param floatOutMin The minimum amount of FLOAT that must be received for this transaction not to revert.
   */
  function commit(
    address recipient,
    uint256 underlyingIn,
    uint256 floatOutMin
  )
    external
    override(IMintingCeremony)
    nonReentrant
    inWindow
    returns (uint256 floatOut)
  {
    floatOut = amountOut(recipient, underlyingIn);
    require(floatOut >= floatOutMin, "MC/SlippageOrLowAllowance");
    require(floatOut != 0, "MC/NoAllowance");

    _totalSupply = _totalSupply.add(floatOut);
    _balances[recipient] = _balances[recipient].add(floatOut);

    emit Committed(recipient, floatOut);

    IERC20(underlying()).safeTransferFrom(
      msg.sender,
      address(basket),
      underlyingIn
    );
  }

  /**
   * @notice Release the float to market which has been committed.
   */
  function mint() external override(IMintingCeremony) afterWindow {
    uint256 balance = balanceOf(msg.sender);
    require(balance != 0, "MC/NotDueFloat");

    _totalSupply = _totalSupply.sub(balance);
    _balances[msg.sender] = _balances[msg.sender].sub(balance);

    emit Minted(msg.sender, balance);

    float.safeMint(msg.sender, balance);
  }
}
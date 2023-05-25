// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../external-lib/SafeDecimalMath.sol";

import "./interfaces/IBasket.sol";
import "./BasketMath.sol";

/**
 * @title Float Protocol Basket
 * @notice The logic contract for storing underlying ETH (as wETH)
 */
contract BasketV1 is IBasket, Initializable, AccessControlUpgradeable {
  using SafeMath for uint256;
  using SafeDecimalMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== CONSTANTS ========== */
  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  bytes32 public constant AUCTION_HOUSE_ROLE = keccak256("AUCTION_HOUSE_ROLE");

  /* ========== STATE VARIABLES ========== */
  IERC20 public float;
  IERC20 private weth;

  /**
   * @notice The target ratio for "collateralisation"
   * @dev [e27] Start at 100%
   */
  uint256 public targetRatio;

  function initialize(
    address _admin,
    address _weth,
    address _float
  ) external initializer {
    weth = IERC20(_weth);
    float = IERC20(_float);
    targetRatio = SafeDecimalMath.PRECISE_UNIT;

    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    _setupRole(GOVERNANCE_ROLE, _admin);
  }

  /* ========== MODIFIERS ========== */

  modifier onlyGovernance {
    require(
      hasRole(GOVERNANCE_ROLE, _msgSender()),
      "AuctionHouse/GovernanceRole"
    );
    _;
  }

  /* ========== VIEWS ========== */

  /// @inheritdoc IBasketReader
  function underlying() public view override(IBasketReader) returns (address) {
    return address(weth);
  }

  /// @inheritdoc IBasketReader
  function getBasketFactor(uint256 targetPriceInEth)
    external
    view
    override(IBasketReader)
    returns (uint256 basketFactor)
  {
    uint256 wethInBasket = weth.balanceOf(address(this));
    uint256 floatTotalSupply = float.totalSupply();

    return
      basketFactor = BasketMath.calcBasketFactor(
        targetPriceInEth,
        wethInBasket,
        floatTotalSupply,
        targetRatio
      );
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /* ----- onlyGovernance ----- */

  /// @inheritdoc IBasketGovernedActions
  function buildAuctionHouse(address _auctionHouse, uint256 _allowance)
    external
    override(IBasketGovernedActions)
    onlyGovernance
  {
    grantRole(AUCTION_HOUSE_ROLE, _auctionHouse);
    weth.safeApprove(_auctionHouse, 0);
    weth.safeApprove(_auctionHouse, _allowance);
  }

  /// @inheritdoc IBasketGovernedActions
  function burnAuctionHouse(address _auctionHouse)
    external
    override(IBasketGovernedActions)
    onlyGovernance
  {
    revokeRole(AUCTION_HOUSE_ROLE, _auctionHouse);
    weth.safeApprove(_auctionHouse, 0);
  }

  /// @inheritdoc IBasketGovernedActions
  function setTargetRatio(uint256 _targetRatio)
    external
    override(IBasketGovernedActions)
    onlyGovernance
  {
    require(
      _targetRatio <= BasketMath.MAX_TARGET_RATIO,
      "BasketV1/RatioTooHigh"
    );
    require(
      _targetRatio >= BasketMath.MIN_TARGET_RATIO,
      "BasketV1/RatioTooLow"
    );
    targetRatio = _targetRatio;

    emit NewTargetRatio(_targetRatio);
  }
}
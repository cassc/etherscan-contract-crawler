// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { IStrategy } from "./interfaces/IStrategy.sol";
import { IPancakeSwapFarm } from "./interfaces/IPancakeSwapFarm.sol";
import { IPancakeRouter02 } from "./interfaces/IPancakeRouter02.sol";

uint256 constant N_COINS = 2;

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
interface IStableSwap {
  function get_dy(
    uint256 i,
    uint256 j,
    uint256 dx
  ) external view returns (uint256);

  function exchange(
    uint256 i,
    uint256 j,
    uint256 dx,
    uint256 min_dy
  ) external;

  function add_liquidity(uint256[N_COINS] memory amounts, uint256 min_mint_amount) external;
}

// solhint-disable max-states-count
contract StableCoinStrategyCurve is
  IStrategy,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable
{
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event AutoharvestChanged(bool value);
  event MinEarnAmountChanged(uint256 indexed oldAmount, uint256 indexed newAmount);

  uint256 public pid;
  address public farmContractAddress;
  address public want;
  address public cake;
  address public token0;
  address public token1;
  address public router;
  address public stableSwap;
  address public helioFarming;

  address[] public earnedToStablePath;

  uint256 public i0;
  uint256 public i1;

  bool public enableAutoHarvest;

  uint256 public wantLockedTotal;
  uint256 public sharesTotal;

  uint256 public minEarnAmount;
  uint256 public constant MIN_EARN_AMOUNT_LL = 10**10;

  modifier onlyHelioFarming() {
    require(msg.sender == helioFarming, "!helio Farming");
    _;
  }

  // 0 address _farmContractAddress,
  // 1 address _want,
  // 2 address _cake,
  // 3 address _token0,
  // 4 address _token1,
  // 5 address _router,
  // 6 address _stableSwap,
  // 7 address _helioFarming,
  function initialize(
    uint256 _pid,
    uint256 _i0,
    uint256 _i1,
    uint256 _minEarnAmount,
    bool _enableAutoHarvest,
    address[] memory _addresses,
    address[] memory _earnedToStablePath
  ) public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();
    require(_minEarnAmount >= MIN_EARN_AMOUNT_LL, "min earn amount is too low");
    pid = _pid;
    i0 = _i0;
    i1 = _i1;
    minEarnAmount = _minEarnAmount;
    farmContractAddress = _addresses[0];
    want = _addresses[1];
    cake = _addresses[2];
    token0 = _addresses[3];
    token1 = _addresses[4];
    router = _addresses[5];
    stableSwap = _addresses[6];
    helioFarming = _addresses[7];
    enableAutoHarvest = _enableAutoHarvest;
    earnedToStablePath = _earnedToStablePath;
  }

  // Receives new deposits from user
  function deposit(address, uint256 _wantAmt)
    public
    virtual
    override
    onlyHelioFarming
    whenNotPaused
    returns (uint256)
  {
    if (enableAutoHarvest) {
      _harvest();
    }
    IERC20Upgradeable(want).safeTransferFrom(address(msg.sender), address(this), _wantAmt);

    uint256 sharesAdded = _wantAmt;

    uint256 sharesTotalLocal = sharesTotal;
    uint256 wantLockedTotalLocal = wantLockedTotal;

    if (wantLockedTotalLocal > 0 && sharesTotalLocal > 0) {
      sharesAdded = (_wantAmt * sharesTotalLocal) / wantLockedTotalLocal;
    }
    sharesTotal = sharesTotalLocal + sharesAdded;

    _farm();

    return sharesAdded;
  }

  function withdraw(address, uint256 _wantAmt)
    public
    virtual
    override
    onlyHelioFarming
    nonReentrant
    returns (uint256)
  {
    require(_wantAmt > 0, "_wantAmt <= 0");

    if (enableAutoHarvest) {
      _harvest();
    }

    uint256 sharesRemoved = (_wantAmt * sharesTotal) / wantLockedTotal;

    uint256 sharesTotalLocal = sharesTotal;
    if (sharesRemoved > sharesTotalLocal) {
      sharesRemoved = sharesTotalLocal;
    }
    sharesTotal = sharesTotalLocal - sharesRemoved;

    _unfarm(_wantAmt);

    uint256 wantAmt = IERC20Upgradeable(want).balanceOf(address(this));
    if (_wantAmt > wantAmt) {
      _wantAmt = wantAmt;
    }

    if (wantLockedTotal < _wantAmt) {
      _wantAmt = wantLockedTotal;
    }

    wantLockedTotal -= _wantAmt;

    IERC20Upgradeable(want).safeTransfer(helioFarming, _wantAmt);

    return sharesRemoved;
  }

  function inCaseTokensGetStuck(
    address _token,
    uint256 _amount,
    address _to
  ) public virtual onlyOwner {
    require(_token != cake, "!safe");
    require(_token != want, "!safe");
    IERC20Upgradeable(_token).safeTransfer(_to, _amount);
  }

  function pause() public virtual onlyOwner {
    _pause();
  }

  function unpause() public virtual onlyOwner {
    _unpause();
  }

  function farm() public virtual nonReentrant {
    _farm();
  }

  function _farm() internal virtual {
    uint256 wantAmt = IERC20Upgradeable(want).balanceOf(address(this));
    wantLockedTotal += wantAmt;
    IERC20Upgradeable(want).safeIncreaseAllowance(farmContractAddress, wantAmt);

    IPancakeSwapFarm(farmContractAddress).deposit(pid, wantAmt);
  }

  function _unfarm(uint256 _wantAmt) internal virtual {
    IPancakeSwapFarm(farmContractAddress).withdraw(pid, _wantAmt);
  }

  // 1. Harvest farm tokens
  // 2. Converts farm tokens into want tokens
  // 3. Deposits want tokens
  function harvest() public virtual nonReentrant whenNotPaused {
    _harvest();
  }

  // 1. Harvest farm tokens
  // 2. Converts farm tokens into want tokens
  // 3. Deposits want tokens
  function _harvest() internal virtual {
    // Harvest farm tokens
    _unfarm(0);

    // Converts farm tokens into want tokens
    uint256 earnedAmt = IERC20Upgradeable(cake).balanceOf(address(this));

    IERC20Upgradeable(cake).safeApprove(router, 0);
    IERC20Upgradeable(cake).safeIncreaseAllowance(router, earnedAmt);

    if (earnedAmt < minEarnAmount) {
      return;
    }

    _safeSwapUni(router, earnedAmt, earnedToStablePath, address(this), block.timestamp + 700);

    uint256 token1Amt = IERC20Upgradeable(token1).balanceOf(address(this));
    IERC20Upgradeable(token1).safeApprove(stableSwap, 0);
    IERC20Upgradeable(token1).safeIncreaseAllowance(stableSwap, token1Amt);

    _safeSwapCurve(stableSwap, i1, i0, token1Amt / 2);

    // Get want tokens, ie. add liquidity
    uint256 token0Amt = IERC20Upgradeable(token0).balanceOf(address(this));
    token1Amt = IERC20Upgradeable(token1).balanceOf(address(this));
    if (token0Amt > 0 && token1Amt > 0) {
      uint256[N_COINS] memory amounts;
      amounts[0] = token0Amt;
      amounts[1] = token1Amt;
      IERC20Upgradeable(token0).safeIncreaseAllowance(stableSwap, token0Amt);
      IERC20Upgradeable(token1).safeIncreaseAllowance(stableSwap, token1Amt);
      IStableSwap(stableSwap).add_liquidity(amounts, 0);
    }

    _farm();
  }

  function _safeSwapCurve(
    address _stableSwap,
    uint256 _i,
    uint256 _j,
    uint256 _dx
  ) internal virtual {
    IStableSwap(_stableSwap).exchange(_i, _j, _dx, 0);
  }

  function _safeSwapUni(
    address _uniRouterAddress,
    uint256 _amountIn,
    address[] memory _path,
    address _to,
    uint256 _deadline
  ) internal virtual {
    IPancakeRouter02(_uniRouterAddress).swapExactTokensForTokens(
      _amountIn,
      0,
      _path,
      _to,
      _deadline
    );
  }

  function setAutoHarvest(bool _value) external onlyOwner {
    enableAutoHarvest = _value;
    emit AutoharvestChanged(_value);
  }

  function setMinEarnAmount(uint256 _minEarnAmount) external onlyOwner {
    require(_minEarnAmount >= MIN_EARN_AMOUNT_LL, "min earn amount is too low");
    emit MinEarnAmountChanged(minEarnAmount, _minEarnAmount);
    minEarnAmount = _minEarnAmount;
  }
}
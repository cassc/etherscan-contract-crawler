// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/convex/IConvexDeposit.sol";
import "../interfaces/convex/IConvexRewards.sol";

/// @notice This contract provides common functions that will be used by all Convex strategies.
contract ConvexBase {
  using SafeERC20 for IERC20;

  address private constant CONVEX_TOKEN_ADDRESS = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

  // The pool id. This is unique for each Curve pool.
  uint256 public poolId;
  // The address of the Convex booster contract
  address public convexBooster;
  // The address of the Rewards contract for the pool. Different for each pool
  address public cvxRewards;
  // The address of the LP token that the booster contract will accept for a pool
  address public lpToken;
  // Store dex approval status to avoid excessive approvals
  mapping(address => bool) internal cvxDexApprovals;

  /// @param _pooId the id of the pool
  /// @param _booster the address of the booster contract
  constructor(uint256 _pooId, address _booster) {
    require(_booster != address(0), "invalid booster address");
    poolId = _pooId;
    convexBooster = _booster;
    (lpToken, , , cvxRewards, , ) = IConvexDeposit(convexBooster).poolInfo(poolId);
    _approveConvexExtra();
  }

  // Need to allow booster to access the lp tokens for deposit
  function _approveConvexExtra() internal virtual {
    IERC20(lpToken).safeApprove(convexBooster, type(uint256).max);
  }

  // Need to allow dex to access the Convex tokens for swaps
  function _approveDexExtra(address _dex) internal {
    if (!cvxDexApprovals[_dex]) {
      cvxDexApprovals[_dex] = true;
      IERC20(_getConvexTokenAddress()).safeApprove(_dex, type(uint256).max);
    }
  }

  // Keep CRV, CVX and the pool lp tokens in the strategy. Everything else can be sent to somewhere else.
  function _buildProtectedTokens(address _curveToken) internal view returns (address[] memory) {
    address[] memory protected = new address[](3);
    protected[0] = _curveToken;
    protected[1] = _getConvexTokenAddress();
    protected[2] = lpToken;
    return protected;
  }

  /// @dev Add Curve LP tokens to Convex booster
  function _depositToConvex() internal {
    uint256 balance = IERC20(lpToken).balanceOf(address(this));
    if (balance > 0) {
      IConvexDeposit(convexBooster).depositAll(poolId, true);
    }
  }

  /// @dev Return the amount of Curve LP tokens.
  ///  The Curve LP tokens are eventually deposited into the Rewards contract, and we can query it to get the balance.
  function _getConvexBalance() internal view returns (uint256) {
    return IConvexRewards(cvxRewards).balanceOf(address(this));
  }

  /// @dev When withdraw, withdraw the LP tokens from the Rewards contract and claim rewards. Unwrap these to Curve LP tokens.
  /// @param _amount The amount of rewards (1:1 to LP tokens) to withdraw.
  function _withdrawFromConvex(uint256 _amount) internal {
    IConvexRewards(cvxRewards).withdrawAndUnwrap(_amount, true);
  }

  function _getConvexTokenAddress() internal view virtual returns (address) {
    return CONVEX_TOKEN_ADDRESS;
  }

  /// @dev Get the rewards (CRV and CVX) from Convex, and swap them for the `want` tokens.
  function _claimConvexRewards(address _curveTokenAddress, function(address, uint256) returns (uint256) _swapFunc)
    internal
    virtual
  {
    IConvexRewards(cvxRewards).getReward(address(this), true);
    uint256 crvBalance = IERC20(_curveTokenAddress).balanceOf(address(this));
    uint256 convexBalance = IERC20(_getConvexTokenAddress()).balanceOf(address(this));
    _swapFunc(_curveTokenAddress, crvBalance);
    _swapFunc(_getConvexTokenAddress(), convexBalance);
  }

  /// @dev calculate the value of the convex rewards in want token.
  ///  It will calculate how many CVX tokens can be claimed based on the _crv amount and then swap them to want
  function _convexRewardsValue(address _curveTokenAddress, function(address, uint256) view returns (uint256) _quoteFunc)
    internal
    view
    returns (uint256)
  {
    uint256 _crv = IConvexRewards(cvxRewards).earned(address(this));

    if (_crv > 0) {
      // calculations pulled directly from CVX's contract for minting CVX per CRV claimed
      uint256 totalCliffs = 1000;
      uint256 maxSupply = 1e8 * 1e18; // 100m
      uint256 reductionPerCliff = 1e5 * 1e18; // 100k
      uint256 supply = IERC20(_getConvexTokenAddress()).totalSupply();
      uint256 _cvx;

      uint256 cliff = supply / reductionPerCliff;
      // mint if below total cliffs
      if (cliff < totalCliffs) {
        // for reduction% take inverse of current cliff
        uint256 reduction = totalCliffs - cliff;
        // reduce
        _cvx = (_crv * reduction) / totalCliffs;

        // supply cap check
        uint256 amtTillMax = maxSupply - supply;
        if (_cvx > amtTillMax) {
          _cvx = amtTillMax;
        }
      }
      uint256 rewardsValue;

      rewardsValue += _quoteFunc(_curveTokenAddress, _crv);
      if (_cvx > 0) {
        rewardsValue += _quoteFunc(_getConvexTokenAddress(), _cvx);
      }
      return rewardsValue;
    }
    return 0;
  }
}
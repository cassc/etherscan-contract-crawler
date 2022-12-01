// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/convex/IConvexForCurve.sol";
import "../../strategies/curve/Curve.sol";

// Convex Strategies common variables and helper functions
contract Convex is Curve {
    using SafeERC20 for IERC20;

    address public constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    IConvex public constant BOOSTER = IConvex(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    Rewards public immutable cvxCrvRewards;
    uint256 public immutable convexPoolId;

    struct ClaimableRewardInfo {
        address token;
        uint256 amount;
    }

    constructor(
        address pool_,
        address crvPool_,
        PoolType curvePoolType_,
        address depositZap_,
        address crvToken_,
        uint256 crvSlippage_,
        address masterOracle_,
        address swapper_,
        uint256 collateralIdx_,
        uint256 convexPoolId_,
        string memory name_
    )
        Curve(
            pool_,
            crvPool_,
            curvePoolType_,
            depositZap_,
            crvToken_,
            crvSlippage_,
            masterOracle_,
            swapper_,
            collateralIdx_,
            name_
        )
    {
        (address _lp, , , address _reward, , ) = BOOSTER.poolInfo(convexPoolId_);
        require(_lp == address(crvLp), "incorrect-lp-token");
        cvxCrvRewards = Rewards(_reward);
        convexPoolId = convexPoolId_;
        rewardTokens = _getRewardTokens();
    }

    function lpBalanceStaked() public view override returns (uint256 _total) {
        _total = cvxCrvRewards.balanceOf(address(this));
    }

    function _approveToken(uint256 amount_) internal virtual override {
        super._approveToken(amount_);
        crvLp.safeApprove(address(BOOSTER), amount_);
    }

    function _claimRewards() internal override {
        require(cvxCrvRewards.getReward(address(this), true), "reward-claim-failed");
    }

    /**
     * @notice Add reward tokens
     * The Convex pools have CRV and CVX as base rewards and may have others tokens as extra rewards
     * In some cases, CVX is also added as extra reward, reason why we have to ensure to not add it twice
     * @return _rewardTokens The array of reward tokens (both base and extra rewards)
     */
    function _getRewardTokens() private view returns (address[] memory _rewardTokens) {
        uint256 _extraRewardCount;
        uint256 _length = cvxCrvRewards.extraRewardsLength();

        for (uint256 i; i < _length; i++) {
            address _rewardToken = Rewards(cvxCrvRewards.extraRewards(i)).rewardToken();
            // Some pool has CVX as extra rewards but other do not. CVX still reward token
            if (_rewardToken != CRV && _rewardToken != CVX) {
                _extraRewardCount++;
            }
        }

        _rewardTokens = new address[](_extraRewardCount + 2);
        _rewardTokens[0] = CRV;
        _rewardTokens[1] = CVX;
        uint256 _nextIdx = 2;

        for (uint256 i; i < _length; i++) {
            address _rewardToken = Rewards(cvxCrvRewards.extraRewards(i)).rewardToken();
            // CRV and CVX already added in array
            if (_rewardToken != CRV && _rewardToken != CVX) {
                _rewardTokens[_nextIdx++] = _rewardToken;
            }
        }
    }

    function _stakeAllLp() internal virtual override {
        uint256 _balance = crvLp.balanceOf(address(this));
        if (_balance > 0) {
            require(BOOSTER.deposit(convexPoolId, _balance, true), "booster-deposit-failed");
        }
    }

    /**
     * @notice Unstake all LPs
     * @dev This function is called by `_beforeMigration()` hook
     * Should claim rewards that will be swept later
     */
    function _unstakeAllLp() internal override {
        cvxCrvRewards.withdrawAllAndUnwrap(true);
    }

    /**
     * @notice Unstake LPs
     * Don't claiming rewards because `_claimRewards()` already does that
     */
    function _unstakeLp(uint256 _amount) internal override {
        if (_amount > 0) {
            require(cvxCrvRewards.withdrawAndUnwrap(_amount, false), "withdraw-and-unwrap-failed");
        }
    }

    /// @dev convex pool can add new rewards. This method refresh list.
    function setRewardTokens(
        address[] memory /*_rewardTokens*/
    ) external override onlyKeeper {
        // Claims all rewards, if any, before updating the reward list
        _claimRewardsAndConvertTo(address(collateralToken));
        rewardTokens = _getRewardTokens();
        _approveToken(0);
        _approveToken(MAX_UINT_VALUE);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../interfaces/stargate/IStargatePool.sol";
import "../../interfaces/stargate/IStargateRouter.sol";
import "../../interfaces/stargate/IStargateFactory.sol";
import "../../interfaces/stargate/IStargateLpStaking.sol";
import "../Strategy.sol";

/// @title This Strategy will deposit collateral token in a Stargate Pool
/// Stake LP Token and accrue swap rewards
contract Stargate is Strategy {
    using SafeERC20 for IERC20;
    using SafeERC20 for IStargatePool;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.0.0";

    /// @notice Address of Staking contract (MasterChef V2 behavior)
    IStargateLpStaking public immutable stargateLpStaking;
    /// @notice Reward pool id of the MasterChef
    uint256 public immutable stargateLpStakingPoolId;
    /// @notice Stargate Factory LP Pool Id
    uint256 public immutable stargatePoolId;

    /// @notice rewardToken, usually STG
    address public immutable rewardToken;

    IStargatePool internal immutable stargateLp;

    /// @dev Router to add/remove liquidity from a STG Pool
    IStargateRouter internal immutable stargateRouter;

    constructor(
        address _pool,
        address _swapper,
        address _stargateRouter,
        address _stargateLpStaking,
        uint256 _stargatePoolId,
        uint256 _stargateLpStakingPoolId,
        string memory _name
    ) Strategy(_pool, _swapper, address(0)) {
        require(_stargateRouter != address(0), "stg-router-is-zero");
        require(_stargateLpStaking != address(0), "stg-staking-is-zero");
        require(_stargatePoolId > 0, "stg-pool-is-zero");

        stargateRouter = IStargateRouter(_stargateRouter);
        stargateLpStaking = IStargateLpStaking(_stargateLpStaking);
        IStargatePool _stargateLp = IStargatePool(IStargateFactory(stargateRouter.factory()).getPool(_stargatePoolId));
        require(address(collateralToken) == _stargateLp.token(), "wrong-pool-id");
        receiptToken = address(_stargateLp);
        stargateLp = _stargateLp;
        stargatePoolId = _stargatePoolId;
        stargateLpStakingPoolId = _stargateLpStakingPoolId; // can be 0
        rewardToken = stargateLpStaking.stargate();
        NAME = _name;
    }

    function isReservedToken(address _token) public view override returns (bool) {
        return _token == receiptToken;
    }

    function lpAmountStaked() public view returns (uint256 _lpAmountStaked) {
        (_lpAmountStaked, ) = stargateLpStaking.userInfo(stargateLpStakingPoolId, address(this));
    }

    function pendingStargate() external view returns (uint256 _pendingStargate) {
        return stargateLpStaking.pendingStargate(stargateLpStakingPoolId, address(this));
    }

    function tvl() external view override returns (uint256) {
        return _getCollateralInStargate() + collateralToken.balanceOf(address(this));
    }

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override {
        super._approveToken(_amount);
        collateralToken.safeApprove(address(stargateRouter), _amount);
        stargateLp.safeApprove(address(stargateLpStaking), _amount);
        stargateLp.safeApprove(address(stargateRouter), _amount);
        IERC20(rewardToken).safeApprove(address(swapper), _amount);
    }

    /**
     * @notice Before migration hook.
     */
    function _beforeMigration(address _newStrategy) internal override {
        require(IStrategy(_newStrategy).token() == receiptToken, "wrong-receipt-token");
        stargateLpStaking.withdraw(stargateLpStakingPoolId, lpAmountStaked());
    }

    /// @notice Claim rewardToken from LPStaking contract
    function _claimRewardsAndConvertTo(address _toToken) internal {
        // 0 withdraw will trigger rewards claim
        stargateLpStaking.withdraw(stargateLpStakingPoolId, 0);
        uint256 _rewardAmount = IERC20(rewardToken).balanceOf(address(this));
        if (_rewardAmount > 0) {
            _safeSwapExactInput(rewardToken, _toToken, _rewardAmount);
        }
    }

    /// @dev Converts a collateral amount in its relative shares of STG LP Token
    function _convertToLpShares(uint256 _collateralAmount) internal view returns (uint256) {
        uint256 _totalLiquidity = stargateLp.totalLiquidity();
        // amount SD = _collateralAmount / stargateLp.convertRate()
        // amount LP = SD * totalSupply / totalLiquidity
        return
            (_totalLiquidity > 0)
                ? ((_collateralAmount / stargateLp.convertRate()) * stargateLp.totalSupply()) / _totalLiquidity
                : 0;
    }

    /// @dev Gets collateral balance deposited into STG Pool
    function _getCollateralInStargate() internal view returns (uint256 _collateralStaked) {
        return stargateLp.amountLPtoLD(lpAmountStaked() + stargateLp.balanceOf(address(this)));
    }

    function _getLpForCollateral(uint256 _collateralAmount) internal returns (uint256) {
        uint256 _lpRequired = _convertToLpShares(_collateralAmount);
        uint256 _lpHere = stargateLp.balanceOf(address(this));
        if (_lpRequired > _lpHere) {
            uint256 _lpAmountStaked = lpAmountStaked();
            uint256 _lpToUnstake = _lpRequired - _lpHere;
            if (_lpToUnstake > _lpAmountStaked) {
                _lpToUnstake = _lpAmountStaked;
            }
            stargateLpStaking.withdraw(stargateLpStakingPoolId, _lpToUnstake);
            return stargateLp.balanceOf(address(this));
        }
        return _lpRequired;
    }

    function _rebalance()
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));

        // Claim any reward we have.
        _claimRewardsAndConvertTo(address(collateralToken));

        uint256 _collateralHere = collateralToken.balanceOf(address(this));

        uint256 _totalCollateral = _getCollateralInStargate() + _collateralHere;

        if (_totalCollateral > _totalDebt) {
            _profit = _totalCollateral - _totalDebt;
        } else {
            _loss = _totalDebt - _totalCollateral;
        }
        uint256 _profitAndExcessDebt = _profit + _excessDebt;
        if (_profitAndExcessDebt > _collateralHere) {
            _withdrawHere(_profitAndExcessDebt - _collateralHere);
            _collateralHere = collateralToken.balanceOf(address(this));
        }

        // Make sure _collateralHere >= _payback + profit. set actual payback first and then profit
        _payback = Math.min(_collateralHere, _excessDebt);
        _profit = _collateralHere > _payback ? Math.min((_collateralHere - _payback), _profit) : 0;

        IVesperPool(pool).reportEarning(_profit, _loss, _payback);

        // strategy may get new fund. Deposit and stake it to stargate
        _collateralHere = collateralToken.balanceOf(address(this));
        if (_collateralHere > 0) {
            stargateRouter.addLiquidity(stargatePoolId, _collateralHere, address(this));
            stargateLpStaking.deposit(stargateLpStakingPoolId, stargateLp.balanceOf(address(this)));
        }
    }

    /// @dev Withdraw collateral here. Do not transfer to pool.
    /// @dev This method may withdraw less than requested amount. Caller may need to check balance before and after
    function _withdrawHere(uint256 _amount) internal override {
        stargateRouter.instantRedeemLocal(uint16(stargatePoolId), _getLpForCollateral(_amount), address(this));
    }

    /************************************************************************************************
     *                                       keeper function                                        *
     ***********************************************************************************************/

    function withdrawForRebalance(uint16 _dstChainId) external payable onlyKeeper {
        // amountToWithdraw is excessDebt of strategy
        uint256 _amountToWithdraw = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));
        uint256 _totalCollateral = _getCollateralInStargate();

        if (_totalCollateral > _totalDebt) {
            // If we have profit then amountToWithdraw = excessDebt + profit
            _amountToWithdraw += (_totalCollateral - _totalDebt);
        }

        uint256 _lpToRedeem = _getLpForCollateral(_amountToWithdraw);
        if (_lpToRedeem > 0) {
            // RedeemLocal will redeem asset from dstChain to this chain and at this address.
            // Also srcPoolId and dstPoolId will be same in this case
            stargateRouter.redeemLocal{value: msg.value}(
                _dstChainId,
                stargatePoolId,
                stargatePoolId,
                payable(msg.sender),
                _lpToRedeem,
                abi.encodePacked(address(this)), // Address which will receive asset
                IStargateRouter.lzTxObj(0, 0, "0x") // Basically empty layer zero tx object
            );
        }
    }
}
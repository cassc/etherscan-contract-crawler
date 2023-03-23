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
    string public constant VERSION = "5.1.0";

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
        address pool_,
        address swapper_,
        IStargateRouter stargateRouter_,
        IStargatePool stargateLp_,
        IStargateLpStaking stargateLpStaking_,
        uint256 stargatePoolId_,
        uint256 stargateLpStakingPoolId_,
        string memory name_
    ) Strategy(pool_, swapper_, address(0)) {
        require(address(stargateRouter_) != address(0), "stg-router-is-zero");
        require(address(stargateLp_) != address(0), "stg-lp-pool-is-zero");
        require(address(stargateLpStaking_) != address(0), "stg-staking-is-zero");
        require(stargatePoolId_ > 0, "stg-pool-is-zero");

        stargateRouter = stargateRouter_;
        stargateLpStaking = IStargateLpStaking(stargateLpStaking_);
        receiptToken = address(stargateLp_);
        stargateLp = stargateLp_;
        stargatePoolId = stargatePoolId_;
        stargateLpStakingPoolId = stargateLpStakingPoolId_; // can be 0
        rewardToken = stargateLpStaking.stargate();
        NAME = name_;
    }

    function isReservedToken(address token_) public view override returns (bool) {
        return token_ == receiptToken;
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

    function _approveToken(uint256 _amount) internal virtual override {
        super._approveToken(_amount);
        collateralToken.safeApprove(address(stargateRouter), _amount);
        stargateLp.safeApprove(address(stargateLpStaking), _amount);
        stargateLp.safeApprove(address(stargateRouter), _amount);
        IERC20(rewardToken).safeApprove(address(swapper), _amount);
    }

    // solhint-disable-next-line no-empty-blocks
    function _beforeDeposit(uint256 collateralAmount_) internal virtual {}

    /**
     * @notice Before migration hook.
     */
    function _beforeMigration(address newStrategy_) internal override {
        require(IStrategy(newStrategy_).token() == receiptToken, "wrong-receipt-token");
        stargateLpStaking.withdraw(stargateLpStakingPoolId, lpAmountStaked());
    }

    /// @notice Claim rewardToken from LPStaking contract
    function _claimRewards() internal override returns (address, uint256) {
        // 0 withdraw will trigger rewards claim
        stargateLpStaking.withdraw(stargateLpStakingPoolId, 0);
        return (rewardToken, IERC20(rewardToken).balanceOf(address(this)));
    }

    /// @dev Converts a collateral amount in its relative shares of STG LP Token
    function _convertToLpShares(uint256 collateralAmount_) internal view returns (uint256) {
        uint256 _totalLiquidity = stargateLp.totalLiquidity();
        // amount SD = _collateralAmount / stargateLp.convertRate()
        // amount LP = SD * totalSupply / totalLiquidity
        return
            (_totalLiquidity > 0)
                ? ((collateralAmount_ / stargateLp.convertRate()) * stargateLp.totalSupply()) / _totalLiquidity
                : 0;
    }

    function _deposit(uint256 collateralAmount_) internal {
        if (collateralAmount_ > 0) {
            _beforeDeposit(collateralAmount_);
            stargateRouter.addLiquidity(stargatePoolId, collateralAmount_, address(this));
            stargateLpStaking.deposit(stargateLpStakingPoolId, stargateLp.balanceOf(address(this)));
        }
    }

    /// @dev Gets collateral balance deposited into STG Pool
    function _getCollateralInStargate() internal view returns (uint256 _collateralStaked) {
        return stargateLp.amountLPtoLD(lpAmountStaked() + stargateLp.balanceOf(address(this)));
    }

    function _getLpForCollateral(uint256 collateralAmount_) internal returns (uint256) {
        uint256 _lpRequired = _convertToLpShares(collateralAmount_);
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

    function _rebalance() internal override returns (uint256 _profit, uint256 _loss, uint256 _payback) {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));

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
        _deposit(collateralToken.balanceOf(address(this)));
    }

    /// @dev Withdraw collateral here.
    /// @dev This method may withdraw less than requested amount. Caller may need to check balance before and after
    function _withdrawHere(uint256 amount_) internal override {
        uint256 _lpToRedeem = _getLpForCollateral(amount_);
        if (_lpToRedeem > 0) {
            stargateRouter.instantRedeemLocal(uint16(stargatePoolId), _lpToRedeem, address(this));
        }
    }

    /************************************************************************************************
     *                                       keeper function                                        *
     ***********************************************************************************************/

    /**
     * @notice OnlyKeeper: This function will withdraw required collateral from given
     *   destination chain to the chain where this contract is deployed.
     * @param dstChainId_ Destination chainId.
     * @dev Stargate has different chainId than EVM chainId.
     */
    function withdrawForRebalance(uint16 dstChainId_) external payable onlyKeeper {
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
                dstChainId_,
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
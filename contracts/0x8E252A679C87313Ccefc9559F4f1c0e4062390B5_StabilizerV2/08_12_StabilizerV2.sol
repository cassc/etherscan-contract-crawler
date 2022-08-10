// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IApeToken.sol";
import "./interfaces/IBaseRewardPool.sol";
import "./interfaces/IBooster.sol";
import "./interfaces/ICurveStableSwap.sol";

contract StabilizerV2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    ICurveStableSwap public constant apeUSDCurvePool =
        ICurveStableSwap(0x04b727C7e246CA70d496ecF52E6b6280f3c8077D);
    IBooster public constant booster =
        IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    uint256 public constant poolId = 103; // Convex pool 103

    IApeToken public immutable apeApeUSD;
    IERC20 public immutable apeUSD;

    event Seize(address token, uint256 amount);

    constructor(address _apeApeUSD) {
        apeApeUSD = IApeToken(_apeApeUSD);
        apeUSD = IERC20(apeApeUSD.underlying());
    }

    function getAmountCurveLP(uint256 amount) external view returns (uint256) {
        return apeUSDCurvePool.calc_token_amount([amount, 0], true); // [apeUSD, FRAX/USDC LP]
    }

    function getAmountApeUSD(uint256 amount) external view returns (uint256) {
        return apeUSDCurvePool.calc_withdraw_one_coin(amount, 0); // 0: apeUSD
    }

    function depositAndStake(uint256 amount, uint256 minLP)
        external
        onlyOwner
        nonReentrant
    {
        if (amount > 0) {
            // Borrow apeUSD.
            require(
                apeApeUSD.borrow(payable(address(this)), amount) == 0,
                "borrow failed"
            );
        }

        // Approve apeUSD and add liquidity to Curve pool.
        uint256 apeUSDBalance = apeUSD.balanceOf(address(this));
        if (apeUSDBalance > 0) {
            apeUSD.safeIncreaseAllowance(
                address(apeUSDCurvePool),
                apeUSDBalance
            );
            apeUSDCurvePool.add_liquidity(
                [apeUSDBalance, 0], // [apeUSD, FRAX/USDC LP]
                minLP,
                address(this)
            );
        }

        // Approve Curve LP, deposit LP to Convex booster, and stake Convex deposit token to base reward pool.
        uint256 lpBalance = apeUSDCurvePool.balanceOf(address(this));
        if (lpBalance > 0) {
            apeUSDCurvePool.approve(address(booster), lpBalance);
            booster.depositAll(poolId, true);
        }
    }

    function unstakeAndWithdraw(uint256 amount, uint256 minApeUSD)
        external
        onlyOwner
        nonReentrant
    {
        // Unstake Convex deposit token from base reward pool and unwrap it back to Curve LP.
        (, , , address baseRewardPool, , ) = booster.poolInfo(poolId);
        if (amount > 0) {
            IBaseRewardPool(baseRewardPool).withdrawAndUnwrap(amount, false); // not claim rewards
        }

        // Remove liquidity from Curve pool.
        uint256 lpBalance = apeUSDCurvePool.balanceOf(address(this));
        if (lpBalance > 0) {
            apeUSDCurvePool.remove_liquidity_one_coin(
                lpBalance,
                0, // 0: apeUSD
                minApeUSD,
                address(this)
            );
        }

        // Approve and repay apeUSD.
        uint256 repayAmount = apeUSD.balanceOf(address(this));
        uint256 borrowBalance = apeApeUSD.borrowBalanceCurrent(address(this));
        if (repayAmount > borrowBalance) {
            repayAmount = borrowBalance;
        }
        apeUSD.safeIncreaseAllowance(address(apeApeUSD), repayAmount);
        require(
            apeApeUSD.repayBorrow(payable(address(this)), repayAmount) == 0,
            "repay failed"
        );
    }

    function claimRewards() external onlyOwner {
        (, , , address baseRewardPool, , ) = booster.poolInfo(poolId);
        IBaseRewardPool(baseRewardPool).getReward();
    }

    function seize(address token, uint256 amount) external onlyOwner {
        if (token == address(apeUSD)) {
            uint256 borrowBalance = apeApeUSD.borrowBalanceCurrent(
                address(this)
            );
            require(borrowBalance == 0, "borrow balance not zero");
        }
        IERC20(token).safeTransfer(owner(), amount);
        emit Seize(token, amount);
    }
}
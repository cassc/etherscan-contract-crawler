// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IApeToken.sol";
import "./interfaces/IConvexStakingWrapperFrax.sol";
import "./interfaces/ICurveStableSwap.sol";
import "./interfaces/IFraxStaking.sol";

contract StabilizerV3 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IConvexStakingWrapperFrax public constant apeUSDConvexStakingWrapperFrax =
        IConvexStakingWrapperFrax(0x6a20FC1654A2167d00614332A5aFbB7EBcD9d414);
    IFraxStaking public constant apeUSDFraxStaking =
        IFraxStaking(0xa810D1268cEF398EC26095c27094596374262826);
    ICurveStableSwap public constant apeUSDCurvePool =
        ICurveStableSwap(0x04b727C7e246CA70d496ecF52E6b6280f3c8077D);

    IApeToken public immutable apeApeUSD;
    IERC20 public immutable apeUSD;

    struct RewardData {
        address token;
        uint256 amount;
    }

    event Seize(address token, uint256 amount);

    constructor(address _apeApeUSD) {
        apeApeUSD = IApeToken(_apeApeUSD);
        apeUSD = IERC20(apeApeUSD.underlying());
    }

    // --- VIEW ---

    function getAmountCurveLP(uint256 amount) external view returns (uint256) {
        return apeUSDCurvePool.calc_token_amount([amount, 0], true); // [apeUSD, FRAX/USDC LP]
    }

    function getAmountApeUSD(uint256 amount) external view returns (uint256) {
        return apeUSDCurvePool.calc_withdraw_one_coin(amount, 0); // 0: apeUSD
    }

    function getApeUSDBorrowBalance() external view returns (uint256) {
        return apeApeUSD.borrowBalanceStored(address(this));
    }

    function getAllLocks()
        external
        view
        returns (IFraxStaking.LockedStake[] memory)
    {
        return apeUSDFraxStaking.lockedStakesOf(address(this));
    }

    function getTotalLPLocked() external view returns (uint256) {
        return apeUSDFraxStaking.lockedLiquidityOf(address(this));
    }

    function getTotalLPLockedValue() external view returns (uint256) {
        uint256 amount = apeUSDFraxStaking.lockedLiquidityOf(address(this));
        uint256 price = apeUSDCurvePool.get_virtual_price();
        return (amount * price) / 1e18;
    }

    function getClaimableRewards() external view returns (RewardData[] memory) {
        IConvexStakingWrapperFrax.EarnedData[]
            memory convexRewards = apeUSDConvexStakingWrapperFrax.earned(
                address(this)
            );
        uint256[] memory fraxRewards = apeUSDFraxStaking.earned(address(this));
        address[] memory fraxRewardTokens = apeUSDFraxStaking
            .getAllRewardTokens();

        RewardData[] memory claimableRewards = new RewardData[](
            convexRewards.length + fraxRewards.length
        );
        for (uint256 i = 0; i < convexRewards.length; i++) {
            claimableRewards[i] = RewardData({
                token: convexRewards[i].token,
                amount: convexRewards[i].amount
            });
        }
        for (uint256 i = 0; i < fraxRewards.length; i++) {
            claimableRewards[i + convexRewards.length] = RewardData({
                token: fraxRewardTokens[i],
                amount: fraxRewards[i]
            });
        }
        return claimableRewards;
    }

    // --- DEPOSIT AND STAKE ---

    function depositAndStakeLock(
        uint256 amount,
        uint256 minCurveLP,
        uint256 period
    ) external onlyOwner nonReentrant {
        depositApeUSD(amount, minCurveLP);

        // Approve Convex staking wrapped LP, and stake LP to Frax staking.
        uint256 stakedBalance = apeUSDConvexStakingWrapperFrax.balanceOf(
            address(this)
        );
        if (stakedBalance > 0) {
            apeUSDConvexStakingWrapperFrax.approve(
                address(apeUSDFraxStaking),
                stakedBalance
            );
            apeUSDFraxStaking.stakeLocked(stakedBalance, period);
        }
    }

    function depositAndIncreaseLockAmount(
        uint256 amount,
        uint256 minCurveLP,
        bytes32 kekID
    ) external onlyOwner nonReentrant {
        depositApeUSD(amount, minCurveLP);

        // Approve Convex staking wrapped LP, and stake LP to Frax staking.
        uint256 stakedBalance = apeUSDConvexStakingWrapperFrax.balanceOf(
            address(this)
        );
        if (stakedBalance > 0) {
            apeUSDConvexStakingWrapperFrax.approve(
                address(apeUSDFraxStaking),
                stakedBalance
            );
            apeUSDFraxStaking.lockAdditional(kekID, stakedBalance);
        }
    }

    function extendLock(bytes32 kekID, uint256 newEndingTime)
        external
        onlyOwner
        nonReentrant
    {
        apeUSDFraxStaking.lockLonger(kekID, newEndingTime);
    }

    function depositApeUSD(uint256 amount, uint256 minCurveLP) internal {
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
                minCurveLP,
                address(this)
            );
        }

        // Approve Curve LP, and deposit LP to Convex staking wrapper (for Frax).
        uint256 lpBalance = apeUSDCurvePool.balanceOf(address(this));
        if (lpBalance > 0) {
            apeUSDCurvePool.approve(
                address(apeUSDConvexStakingWrapperFrax),
                lpBalance
            );
            apeUSDConvexStakingWrapperFrax.deposit(lpBalance, address(this));
        }
    }

    // --- WITHDRAW ---

    function unstakeAndWithdraw(bytes32 kekID, uint256 minApeUSD)
        external
        onlyOwner
        nonReentrant
    {
        apeUSDFraxStaking.withdrawLocked(kekID, address(this));

        // Withdraw from Convex staking wrapper (for Frax) and unwrap it back to Curve LP.
        uint256 stakedBalance = apeUSDConvexStakingWrapperFrax.balanceOf(
            address(this)
        );
        if (stakedBalance > 0) {
            apeUSDConvexStakingWrapperFrax.withdrawAndUnwrap(stakedBalance);
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

    // --- CLAIM REWARDS ---

    function claimRewards() external onlyOwner {
        // Claim CRV and CVX.
        apeUSDConvexStakingWrapperFrax.getReward(address(this));

        // Claim FXS.
        apeUSDFraxStaking.getReward(address(this));
    }

    // --- SEIZE ---

    function seize(address token) external onlyOwner {
        if (token == address(apeUSD)) {
            uint256 borrowBalance = apeApeUSD.borrowBalanceCurrent(
                address(this)
            );
            require(borrowBalance == 0, "borrow balance not zero");
        }
        uint256 bal = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(owner(), bal);
        emit Seize(token, bal);
    }
}
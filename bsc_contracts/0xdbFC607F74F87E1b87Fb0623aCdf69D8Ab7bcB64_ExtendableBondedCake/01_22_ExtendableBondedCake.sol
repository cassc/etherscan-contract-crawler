// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@private/shared/3rd/pancake/ICakePool.sol";

import "../../ExtendableBond.sol";

contract ExtendableBondedCake is ExtendableBond {
    /**
     * CakePool contract
     */
    ICakePool public cakePool;

    function setCakePool(ICakePool cakePool_) external onlyAdmin {
        cakePool = cakePool_;
    }

    /**
     * @dev calculate cake amount from pancake.
     */
    function remoteUnderlyingAmount() public view override returns (uint256) {
        ICakePool.UserInfo memory userInfo = cakePool.userInfo(address(this));
        uint256 pricePerFullShare = cakePool.getPricePerFullShare();
        if (userInfo.shares <= 0) {
            return 0;
        }
        uint256 withdrawFee = 0;
        if (
            ((userInfo.locked ? userInfo.lockEndTime : block.timestamp) <
                userInfo.lastDepositedTime + cakePool.withdrawFeePeriod())
        ) {
            withdrawFee = cakePool.calculateWithdrawFee(address(this), userInfo.shares);
        }
        return (userInfo.shares * pricePerFullShare) / 1e18 - userInfo.userBoostedShare - withdrawFee;
    }

    /**
     * @dev calculate cake amount from pancake.
     */
    function pancakeUserInfo() public view returns (ICakePool.UserInfo memory) {
        return cakePool.userInfo(address(this));
    }

    /**
     * @dev withdraw from pancakeswap
     */
    function _withdrawFromRemote(uint256 amount_) internal override {
        cakePool.withdrawByAmount(amount_);
    }

    /**
     * @dev deposit to pancakeswap
     */
    function _depositRemote(uint256 amount_) internal override {
        uint256 balance = underlyingToken.balanceOf(address(this));
        require(balance > 0 && balance >= amount_, "nothing to deposit");
        underlyingToken.approve(address(cakePool), amount_);
        cakePool.deposit(amount_, secondsToPancakeLockExtend(true));

        _checkLockEndTime();
    }

    function _checkLockEndTime() internal view {
        require(pancakeUserInfo().lockEndTime <= checkPoints.maturity, "The lock-up time exceeds the ebCAKE maturity");
    }

    /**
     * @dev calculate lock extend seconds
     * @param deposit_ whether use as deposit param.
     */
    function secondsToPancakeLockExtend(bool deposit_) public view returns (uint256 secondsToExtend) {
        uint256 currentTime = block.timestamp;
        ICakePool.UserInfo memory cakeInfo = cakePool.userInfo(address(this));

        uint256 cakeMaxLockDuration = cakePool.MAX_LOCK_DURATION();
        // lock expired or cake lockEndTime earlier than maturity, extend lock time required.
        if (
            cakeInfo.lockEndTime < checkPoints.maturity &&
            checkPoints.maturity > block.timestamp &&
            (deposit_ || cakeInfo.lockEndTime - cakeInfo.lockStartTime < cakeMaxLockDuration)
        ) {
            if (cakeInfo.lockEndTime >= block.timestamp) {
                // lockStartTime will be updated to block.timestamp in CakePool every time.
                uint256 totalLockDuration = checkPoints.maturity - block.timestamp;
                return
                    MathUpgradeable.min(totalLockDuration, cakeMaxLockDuration) +
                    block.timestamp -
                    cakeInfo.lockEndTime;
            }

            return MathUpgradeable.min(checkPoints.maturity - block.timestamp, cakeMaxLockDuration);
        }

        return secondsToExtend;
    }

    /**
     * @dev Withdraw cake from cake pool.
     */
    function withdrawAllCakesFromPancake(bool makeRedeemable_) public onlyAdminOrKeeper {
        checkPoints.convertable = false;
        cakePool.withdrawAll();
        if (makeRedeemable_) {
            checkPoints.redeemable = true;
        }
    }

    /**
     * @dev extend pancake lock duration if needs
     * @param force_ force extend even it's unnecessary
     */
    function extendPancakeLockDuration(bool force_) public onlyAdminOrKeeper {
        uint256 secondsToExtend = secondsToPancakeLockExtend(force_);
        if (secondsToExtend > 0) {
            cakePool.deposit(0, secondsToExtend);
            _checkLockEndTime();
        }
    }
}
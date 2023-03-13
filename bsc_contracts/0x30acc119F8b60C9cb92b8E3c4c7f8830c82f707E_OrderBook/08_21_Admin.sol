// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "./Storage.sol";

contract Admin is Storage {
    event AddBroker(address indexed newBroker);
    event RemoveBroker(address indexed broker);
    event AddRebalancer(address indexed newRebalancer);
    event RemoveRebalancer(address indexed rebalancer);
    event SetLiquidityLockPeriod(uint32 oldLockPeriod, uint32 newLockPeriod);
    event SetOrderTimeout(uint32 marketOrderTimeout, uint32 maxLimitOrderTimeout);
    event PausePositionOrder(bool isPaused);
    event PauseLiquidityOrder(bool isPaused);
    event SetMaintainer(address indexed newMaintainer);
    event SetReferralManager(address newReferralManager);

    modifier onlyBroker() {
        require(brokers[_msgSender()], "BKR"); // only BroKeR
        _;
    }

    modifier onlyRebalancer() {
        require(rebalancers[_msgSender()], "BAL"); // only reBALancer
        _;
    }

    modifier onlyMaintainer() {
        require(_msgSender() == maintainer || _msgSender() == owner(), "S!M"); // Sender is Not MaiNTainer
        _;
    }

    function addBroker(address newBroker) external onlyOwner {
        require(!brokers[newBroker], "CHG"); // not CHanGed
        brokers[newBroker] = true;
        emit AddBroker(newBroker);
    }

    function removeBroker(address broker) external onlyOwner {
        _removeBroker(broker);
    }

    function renounceBroker() external {
        _removeBroker(msg.sender);
    }

    function addRebalancer(address newRebalancer) external onlyOwner {
        require(!rebalancers[newRebalancer], "CHG"); // not CHanGed
        rebalancers[newRebalancer] = true;
        emit AddRebalancer(newRebalancer);
    }

    function removeRebalancer(address rebalancer) external onlyOwner {
        _removeRebalancer(rebalancer);
    }

    function renounceRebalancer() external {
        _removeRebalancer(msg.sender);
    }

    function setLiquidityLockPeriod(uint32 newLiquidityLockPeriod) external onlyOwner {
        require(newLiquidityLockPeriod <= 86400 * 30, "LCK"); // LoCK time is too large
        require(liquidityLockPeriod != newLiquidityLockPeriod, "CHG"); // setting is not CHanGed
        emit SetLiquidityLockPeriod(liquidityLockPeriod, newLiquidityLockPeriod);
        liquidityLockPeriod = newLiquidityLockPeriod;
    }

    function setOrderTimeout(uint32 marketOrderTimeout_, uint32 maxLimitOrderTimeout_) external onlyOwner {
        require(marketOrderTimeout_ != 0, "T=0"); // Timeout Is Zero
        require(marketOrderTimeout_ / 10 <= type(uint24).max, "T>M"); // Timeout is Larger than Max
        require(maxLimitOrderTimeout_ != 0, "T=0"); // Timeout Is Zero
        require(maxLimitOrderTimeout_ / 10 <= type(uint24).max, "T>M"); // Timeout is Larger than Max
        require(marketOrderTimeout != marketOrderTimeout_ || maxLimitOrderTimeout != maxLimitOrderTimeout_, "CHG"); // setting is not CHanGed
        marketOrderTimeout = marketOrderTimeout_;
        maxLimitOrderTimeout = maxLimitOrderTimeout_;
        emit SetOrderTimeout(marketOrderTimeout_, maxLimitOrderTimeout_);
    }

    function pause(bool isPositionOrderPaused_, bool isLiquidityOrderPaused_) external onlyMaintainer {
        if (isPositionOrderPaused != isPositionOrderPaused_) {
            isPositionOrderPaused = isPositionOrderPaused_;
            emit PausePositionOrder(isPositionOrderPaused_);
        }
        if (isLiquidityOrderPaused != isLiquidityOrderPaused_) {
            isLiquidityOrderPaused = isLiquidityOrderPaused_;
            emit PauseLiquidityOrder(isLiquidityOrderPaused_);
        }
    }

    function setMaintainer(address newMaintainer) external onlyOwner {
        require(maintainer != newMaintainer, "CHG"); // not CHanGed
        maintainer = newMaintainer;
        emit SetMaintainer(newMaintainer);
    }

    function setReferralManager(address newReferralManager) external onlyOwner {
        require(newReferralManager != address(0), "ZAD");
        referralManager = newReferralManager;
        emit SetReferralManager(newReferralManager);
    }

    function _removeBroker(address broker) internal {
        require(brokers[broker], "CHG"); // not CHanGed
        brokers[broker] = false;
        emit RemoveBroker(broker);
    }

    function _removeRebalancer(address rebalancer) internal {
        require(rebalancers[rebalancer], "CHG"); // not CHanGed
        rebalancers[rebalancer] = false;
        emit RemoveRebalancer(rebalancer);
    }
}
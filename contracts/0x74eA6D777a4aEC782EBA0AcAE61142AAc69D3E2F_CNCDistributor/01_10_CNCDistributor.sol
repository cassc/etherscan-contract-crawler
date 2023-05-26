// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "Ownable.sol";
import "IERC20.sol";
import "SafeERC20.sol";

import "ScaledMath.sol";

import "ICNCDistributor.sol";
import "ICurveGauge.sol";

contract CNCDistributor is ICNCDistributor, Ownable {
    using SafeERC20 for IERC20;
    using ScaledMath for uint256;

    IERC20 public constant CNC = IERC20(0x9aE380F0272E2162340a5bB646c354271c0F5cFC);
    address public constant TREASURY = 0xB27DC5f8286f063F11491c8f349053cB37718bea;
    ICurveGauge public constant CNC_ETH_GAUGE =
        ICurveGauge(0x5A8fa46ebb404494D718786e55c4E043337B10bF);

    uint256 internal constant INITIAL_INFLATION_RATE = 240_000 * 1e18;
    uint256 internal constant INFLATION_RATE_DECAY = 0.3999999 * 1e18;
    uint256 internal constant INFLATION_RATE_PERIOD = 358 days; // @dev: avoid inflation running over by 1 week

    bool public override isShutdown;
    uint256 public override gaugeInflationShare = 0.45e18;
    uint256 public override currentInflationRate;
    uint256 public override lastInflationRateDecay;

    constructor() {
        currentInflationRate = INITIAL_INFLATION_RATE / INFLATION_RATE_PERIOD;
        lastInflationRateDecay = block.timestamp;
    }

    function topUpGauge() public override {
        require(!isShutdown, "contract is shutdown");
        uint256 gaugeInflationRate = gaugeInflationShare.mulDown(currentInflationRate);

        (, , uint256 periodFinish, , , ) = CNC_ETH_GAUGE.reward_data(address(CNC));
        uint256 amount;
        if (block.timestamp < periodFinish) {
            uint256 remainder = periodFinish - block.timestamp;
            amount = (7 days - remainder) * gaugeInflationRate;
        } else {
            uint256 diff = block.timestamp - periodFinish;
            amount = (diff + 7 days) * gaugeInflationRate;
        }

        require(CNC.balanceOf(address(this)) >= amount, "Insufficient CNC balance");
        CNC.safeApprove(address(CNC_ETH_GAUGE), amount);
        CNC_ETH_GAUGE.deposit_reward_token(address(CNC), amount);

        emit GaugeTopUp(amount);
    }

    function donate(uint256 amount) external override {
        require(!isShutdown, "contract is shutdown");
        CNC.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdrawOtherToken(address token) external override onlyOwner {
        require(token != address(CNC), "invalid token to send to treasury");
        IERC20(token).safeTransfer(TREASURY, IERC20(token).balanceOf(address(this)));
    }

    function updateInflationShare(uint256 _gaugeInflationShare) external onlyOwner {
        require(_gaugeInflationShare <= 1e18, "inflation share can not exceed 100%");
        require(
            _gaugeInflationShare != gaugeInflationShare,
            "new inflation shares must be different"
        );
        gaugeInflationShare = _gaugeInflationShare;

        emit InflationSharesUpdated(_gaugeInflationShare);
    }

    function _executeInflationRateUpdate() internal {
        if (block.timestamp >= lastInflationRateDecay + INFLATION_RATE_PERIOD) {
            currentInflationRate = currentInflationRate.mulDown(INFLATION_RATE_DECAY);
            lastInflationRateDecay = block.timestamp;
        }
    }

    function executeInflationRateUpdate() external override onlyOwner {
        _executeInflationRateUpdate();
    }

    function setGaugeRewardDistributor(address newDistributor) external onlyOwner {
        require(isShutdown, "Distributor is not shutdown");
        require(newDistributor != address(0), "Can not be zero address");
        CNC_ETH_GAUGE.set_reward_distributor(address(CNC), newDistributor);
    }

    function shutdown() external override onlyOwner {
        require(!isShutdown, "is already shutdown");
        isShutdown = true;
        CNC.safeTransfer(TREASURY, CNC.balanceOf(address(this)));
    }
}
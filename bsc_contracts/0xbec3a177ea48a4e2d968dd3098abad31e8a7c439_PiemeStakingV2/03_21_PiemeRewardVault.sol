// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {IPiemeVault, PiemeVault} from "./PiemeVault.sol";

interface IPiemeRewardVault is IPiemeVault {
    function estimate(
        uint256 staked,
        uint256 when
    ) external view returns (uint256 _dailyReward, uint256 _cumulativeReward);

    function update(uint256 staked) external;

    function cumulativeReward() external view returns (uint256);

    event Update(uint256, uint256, uint256, uint256);
}

contract PiemeRewardVault is PiemeVault, IPiemeRewardVault {
    uint256 public refreshed; // the latest timestamp of contract data update
    uint256 public override cumulativeReward; // total rewards from deploy per token
    uint256 public dailyReward; // the latest daily reward per token

    uint256 private _balance; // temp reward balance
    uint256 private _withdrawn; // temp withdraw balance

    uint256 public constant DAYS1 = 1 seconds;
    uint256 public constant MONTHS12 = 360 days; // 500,000
    uint256 public constant DAILYRWD = 8037551440329198; // 1388.88889 daily reward

    constructor(address token_, address owner_) PiemeVault(token_, owner_) {
        // refreshed = block.timestamp; for tests
        refreshed = 1669015957; // Sunday, 20 November 2022 22:35:56
    }

    /**
     * @dev Estimate reward by timestamp.
     *
     * @param staked Current stake amount
     * @param when Future timestamp
     * Emits a {Update} event.
     */
    function estimate(
        uint256 staked,
        uint256 when
    ) public view returns (uint256 _dailyReward, uint256 _cumulativeReward) {
        uint256 slices = (when - refreshed) / DAYS1;
        _dailyReward =
            (1e18 *
                ((token.balanceOf(address(this)) + _withdrawn - _balance) /
                    (MONTHS12 / DAYS1 - slices) +
                    DAILYRWD)) /
            staked;
        _cumulativeReward = cumulativeReward + slices * _dailyReward;
    }

    /**
     * @dev Update data.
     *
     * @param staked Current stake amount
     * Emits a {Update} event.
     */
    function update(uint256 staked) external override onlyOwner {
        (dailyReward, cumulativeReward) = estimate(staked, block.timestamp);
        _balance = token.balanceOf(address(this));
        _withdrawn = 0;
        refreshed = block.timestamp;

        emit Update(staked, refreshed, cumulativeReward, dailyReward);
    }

    /**
     * @dev Withdraws funds.
     *
     * @param to Transfer funds to address
     * @param amount Transfer amount
     * Emits a {Withdrawn} event.
     */
    function withdraw(
        address to,
        uint256 amount
    ) public override(IPiemeVault, PiemeVault) {
        _withdrawn += amount;
        super.withdraw(to, amount);
    }
}
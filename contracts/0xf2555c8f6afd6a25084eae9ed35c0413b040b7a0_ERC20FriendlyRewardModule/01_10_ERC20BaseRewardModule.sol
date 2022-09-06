/*
ERC20BaseRewardModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IRewardModule.sol";

/**
 * @title ERC20 base reward module
 *
 * @notice this abstract class implements common ERC20 funding and unlocking
 * logic, which is inherited by other reward modules.
 */
abstract contract ERC20BaseRewardModule is IRewardModule {
    using SafeERC20 for IERC20;

    // single funding/reward schedule
    struct Funding {
        uint256 amount;
        uint256 shares;
        uint256 locked;
        uint256 updated;
        uint256 start;
        uint256 duration;
    }

    // constants
    uint256 public constant INITIAL_SHARES_PER_TOKEN = 10**6;
    uint256 public constant MAX_ACTIVE_FUNDINGS = 16;

    // funding/reward state fields
    mapping(address => Funding[]) private _fundings;
    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _locked;

    /**
     * @notice getter for total token shares
     */
    function totalShares(address token) public view returns (uint256) {
        return _shares[token];
    }

    /**
     * @notice getter for total locked token shares
     */
    function lockedShares(address token) public view returns (uint256) {
        return _locked[token];
    }

    /**
     * @notice getter for funding schedule struct
     */
    function fundings(address token, uint256 index)
        public
        view
        returns (
            uint256 amount,
            uint256 shares,
            uint256 locked,
            uint256 updated,
            uint256 start,
            uint256 duration
        )
    {
        Funding storage f = _fundings[token][index];
        return (f.amount, f.shares, f.locked, f.updated, f.start, f.duration);
    }

    /**
     * @param token contract address of reward token
     * @return number of active funding schedules
     */
    function fundingCount(address token) public view returns (uint256) {
        return _fundings[token].length;
    }

    /**
     * @notice compute number of unlockable shares for a specific funding schedule
     * @param token contract address of reward token
     * @param idx index of the funding
     * @return the number of unlockable shares
     */
    function unlockable(address token, uint256 idx)
        public
        view
        returns (uint256)
    {
        Funding storage funding = _fundings[token][idx];

        // funding schedule is in future
        if (block.timestamp < funding.start) {
            return 0;
        }
        // empty
        if (funding.locked == 0) {
            return 0;
        }
        // handle zero-duration period or leftover dust from integer division
        if (block.timestamp >= funding.start + funding.duration) {
            return funding.locked;
        }

        return
            ((block.timestamp - funding.updated) * funding.shares) /
            funding.duration;
    }

    /**
     * @notice fund pool by locking up reward tokens for future distribution
     * @param token contract address of reward token
     * @param amount number of reward tokens to lock up as funding
     * @param duration period (seconds) over which funding will be unlocked
     * @param start time (seconds) at which funding begins to unlock
     */
    function _fund(
        address token,
        uint256 amount,
        uint256 duration,
        uint256 start
    ) internal {
        requireController();
        // validate
        require(amount > 0, "rm1");
        require(start >= block.timestamp, "rm2");
        require(_fundings[token].length < MAX_ACTIVE_FUNDINGS, "rm3");

        IERC20 rewardToken = IERC20(token);

        // do transfer of funding
        uint256 total = rewardToken.balanceOf(address(this));
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 actual = rewardToken.balanceOf(address(this)) - total;

        // mint shares at current rate
        uint256 minted =
            (total > 0)
                ? (_shares[token] * actual) / total
                : actual * INITIAL_SHARES_PER_TOKEN;

        _locked[token] += minted;
        _shares[token] += minted;

        // create new funding
        _fundings[token].push(
            Funding({
                amount: amount,
                shares: minted,
                locked: minted,
                updated: start,
                start: start,
                duration: duration
            })
        );

        emit RewardsFunded(token, amount, minted, start);
    }

    /**
     * @dev internal function to clean up stale funding schedules
     * @param token contract address of reward token to clean up
     */
    function _clean(address token) internal {
        // check for stale funding schedules to expire
        uint256 removed = 0;
        uint256 originalSize = _fundings[token].length;
        for (uint256 i = 0; i < originalSize; i++) {
            Funding storage funding = _fundings[token][i - removed];
            uint256 idx = i - removed;

            if (
                unlockable(token, idx) == 0 &&
                block.timestamp >= funding.start + funding.duration
            ) {
                emit RewardsExpired(
                    token,
                    funding.amount,
                    funding.shares,
                    funding.start
                );

                // remove at idx by copying last element here, then popping off last
                // (we don't care about order)
                _fundings[token][idx] = _fundings[token][
                    _fundings[token].length - 1
                ];
                _fundings[token].pop();
                removed++;
            }
        }
    }

    /**
     * @dev unlocks reward tokens based on funding schedules
     * @param token contract addres of reward token
     * @return shares number of shares unlocked
     */
    function _unlockTokens(address token) internal returns (uint256 shares) {
        // get unlockable shares for each funding schedule
        for (uint256 i = 0; i < _fundings[token].length; i++) {
            uint256 s = unlockable(token, i);
            Funding storage funding = _fundings[token][i];
            if (s > 0) {
                funding.locked -= s;
                funding.updated = block.timestamp;
                shares += s;
            }
        }

        // do unlocking
        if (shares > 0) {
            _locked[token] -= shares;
            emit RewardsUnlocked(token, shares);
        }
    }

    /**
     * @dev distribute reward tokens to user
     * @param user address of user receiving rweard
     * @param token contract address of reward token
     * @param shares number of shares to be distributed
     * @return amount number of reward tokens distributed
     */
    function _distribute(
        address user,
        address token,
        uint256 shares
    ) internal returns (uint256 amount) {
        // compute reward amount in tokens
        IERC20 rewardToken = IERC20(token);
        amount =
            (rewardToken.balanceOf(address(this)) * shares) /
            _shares[token];

        // update overall reward shares
        _shares[token] -= shares;

        // do reward
        rewardToken.safeTransfer(user, amount);
        emit RewardsDistributed(user, token, amount, shares);
    }
}
/*
ERC20FriendlyRewardModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IRewardModule.sol";
import "./IERC20FriendlyRewardModuleV2.sol";
import "../GysrUtils.sol";
import "./TokenUtilsInfo.sol";

/**
 * @title ERC20 friendly reward module info library
 *
 * @notice this library provides read-only convenience functions to query
 * additional information about the ERC20FriendlyRewardModule contract.
 */
library ERC20FriendlyRewardModuleInfo {
    using GysrUtils for uint256;
    using TokenUtilsInfo for IERC20;

    /**
     * @notice get all token metadata
     * @param module address of reward module
     * @return addresses_
     * @return names_
     * @return symbols_
     * @return decimals_
     */
    function tokens(
        address module
    )
        external
        view
        returns (
            address[] memory addresses_,
            string[] memory names_,
            string[] memory symbols_,
            uint8[] memory decimals_
        )
    {
        addresses_ = new address[](1);
        names_ = new string[](1);
        symbols_ = new string[](1);
        decimals_ = new uint8[](1);
        (addresses_[0], names_[0], symbols_[0], decimals_[0]) = token(module);
    }

    /**
     * @notice convenience function to get token metadata in a single call
     * @param module address of reward module
     * @return address
     * @return name
     * @return symbol
     * @return decimals
     */
    function token(
        address module
    ) public view returns (address, string memory, string memory, uint8) {
        IRewardModule m = IRewardModule(module);
        IERC20Metadata tkn = IERC20Metadata(m.tokens()[0]);
        return (address(tkn), tkn.name(), tkn.symbol(), tkn.decimals());
    }

    /**
     * @notice generic function to get pending reward balances
     * @param module address of reward module
     * @param account bytes32 account of interest for preview
     * @param shares number of shares that would be used
     * @return rewards_ estimated reward balances
     */
    function rewards(
        address module,
        bytes32 account,
        uint256 shares,
        bytes calldata
    ) public view returns (uint256[] memory rewards_) {
        rewards_ = new uint256[](1);
        (rewards_[0], , ) = preview(module, account, shares);
    }

    /**
     * @notice preview estimated rewards
     * @param module address of reward module
     * @param account bytes32 account of interest for preview
     * @param shares number of shares that would be unstaked
     * @return estimated reward
     * @return estimated time multiplier weighted by rewards
     * @return estimated gysr multiplier weighted by rewards
     */
    function preview(
        address module,
        bytes32 account,
        uint256 shares
    ) public view returns (uint256, uint256, uint256) {
        require(shares > 0, "frmi1");
        IERC20FriendlyRewardModuleV2 m = IERC20FriendlyRewardModuleV2(module);
        address user = address(uint160(uint256(account)));

        uint256 reward;
        uint256 rawSum;
        uint256 bonusSum;

        uint256 i = m.stakeCount(user);

        // redeem first-in-last-out
        while (shares > 0) {
            require(i > 0, "frmi2");
            i -= 1;

            (uint256 s, , , , ) = m.stakes(user, i);

            // only redeem partial stake if more shares left than needed to burn
            s = s <= shares ? s : shares;

            uint256 r;
            {
                r = rewardsPerStakedShare(module);
            }

            {
                (, , , uint256 tally, ) = m.stakes(user, i);
                r = ((r - tally) * s) / 1e18;
                rawSum += r;
            }

            {
                (, , uint256 bonus, , ) = m.stakes(user, i);
                r = (r * bonus) / 1e18;
                bonusSum += r;
            }

            {
                (, , , , uint256 time) = m.stakes(user, i);
                r = (r * m.timeVestingCoefficient(time)) / 1e18;
            }
            reward += r;
            shares -= s;
        }

        address tkn = m.tokens()[0];
        return (
            IERC20(tkn).getAmount(module, m.totalShares(tkn), reward),
            reward > 0 ? (reward * 1e18) / bonusSum : 0,
            reward > 0 ? (bonusSum * 1e18) / rawSum : 0
        );
    }

    /**
     * @notice compute reward shares to be unlocked on the next update
     * @param module address of reward module
     * @return estimated unlockable rewards
     */
    function unlockable(address module) public view returns (uint256) {
        IERC20FriendlyRewardModuleV2 m = IERC20FriendlyRewardModuleV2(module);
        address tkn = m.tokens()[0];
        if (m.lockedShares(tkn) == 0) {
            return 0;
        }
        uint256 sharesToUnlock = 0;
        for (uint256 i = 0; i < m.fundingCount(tkn); i++) {
            sharesToUnlock = sharesToUnlock + m.unlockable(tkn, i);
        }
        return sharesToUnlock;
    }

    /**
     * @notice compute effective unlocked rewards
     * @param module address of reward module
     * @return estimated current unlocked rewards
     */
    function unlocked(address module) public view returns (uint256) {
        IERC20FriendlyRewardModuleV2 m = IERC20FriendlyRewardModuleV2(module);
        IERC20 tkn = IERC20(m.tokens()[0]);
        uint256 totalShares = m.totalShares(address(tkn));
        if (totalShares == 0) {
            return 0;
        }
        uint256 shares = unlockable(module);
        uint256 amount = tkn.getAmount(module, totalShares, shares);
        return m.totalUnlocked() + amount;
    }

    /**
     * @notice compute effective rewards per staked share
     * @param module module contract address
     * @return estimated rewards per staked share
     */
    function rewardsPerStakedShare(
        address module
    ) public view returns (uint256) {
        IERC20FriendlyRewardModuleV2 m = IERC20FriendlyRewardModuleV2(module);
        if (m.totalStakingShares() == 0) {
            return m.rewardsPerStakedShare();
        }
        uint256 rewardsToUnlock = unlockable(module) + m.rewardDust();
        return
            m.rewardsPerStakedShare() +
            (rewardsToUnlock * 1e18) /
            m.totalStakingShares();
    }

    /**
     * @notice compute estimated GYSR bonus for stake
     * @param module module contract address
     * @param shares number of shares that would be staked
     * @param gysr number of GYSR tokens that would be applied to stake
     * @return estimated GYSR multiplier
     */
    function gysrBonus(
        address module,
        uint256 shares,
        uint256 gysr
    ) public view returns (uint256) {
        IERC20FriendlyRewardModuleV2 m = IERC20FriendlyRewardModuleV2(module);
        return
            gysr.gysrBonus(
                shares,
                m.totalRawStakingShares() + shares,
                m.usage()
            );
    }
}
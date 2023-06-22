/*
ERC20CompetitiveRewardModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IRewardModule.sol";
import "../ERC20CompetitiveRewardModule.sol";
import "../GysrUtils.sol";

/**
 * @title ERC20 competitive reward module info library
 *
 * @notice this library provides read-only convenience functions to query
 * additional information about the ERC20CompetitiveRewardModule contract.
 */
library ERC20CompetitiveRewardModuleInfo {
    using GysrUtils for uint256;

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
        (rewards_[0], , ) = preview(module, account, shares, 0);
    }

    /**
     * @notice preview estimated rewards
     * @param module address of reward module
     * @param account bytes32 account of interest for preview
     * @param shares number of shares that would be unstaked
     * @param gysr number of GYSR tokens that would be applied
     * @return estimated reward
     * @return estimated time multiplier
     * @return estimated gysr multiplier
     */
    function preview(
        address module,
        bytes32 account,
        uint256 shares,
        uint256 gysr
    ) public view returns (uint256, uint256, uint256) {
        ERC20CompetitiveRewardModule m = ERC20CompetitiveRewardModule(module);

        // get associated share seconds
        uint256 rawShareSeconds;
        uint256 bonusShareSeconds;
        (rawShareSeconds, bonusShareSeconds) = userShareSeconds(
            module,
            account,
            shares
        );
        if (rawShareSeconds == 0) {
            return (0, 0, 0);
        }

        uint256 timeBonus = (bonusShareSeconds * 1e18) / rawShareSeconds;

        // apply gysr bonus
        uint256 gysrBonus = gysr.gysrBonus(
            shares,
            m.totalStakingShares(),
            m.usage()
        );
        bonusShareSeconds = (gysrBonus * bonusShareSeconds) / 1e18;

        // compute rewards based on expected updates
        uint256 reward = (unlocked(module) * bonusShareSeconds) /
            (totalShareSeconds(module) + bonusShareSeconds - rawShareSeconds);

        return (reward, timeBonus, gysrBonus);
    }

    /**
     * @notice compute effective unlocked rewards
     * @param module address of reward module
     * @return estimated current unlocked rewards
     */
    function unlocked(address module) public view returns (uint256) {
        ERC20CompetitiveRewardModule m = ERC20CompetitiveRewardModule(module);

        // compute expected updates to global totals
        uint256 deltaUnlocked;
        address tkn = m.tokens()[0];
        uint256 totalLockedShares = m.lockedShares(tkn);
        if (totalLockedShares != 0) {
            uint256 sharesToUnlock;
            for (uint256 i = 0; i < m.fundingCount(tkn); i++) {
                sharesToUnlock = sharesToUnlock + m.unlockable(tkn, i);
            }
            deltaUnlocked =
                (sharesToUnlock * m.totalLocked()) /
                totalLockedShares;
        }
        return m.totalUnlocked() + deltaUnlocked;
    }

    /**
     * @notice compute user share seconds for given number of shares
     * @param module module contract address
     * @param account user account
     * @param shares number of shares
     * @return raw share seconds
     * @return time bonus share seconds
     */
    function userShareSeconds(
        address module,
        bytes32 account,
        uint256 shares
    ) public view returns (uint256, uint256) {
        require(shares > 0, "crmi1");

        ERC20CompetitiveRewardModule m = ERC20CompetitiveRewardModule(module);

        uint256 rawShareSeconds;
        uint256 timeBonusShareSeconds;

        // compute first-in-last-out, time bonus weighted, share seconds
        uint256 i = m.stakeCount(account);
        while (shares > 0) {
            require(i > 0, "crmi2");
            i -= 1;
            uint256 s;
            uint256 time;
            (s, time) = m.stakes(account, i);
            time = block.timestamp - time;

            // only redeem partial stake if more shares left than needed to burn
            s = s < shares ? s : shares;

            rawShareSeconds += (s * time);
            timeBonusShareSeconds += ((s * time * m.timeBonus(time)) / 1e18);
            shares -= s;
        }
        return (rawShareSeconds, timeBonusShareSeconds);
    }

    /**
     * @notice compute total expected share seconds for a rewards module
     * @param module address for reward module
     * @return expected total shares seconds
     */
    function totalShareSeconds(address module) public view returns (uint256) {
        ERC20CompetitiveRewardModule m = ERC20CompetitiveRewardModule(module);

        return
            m.totalStakingShareSeconds() +
            (block.timestamp - m.lastUpdated()) *
            m.totalStakingShares();
    }
}
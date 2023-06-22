/*
ERC20MultiRewardModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IRewardModule.sol";
import "../ERC20MultiRewardModule.sol";
import "./TokenUtilsInfo.sol";

/**
 * @title ERC20 multi reward module info library
 *
 * @notice this library provides read-only convenience functions to query
 * additional information about the ERC20MultiRewardModule contract.
 */
library ERC20MultiRewardModuleInfo {
    using TokenUtilsInfo for IERC20;

    // -- IRewardModuleInfo ---------------------------------------------------

    /**
     * @notice convenience function to get all token metadata in a single call
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
        IRewardModule m = IRewardModule(module);

        addresses_ = m.tokens();
        names_ = new string[](addresses_.length);
        symbols_ = new string[](addresses_.length);
        decimals_ = new uint8[](addresses_.length);

        for (uint256 i; i < addresses_.length; ++i) {
            IERC20Metadata tkn = IERC20Metadata(addresses_[i]);
            names_[i] = tkn.name();
            symbols_[i] = tkn.symbol();
            decimals_[i] = tkn.decimals();
        }
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
        IRewardModule m = IRewardModule(module);
        (rewards_, ) = preview(module, account, shares, m.tokens());
    }

    // -- ERC20MultiRewardModuleInfo ------------------------------------------

    /**
     * @notice preview estimated rewards
     * @param module address of reward module
     * @param account bytes32 account of interest for preview
     * @param shares number of shares that would be unstaked
     * @param tokens_ reward token addresses
     * @return rewards_ estimated reward balances
     * @return vesting_ estimated time vesting coeffs weighted by rewards
     */
    function preview(
        address module,
        bytes32 account,
        uint256 shares,
        address[] memory tokens_
    )
        public
        view
        returns (uint256[] memory rewards_, uint256[] memory vesting_)
    {
        require(shares > 0, "mrmi1");
        ERC20MultiRewardModule m = ERC20MultiRewardModule(module);

        rewards_ = new uint256[](tokens_.length);
        vesting_ = new uint256[](tokens_.length);

        uint256 i = m.stakeCount(account);

        // redeem first-in-last-out
        while (shares > 0) {
            require(i > 0, "mrmi2");
            i -= 1;

            (uint256 s, uint256 ts, ) = m.stakes(account, i);

            // only redeem partial stake if more shares left than needed to burn
            s = s <= shares ? s : shares;

            for (uint256 j; j < rewards_.length; ++j) {
                uint256 r = rewardsPerStakedShare(module, tokens_[j]);

                // check if stake is registered for reward
                uint256 tally = m.stakeRegistered(account, i, tokens_[j]);
                if (tally == 0) continue;

                // get raw rewards
                r = ((r - tally) * s) / 1e18;
                vesting_[j] += r;

                // time vesting
                if (block.timestamp < ts + m.vestingPeriod()) {
                    uint256 v = m.vestingStart() +
                        ((1e18 - m.vestingStart()) * (block.timestamp - ts)) /
                        m.vestingPeriod();
                    r = (r * v) / 1e18;
                }

                rewards_[j] += r;
            }
            shares -= s;
        }

        // compute vesting coefficients
        for (uint256 j; j < rewards_.length; ++j) {
            if (vesting_[j] == 0) continue;
            vesting_[j] = (rewards_[j] * 1e18) / vesting_[j];
        }

        // adjust shares to amount
        for (uint256 j; j < rewards_.length; ++j) {
            if (m.totalShares(tokens_[j]) == 0) continue;
            rewards_[j] = IERC20(tokens_[j]).getAmount(
                module,
                m.totalShares(tokens_[j]),
                rewards_[j]
            );
        }
    }

    /**
     * @notice preview estimated rewards for claim (by index)
     * @param module address of reward module
     * @param account bytes32 account of interest for preview
     * @param start start of claim index range
     * @param end end of claim index range, exclusive
     * @param tokens_ reward token addresses
     * @return rewards_ estimated reward balances
     * @return vesting_ estimated time vesting coeffs weighted by rewards
     */
    function preview(
        address module,
        bytes32 account,
        uint256 start,
        uint256 end,
        address[] memory tokens_
    )
        public
        view
        returns (uint256[] memory rewards_, uint256[] memory vesting_)
    {
        ERC20MultiRewardModule m = ERC20MultiRewardModule(module);
        require(start < end, "mrmi3");
        require(end <= m.stakeCount(account), "mrmi4");

        rewards_ = new uint256[](tokens_.length);
        vesting_ = new uint256[](tokens_.length);

        for (uint256 i = start; i < end; ++i) {
            (uint256 s, uint256 ts, ) = m.stakes(account, i);

            for (uint256 j; j < rewards_.length; ++j) {
                uint256 r = rewardsPerStakedShare(module, tokens_[j]);

                // check if stake is registered for reward
                uint256 tally = m.stakeRegistered(account, i, tokens_[j]);
                if (tally == 0) continue;

                // get raw rewards
                r = ((r - tally) * s) / 1e18;
                vesting_[j] += r;

                // time vesting
                if (block.timestamp < ts + m.vestingPeriod()) {
                    uint256 v = m.vestingStart() +
                        ((1e18 - m.vestingStart()) * (block.timestamp - ts)) /
                        m.vestingPeriod();
                    r = (r * v) / 1e18;
                }

                rewards_[j] += r;
            }
        }

        // compute vesting coefficients
        for (uint256 j; j < rewards_.length; ++j) {
            if (vesting_[j] == 0) continue;
            vesting_[j] = (rewards_[j] * 1e18) / vesting_[j];
        }

        // adjust shares to amount
        for (uint256 j; j < rewards_.length; ++j) {
            if (m.totalShares(tokens_[j]) == 0) continue;
            rewards_[j] = IERC20(tokens_[j]).getAmount(
                module,
                m.totalShares(tokens_[j]),
                rewards_[j]
            );
        }
    }

    /**
     * @notice convenience function to get registered accumulators for account
     * @param module address of reward module
     * @param account bytes32 account of interest
     * @param start start of stake index range
     * @param end end of stake index range, exclusive
     * @param tokens_ reward token addresses
     * @return registered_ accumulators for each stake and reward token
     */
    function registered(
        address module,
        bytes32 account,
        uint256 start,
        uint256 end,
        address[] memory tokens_
    ) public view returns (uint256[][] memory registered_) {
        ERC20MultiRewardModule m = ERC20MultiRewardModule(module);
        require(start < end, "mrmi5");
        require(end <= m.stakeCount(account), "mrmi6");

        registered_ = new uint256[][](end - start);

        for (uint256 i = start; i < end; ++i) {
            registered_[i - start] = new uint256[](tokens_.length);

            for (uint256 j; j < tokens_.length; ++j) {
                registered_[i - start][j] = m.stakeRegistered(
                    account,
                    i,
                    tokens_[j]
                );
            }
        }
    }

    /**
     * @notice compute reward shares to be unlocked on the next update
     * @param module address of reward module
     * @param token address of reward token
     * @return estimated unlockable rewards
     */
    function unlockable(
        address module,
        address token
    ) public view returns (uint256) {
        ERC20MultiRewardModule m = ERC20MultiRewardModule(module);
        if (m.lockedShares(token) == 0) {
            return 0;
        }
        uint256 sharesToUnlock = 0;
        uint256 count = m.fundingCount(token);
        for (uint256 i = 0; i < count; i++) {
            sharesToUnlock += m.unlockable(token, i);
        }
        return sharesToUnlock;
    }

    /**
     * @notice compute effective unlocked rewards
     * @param module address of reward module
     * @param token address of reward token
     * @return estimated current unlocked rewards
     */
    function unlocked(
        address module,
        address token
    ) public view returns (uint256) {
        ERC20MultiRewardModule m = ERC20MultiRewardModule(module);
        IERC20 tkn = IERC20(token);
        uint256 totalShares = m.totalShares(address(tkn));
        if (totalShares == 0) {
            return 0;
        }

        uint256 shares = m.totalShares(token) -
            m.lockedShares(token) +
            unlockable(module, token);

        return tkn.getAmount(module, totalShares, shares);
    }

    /**
     * @notice compute effective rewards per staked share
     * @param module module contract address
     * @param token address of reward token
     * @return estimated rewards per staked share
     */
    function rewardsPerStakedShare(
        address module,
        address token
    ) public view returns (uint256) {
        ERC20MultiRewardModule m = ERC20MultiRewardModule(module);

        (uint256 stakingShares, uint256 accumulator, uint256 dust) = m.rewards(
            token
        );
        if (stakingShares == 0) {
            return accumulator;
        }
        uint256 rewardsToUnlock = unlockable(module, token) + dust;
        return accumulator + (rewardsToUnlock * 1e18) / stakingShares;
    }
}
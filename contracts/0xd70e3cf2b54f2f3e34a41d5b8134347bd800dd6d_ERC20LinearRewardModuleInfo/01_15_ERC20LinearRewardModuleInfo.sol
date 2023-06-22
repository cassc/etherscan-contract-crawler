/*
ERC20LinearRewardModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IRewardModule.sol";
import "../ERC20LinearRewardModule.sol";
import "./TokenUtilsInfo.sol";

/**
 * @title ERC20 linear reward module info library
 *
 * @notice this library provides read-only convenience functions to query
 * additional information about the ERC20LinearRewardModule contract.
 */
library ERC20LinearRewardModuleInfo {
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
        rewards_[0] = preview(module, account);
    }

    /**
     * @notice preview estimated rewards
     * @param module address of reward module
     * @param account bytes32 account of interest for preview
     * @return estimated reward
     */
    function preview(
        address module,
        bytes32 account
    ) public view returns (uint256) {
        ERC20LinearRewardModule m = ERC20LinearRewardModule(module);

        // get effective elapsed time
        uint256 budget = m.rewardShares() - m.earned();
        uint256 e = block.timestamp - m.lastUpdated();

        if (budget < (m.stakingShares() * e * m.rate()) / 1e18) {
            // over budget, clip elapsed
            e = budget / ((m.stakingShares() * m.rate()) / 1e18);
        }
        uint256 elapsed = m.elapsed() + e;

        // compute earned
        (uint256 shares, uint256 timestamp, uint256 earned) = m.positions(
            account
        );
        uint256 r = earned + (shares * m.rate() * (elapsed - timestamp)) / 1e18;

        if (r == 0) return 0;

        IERC20 tkn = IERC20(m.tokens()[0]);
        return tkn.getAmount(module, m.rewardShares(), r);
    }

    /**
     * @notice compute effective runway with current budget and reward rate
     * @param module address of reward module
     * @return estimated runway in seconds
     */
    function runway(address module) public view returns (uint256) {
        ERC20LinearRewardModule m = ERC20LinearRewardModule(module);
        if (m.stakingShares() == 0) return 0;

        uint256 budget = m.rewardShares() - m.earned();
        uint256 t = budget / ((m.stakingShares() * m.rate()) / 1e18);
        uint256 dt = block.timestamp - m.lastUpdated();

        return (t > dt) ? t - dt : 0;
    }

    /**
     * @notice check potential increase in shares for sufficient budget and runway
     * @param module address of reward module
     * @param shares number of shares to be staked
     * @return okay if stake amount is within budget for time period
     * @return estimated runway in seconds
     */
    function validate(
        address module,
        uint256 shares
    ) public view returns (bool, uint256) {
        ERC20LinearRewardModule m = ERC20LinearRewardModule(module);
        if (m.stakingShares() + shares == 0) return (false, 0);

        uint256 budget = m.rewardShares() - m.earned();
        uint256 dt = block.timestamp - m.lastUpdated();
        uint256 earned = (m.stakingShares() * dt * m.rate()) / 1e18;

        // already depleted
        if (budget < earned) return (false, 0);

        // get runway with added shares updated budget
        budget -= earned;
        uint256 t = budget / (((m.stakingShares() + shares) * m.rate()) / 1e18);

        return (t > m.period(), t);
    }

    /**
     * @notice get withdrawable excess budget
     * @param module address of linear reward module
     * @return withdrawable budget in tokens
     */
    function withdrawable(address module) public view returns (uint256) {
        ERC20LinearRewardModule m = ERC20LinearRewardModule(module);

        // earned since last update
        uint256 budget = m.rewardShares() - m.earned();
        uint256 dt = block.timestamp - m.lastUpdated();
        uint256 earned = (m.stakingShares() * dt * m.rate()) / 1e18;
        if (budget < earned) return 0; // already depleted
        budget -= earned;

        // committed rolling period
        uint256 committed = (m.stakingShares() * m.period() * m.rate()) / 1e18;
        if (budget < committed) return 0;
        budget -= committed;

        IERC20 tkn = IERC20(m.tokens()[0]);
        return tkn.getAmount(module, m.rewardShares(), budget);
    }
}
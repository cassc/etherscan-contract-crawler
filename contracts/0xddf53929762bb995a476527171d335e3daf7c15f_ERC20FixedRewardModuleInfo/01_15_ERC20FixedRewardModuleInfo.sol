/*
ERC20FixedRewardModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IRewardModule.sol";
import "../ERC20FixedRewardModule.sol";
import "./TokenUtilsInfo.sol";

/**
 * @title ERC20 fixed reward module info library
 *
 * @notice this library provides read-only convenience functions to query
 * additional information about the ERC20FixedRewardModule contract.
 */
library ERC20FixedRewardModuleInfo {
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
        (rewards_[0], ) = preview(module, account);
    }

    /**
     * @notice preview estimated rewards
     * @param module address of reward module
     * @param account bytes32 account of interest for preview
     * @return estimated reward
     * @return estimated time vesting coefficient
     */
    function preview(
        address module,
        bytes32 account
    ) public view returns (uint256, uint256) {
        ERC20FixedRewardModule m = ERC20FixedRewardModule(module);
        (uint256 debt, , uint256 earned, uint128 timestamp, uint128 updated) = m
            .positions(account);

        uint256 r = earned;
        {
            uint256 end = timestamp + m.period();
            if (block.timestamp > end) {
                r += debt;
            } else {
                r += (debt * (block.timestamp - updated)) / (end - updated);
            }
        }

        if (r == 0) return (0, 0);

        // convert to tokens
        r = IERC20(m.tokens()[0]).getAmount(module, m.rewards(), r);

        // get vesting coeff
        uint256 v = 1e18;
        if (block.timestamp < timestamp + m.period())
            v = ((block.timestamp - timestamp) * 1e18) / m.period();

        return (r, v);
    }

    /**
     * @notice get effective budget
     * @param module address of reward module
     * @return estimated budget in debt shares
     */
    function budget(address module) public view returns (uint256) {
        ERC20FixedRewardModule m = ERC20FixedRewardModule(module);
        return m.rewards() - m.debt();
    }

    /**
     * @notice check potential increase in staking shares for sufficient budget
     * @param module address of reward module
     * @param shares number of shares to be staked
     * @return okay if stake amount is within budget for time period
     * @return estimated debt shares allocated
     * @return remaining total debt shares
     */
    function validate(
        address module,
        uint256 shares
    ) public view returns (bool, uint256, uint256) {
        ERC20FixedRewardModule m = ERC20FixedRewardModule(module);

        uint256 reward = (shares * m.rate()) / 1e18;
        uint256 budget_ = budget(module);
        if (reward > budget_) return (false, reward, 0);

        return (true, reward, budget_ - reward);
    }

    /**
     * @notice get withdrawable excess budget
     * @param module address of reward module
     * @return withdrawable budget in tokens
     */
    function withdrawable(address module) public view returns (uint256) {
        ERC20FixedRewardModule m = ERC20FixedRewardModule(module);
        IERC20 tkn = IERC20(m.tokens()[0]);
        return tkn.getAmount(module, m.rewards(), budget(module));
    }
}
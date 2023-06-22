/*
AssignmentStakingModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "../interfaces/IStakingModule.sol";
import "../AssignmentStakingModule.sol";

/**
 * @title Assignment staking module info library
 *
 * @notice this library provides read-only convenience functions to query
 * additional information about the ERC20StakingModule contract.
 */
library AssignmentStakingModuleInfo {
    // -- IStakingModuleInfo --------------------------------------------------

    /**
     * @notice convenient function to get all token metadata in a single call
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
    }

    /**
     * @notice get all staking positions for user
     * @param module address of staking module
     * @param addr user address of interest
     * @param data additional encoded data
     * @return accounts_
     * @return shares_
     */
    function positions(
        address module,
        address addr,
        bytes calldata data
    )
        external
        view
        returns (bytes32[] memory accounts_, uint256[] memory shares_)
    {
        uint256 s = shares(module, addr, 0);
        if (s > 0) {
            accounts_ = new bytes32[](1);
            shares_ = new uint256[](1);
            accounts_[0] = bytes32(uint256(uint160(addr)));
            shares_[0] = s;
        }
    }

    // -- AssignmentStakingModuleInfo -----------------------------------------

    /**
     * @notice quote the share value for an amount of tokens
     * @param module address of staking module
     * @param addr account address of interest
     * @param amount number of tokens. if zero, return entire share balance
     * @return number of shares
     */
    function shares(
        address module,
        address addr,
        uint256 amount
    ) public view returns (uint256) {
        AssignmentStakingModule m = AssignmentStakingModule(module);

        // return all user shares
        if (amount == 0) {
            return m.rates(addr);
        }

        require(amount <= m.rates(addr), "smai1");
        return amount * m.SHARES_COEFF();
    }

    /**
     * @notice get shares per unit
     * @param module address of staking module
     * @return current shares per token
     */
    function sharesPerToken(address module) public view returns (uint256) {
        AssignmentStakingModule m = AssignmentStakingModule(module);
        return m.SHARES_COEFF() * 1e18;
    }
}
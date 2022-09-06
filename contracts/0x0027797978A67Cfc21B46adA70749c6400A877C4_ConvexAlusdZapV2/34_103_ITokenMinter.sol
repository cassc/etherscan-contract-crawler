// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

/**
 * @notice the Curve token minter
 * @author Curve Finance
 * @dev translated from vyper
 * license MIT
 * version 0.2.4
 */

// solhint-disable func-name-mixedcase, func-param-name-mixedcase
interface ITokenMinter {
    /**
     * @notice Mint everything which belongs to `msg.sender` and send to them
     * @param gauge_addr `LiquidityGauge` address to get mintable amount from
     */
    function mint(address gauge_addr) external;

    /**
     * @notice Mint everything which belongs to `msg.sender` across multiple gauges
     * @param gauge_addrs List of `LiquidityGauge` addresses
     */
    function mint_many(address[8] calldata gauge_addrs) external;

    /**
     * @notice Mint tokens for `_for`
     * @dev Only possible when `msg.sender` has been approved via `toggle_approve_mint`
     * @param gauge_addr `LiquidityGauge` address to get mintable amount from
     * @param _for Address to mint to
     */
    function mint_for(address gauge_addr, address _for) external;

    /**
     * @notice allow `minting_user` to mint for `msg.sender`
     * @param minting_user Address to toggle permission for
     */
    function toggle_approve_mint(address minting_user) external;
}
// solhint-enable
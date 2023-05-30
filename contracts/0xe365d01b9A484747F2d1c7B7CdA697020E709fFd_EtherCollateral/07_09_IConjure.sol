// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/// @author Conjure Finance Team
/// @title IConjure
/// @notice Interface for interacting with the Conjure Contracts
interface IConjure {
    /**
     * @dev lets the EtherCollateral contract instance burn synths
     *
     * @param account the account address where the synths should be burned
     * @param amount the amount to be burned
    */
    function burn(address account, uint amount) external;

    /**
     * @dev lets the EtherCollateral contract instance mint new synths
     *
     * @param account the account address where the synths should be minted to
     * @param amount the amount to be minted
    */
    function mint(address account, uint amount) external;

    /**
     * @dev gets the latest ETH USD Price from the given oracle
     *
     * @return the current eth usd price
    */
    function getLatestETHUSDPrice() external view returns (uint);

    /**
     * @dev sets the latest price of the synth in USD by calculation
    */
    function updatePrice() external;

    /**
     * @dev gets the latest recorded price of the synth in USD
     *
     * @return the last recorded synths price
    */
    function getLatestPrice() external view returns (uint);
}
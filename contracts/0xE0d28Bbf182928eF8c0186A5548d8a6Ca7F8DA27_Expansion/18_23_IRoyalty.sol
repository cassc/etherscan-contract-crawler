//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/**
 * @notice Interface containing shared royalty object throughout Dynamic Blueprint system
 * @author Ohimire Labs
 */
interface IRoyalty {
    /**
     * @notice Shared royalty object
     * @param recipients Royalty recipients
     * @param royaltyCutsBPS Percentage of purchase allocated to each royalty recipient, in basis points
     */
    struct Royalty {
        address[] recipients;
        uint32[] royaltyCutsBPS;
    }
}
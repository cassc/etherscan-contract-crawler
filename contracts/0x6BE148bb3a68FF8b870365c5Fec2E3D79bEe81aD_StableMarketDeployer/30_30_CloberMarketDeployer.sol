// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface CloberMarketDeployer {
    /**
     * @notice Emitted when a new market is deployed.
     * @param market The address of the generated market.
     */
    event Deploy(address indexed market);
}
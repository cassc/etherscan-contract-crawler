// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { IDDX } from "./interfaces/IDDX.sol";

/**
 * @title DDXWalletCloneable
 * @author DerivaDEX
 * @notice This is a cloneable on-chain DDX wallet that holds a trader's
 *         stakes and issued rewards.
 */
contract DDXWalletCloneable {
    // Whether contract has already been initialized once before
    bool initialized;

    /**
     * @notice This function initializes the on-chain DDX wallet
     *         for a given trader.
     * @param _trader Trader address.
     * @param _ddxToken DDX token address.
     * @param _derivaDEX DerivaDEX Proxy address.
     */
    function initialize(
        address _trader,
        IDDX _ddxToken,
        address _derivaDEX
    ) external {
        // Prevent initializing more than once
        require(!initialized, "DDXWalletCloneable: already init.");
        initialized = true;

        // Automatically delegate the holdings of this contract/wallet
        // back to the trader.
        _ddxToken.delegate(_trader);

        // Approve the DerivaDEX Proxy contract for unlimited transfers
        _ddxToken.approve(_derivaDEX, uint96(-1));
    }
}
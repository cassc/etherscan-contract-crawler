// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

library WhitelistableState {
    struct WhitelistConfig {
        bytes32 merkleRoot;
        uint8 amount;
        uint24 mintPriceInFinney;
        uint32 mintStartTS;
        uint32 mintEndTS;
    }

    struct WLState {
        // hash(EditionId + mintable amount + price)
        mapping(uint256 => WhitelistConfig) _whitelistConfig;
    }


    /**
     * @dev Get storage data from dedicated slot.
     * This pattern avoids storage conflict during proxy upgrades
     * and give more flexibility when creating extensions
     */
    function _getWhitelistableState()
        internal
        pure
        returns (WLState storage state)
    {
        bytes32 storageSlot = keccak256("liveart.Whitelistable");
        assembly {
            state.slot := storageSlot
        }
    }
}
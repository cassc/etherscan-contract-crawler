// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IEssenceNFTEvents {
    /**
     * @notice Emiited when the essence NFT is initialized
     *
     * @param profileId The profile ID for the Essence NFT.
     * @param essenceId The essence ID for the Essence NFT.
     * @param name The name for the Essence NFT.
     * @param symbol The symbol for the Essence NFT.
     * @param transferable Whether the Essence NFT is transferable.
     */
    event Initialize(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        string name,
        string symbol,
        bool transferable
    );
}
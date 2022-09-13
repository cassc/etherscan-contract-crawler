// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ISubscribeNFTEvents {
    /**
     * @notice Emiited when the subscribe NFT is initialized
     *
     * @param profileId The profile ID for the Susbcribe NFT.
     * @param name The name for the Subscribe NFT.
     * @param symbol The symbol for the Subscribe NFT.
     */
    event Initialize(uint256 indexed profileId, string name, string symbol);
}
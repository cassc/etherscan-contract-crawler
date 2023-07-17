// SPDX-License-Identifier: CC-BY-NC-ND-4.0

/*

 _____ _____   ___  ________   __  _____   ___  ________   _______
/  ___/  __ \ / _ \ | ___ \ \ / / |  __ \ / _ \ | ___ \ \ / /  ___|
\ `--.| /  \// /_\ \| |_/ /\ V /  | |  \// /_\ \| |_/ /\ V /\ `--.
 `--. \ |    |  _  ||    /  \ /   | | __ |  _  ||    /  \ /  `--. \
/\__/ / \__/\| | | || |\ \  | |   | |_\ \| | | || |\ \  | | /\__/ /
\____/ \____/\_| |_/\_| \_| \_/    \____/\_| |_/\_| \_| \_/ \____/

A generative collection by Mister Goldie
Curated by imnotArt

Physical: 1010 N. Ashland, Chicago IL - https://goo.gl/maps/gyoSKSbUZvGMLHBV7
Metaverse: 2 Exciting Field, Vibes CV - https://www.cryptovoxels.com/parcels/4927

Smart Contract by imnotArt Team:
Ian Olson
Joseph Hirn

*/

pragma solidity ^0.8.10;
pragma abicoder v2;

import "./core/CoreDrop721.sol";

contract ScaryGarys is CoreDrop721 {

    // ---
    // Constructor
    // ---

    // @dev Contract constructor.
    constructor() CoreDrop721(
        NftOptions({
            name: "Scary Garys",
            symbol: "GARYS",
            imnotArtBps: 0,
            royaltyBps: 750,
            startingTokenId: 1,
            maxInvocations: 750,
            contractUri: "https://ipfs.imnotart.com/ipfs/QmTZ3PyPH3Nnby2R58uVpaDcm5ahSnqmo2h4QoMm39NybX"
        }), 
        DropOptions({
            metadataBaseUri: "https://api.imnotart.com/",
            mintPriceInWei: 0.05 ether,
            maxQuantityPerTransaction: 10,
            autoPayout: false,
            active: false,
            presaleMint: true,
            presaleActive: true,
            imnotArtPayoutAddress: msg.sender,
            artistPayoutAddress: msg.sender,
            maxPerWalletEnabled: true,
            maxPerWalletQuantity: 10
        })
    ){
    }
}
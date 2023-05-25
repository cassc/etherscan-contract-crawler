// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {EtherealStatesMeta} from './EtherealStatesMeta.sol';

/// @title EtherealStates - https://etherealstates.art
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
contract EtherealStates is EtherealStatesMeta {
    constructor(
        string memory contractURI_,
        address mintPasses,
        address newSigner,
        address dnaGenerator_,
        address metadataManager_,
        VRFConfig memory vrfConfig_
    )
        EtherealStatesMeta(
            contractURI_,
            mintPasses,
            newSigner,
            dnaGenerator_,
            metadataManager_,
            vrfConfig_
        )
    {}
}
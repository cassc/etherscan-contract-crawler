// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./BaseNFT.sol";

contract MegaMansionNFT is Ownable, BaseNFT {
    string private tokenMetadataUriPrefix = "https://medias.landz.io/nft/megamansion/metadata/";
    string private contractMetadataUri =
        "https://medias.landz.io/nft/megamansion/megamansion-contract.json";

    constructor()
        BaseNFT("The Mega Mansion Collection", "LDZ", tokenMetadataUriPrefix, contractMetadataUri)
    {}
}
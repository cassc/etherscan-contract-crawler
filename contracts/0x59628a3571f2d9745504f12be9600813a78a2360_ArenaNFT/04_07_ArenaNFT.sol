// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./BaseNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArenaNFT is Ownable, BaseNFT {
    string private tokenMetadataUriPrefix = "https://medias.landz.io/nft/arena/metadata/";
    string private contractMetadataUri = "https://medias.landz.io/nft/arena/arena-contract.json";

    constructor()
        BaseNFT("The Arena Collection", "LDZ", tokenMetadataUriPrefix, contractMetadataUri)
    {}
}
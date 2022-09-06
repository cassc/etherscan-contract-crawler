// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./standards/ERC721G.sol";

contract GaiaSupernova is ERC721G {
    constructor() ERC721G("Gaia Protocol Supernova", "GAIA", "https://api.gaiaprotocol.com/metadata/supernova/") {}
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./standards/ERC721G.sol";

contract GaiaGenesis is ERC721G {
    constructor() ERC721G("Gaia Protocol Genesis", "GAIA", "https://api.gaiaprotocol.com/metadata/genesis/") {}
}
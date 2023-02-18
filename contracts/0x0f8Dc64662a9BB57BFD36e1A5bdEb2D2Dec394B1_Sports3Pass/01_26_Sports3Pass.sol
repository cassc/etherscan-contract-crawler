// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ERC721Core } from "../core/ERC721Core.sol";

contract Sports3Pass is ERC721Core {
    constructor()
        ERC721Core("Sports3 Pass", "SPP", address(0), 0, 3333, "", "")
    {}
}
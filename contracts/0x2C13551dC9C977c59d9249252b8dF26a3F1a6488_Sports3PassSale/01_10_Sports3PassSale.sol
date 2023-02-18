// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ERC721Sale } from "../core/ERC721Sale.sol";

contract Sports3PassSale is ERC721Sale {
    constructor(address newMintAddress) ERC721Sale(newMintAddress) {}
}
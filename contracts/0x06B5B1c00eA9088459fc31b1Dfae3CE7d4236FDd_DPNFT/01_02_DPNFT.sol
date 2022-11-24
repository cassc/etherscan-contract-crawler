// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Dreadful Pumpkinz
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract DPNFT is ERC721Community {
    constructor() ERC721Community("Dreadful Pumpkinz", "DPNFT", 1111, 100, START_FROM_ONE, "ipfs://bafybeifkxntjohml6kg4rsgvsf6tdzlsmdwxkrfzjked6sc2m7ixqnrpbm/",
                                  MintConfig(0.03 ether, 20, 20, 0, 0xf63A39EcD200A4BCA571355Cffffa0F107b6Fcd5, false, false, false)) {}
}
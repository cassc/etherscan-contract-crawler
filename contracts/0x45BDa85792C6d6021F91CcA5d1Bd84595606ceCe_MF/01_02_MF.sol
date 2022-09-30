// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Metafins
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract MF is ERC721Community {
    constructor() ERC721Community("Metafins", "MF", 10000, 10, START_FROM_ONE, "ipfs://bafybeih66eouspwx3dxl432gi4rsfczoejwe25m5jbxvqwkwss3eny475y/",
                                  MintConfig(0.1 ether, 10, 10, 0, 0x52E57Baae360403775534Dae1D11BE0C875F34b4, false, false, false)) {}
}
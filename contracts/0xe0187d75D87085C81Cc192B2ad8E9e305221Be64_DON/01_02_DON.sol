// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: DeOracles NFT
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract DON is ERC721Community {
    constructor() ERC721Community("DeOracles NFT", "DON", 1000, 300, START_FROM_ONE, "ipfs://bafybeiav4k5a3lneumv7qt54edeyph4bldfex2lub5yjzj6tshao7omtxa/",
                                  MintConfig(0.02 ether, 20, 20, 0, 0x17adc85ED1874fBBB48ab7550143D49E8e798E2f, true, false, false)) {}
}
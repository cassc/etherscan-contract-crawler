// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: RadiantMojiNft
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract RMN is ERC721Community {
    constructor() ERC721Community("RadiantMojiNft", "RMN", 1000, 1, START_FROM_ONE, "ipfs://bafybeiheoiunc7jmz5s65pdfwwaqaaet5edpnloupxv3kb7moj2zxohuum/",
                                  MintConfig(0.004 ether, 5, 10, 0, 0x10725Cb8167c10aF67E169d52556A98aC4902285, false, false, false)) {}
}
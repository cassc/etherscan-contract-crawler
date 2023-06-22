// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// ██╗      █████╗ ███╗   ███╗ ██████╗
// ██║     ██╔══██╗████╗ ████║██╔═══██╗
// ██║     ███████║██╔████╔██║██║   ██║
// ██║     ██╔══██║██║╚██╔╝██║██║   ██║
// ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝
// ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝

import "../ExPopulusERC721WithSingleMetadataIPFS.sol";

contract LAMO_Fallon_Deluxe_001 is ExPopulusERC721WithSingleMetadataIPFS {
  constructor()
    ExPopulusERC721WithSingleMetadataIPFS(
        "Fallon Deluxe 001",
        "LAMO",
        "ipfs://",
        "QmVx9NiNfLZvwqEuTHyf3bHQt26mJCZfZvBwiSP5MR1LQz",
        "https://ipfs.io/ipfs/",
        "QmUzdN7B4PY9zHh3G91j5S94WEGp5ahsW9vrP5tKPcpGHS",
        333,
        30000000000000000,
        500,
        payable(address(0xbA1547331e29f1ee3606941B42A296f3a1612888)),
        payable(address(0xbA1547331e29f1ee3606941B42A296f3a1612888))
    ) {}
}
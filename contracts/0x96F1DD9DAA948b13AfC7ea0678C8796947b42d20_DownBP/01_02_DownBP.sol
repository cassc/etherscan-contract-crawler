// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Down Bad Pepe
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract DownBP is ERC721Community {
    constructor() ERC721Community("Down Bad Pepe", "DownBP", 333, 1, START_FROM_ONE, "ipfs://bafybeigc424mojm2qzeajo75d2r52l3siilxg4ihq6bwyb3gjnahic6npu/",
                                  MintConfig(0.004 ether, 10, 20, 0, 0x324fBfeF8a74CfcFF03311C4107481DF9c60E1fE, false, false, false)) {}
}
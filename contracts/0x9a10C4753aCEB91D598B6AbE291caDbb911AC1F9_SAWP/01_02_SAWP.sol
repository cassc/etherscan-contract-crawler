// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: SNAFU Ape Wagmi Punks
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract SAWP is ERC721Community {
    constructor() ERC721Community("SNAFU Ape Wagmi Punks", "SAWP", 9999, 749, START_FROM_ONE, "ipfs://bafybeih3z3ymewwngzqevb2ybssfv2p75nmwv35qibmrkfbu3dc4kjrrxq/",
                                  MintConfig(0.0069 ether, 20, 20, 0, 0x9bFbF46C67cfdbFc1c444a2f3FFA9a4171D4616e, false, false, false)) {}
}
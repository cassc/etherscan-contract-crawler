// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: BadInfluencerClub
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract BIC is ERC721Community {
    constructor() ERC721Community("BadInfluencerClub", "BIC", 10000, 50, START_FROM_ONE, "ipfs://bafybeiazzr2qi6m5ohutsh2tduupsg5xoheset7npndlrfvqwvifl25fpa/",
                                  MintConfig(0.0009 ether, 5, 5, 0, 0x6483Cd1a106dc3Ddef5a10a7eb4C337bEFE918A2, false, false, false)) {}
}
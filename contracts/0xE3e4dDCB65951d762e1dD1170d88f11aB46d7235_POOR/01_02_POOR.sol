// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Poor Penguins
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract POOR is ERC721Community {
    constructor() ERC721Community("Poor Penguins", "POOR", 5000, 5, START_FROM_ONE, "ipfs://bafybeidnmezzgebyl7uih4wf6ps4h5mg72gdw6zvanq7dujs2emabvuze4/",
                                  MintConfig(0.05 ether, 5, 5, 0, 0x1a167b4fEf71d1bDc63d7D41E0A5e1d36F5b1a87, false, false, false)) {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: NIKI GENESIS
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract NIKIGEN is ERC721Community {
    constructor() ERC721Community("NIKI GENESIS", "NIKIGEN", 500, 100, START_FROM_ONE, "ipfs://bafybeihkq4rwgbthgrnyrd7xbyl6zclilzagxobs3hjou6g4uldflfyiae/",
                                  MintConfig(0 ether, 3, 3, 0, 0x012584C85Ff704555451234457992609c6e561bB, false, false, false)) {}
}
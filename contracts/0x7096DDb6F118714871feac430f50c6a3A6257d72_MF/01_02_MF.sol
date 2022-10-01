// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Metafins Official
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract MF is ERC721Community {
    constructor() ERC721Community("Metafins Official", "MF", 10000, 10, START_FROM_ONE, "ipfs://bafybeigvxhuxmqmv4dca3tmzg2yhcyikqo3rz7a54ldvlvkbas6oysxnui/",
                                  MintConfig(0.1 ether, 10, 10, 0, 0x0405BDFc94FB1A81D0BeD5aBBF56ED3A64a4F820, false, false, false)) {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: AmineNoJose
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract ANJ is ERC721Community {
    constructor() ERC721Community("AmineNoJose", "ANJ", 7777, 20, START_FROM_ONE, "ipfs://bafybeigxpxs6mxt3e6o3uobvug5qej6c43na25iqnv565667csu34lgx6y/",
                                  MintConfig(0.039 ether, 3, 3, 0, 0x5Ddd0CE97517F00ba03E9A8D1e31128E3c172055, false, false, false)) {}
}
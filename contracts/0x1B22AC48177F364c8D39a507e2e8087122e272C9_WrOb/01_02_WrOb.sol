// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: WrObBuGgEr
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract WrOb is ERC721Community {
    constructor() ERC721Community("WrObBuGgEr", "WrOb", 4050, 10, START_FROM_ONE, "ipfs://bafybeieaqabsbbkapd33hv4zzicum5zquigfeyubd7tgigcf72rbzu5ebi/",
                                  MintConfig(0.0018 ether, 2, 2, 0, 0xb748c67b900419e5a1736618e26FA979478D73bF, false, false, false)) {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: WeBearzV2
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract WBZV2 is ERC721Community {
    constructor() ERC721Community("WeBearzV2", "WBZV2", 5500, 5, START_FROM_ONE, "ipfs://bafybeidl6vi2ygl7mhr63rv25b5cvfkt6hhw3sh7klc5etsenyjyl7zhwe/",
                                  MintConfig(0 ether, 1, 1, 0, 0xD8D9a80F831F7F1055A3548Db2f7142082e32C8d, false, false, false)) {}
}
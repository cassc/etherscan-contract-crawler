// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Coleccion de prueba
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract XD is ERC721Community {
    constructor() ERC721Community("Coleccion de prueba", "XD", 405, 1, START_FROM_ONE, "ipfs://bafybeidtzmegyh5qhg3erzx4u46xd4iv3rsgqovuulmg4mq7arod7xmuqm/",
                                  MintConfig(0.01 ether, 3, 20, 0, 0xF512E72d99c28310B54F042a6aa89b6a0C45e54C, false, false, false)) {}
}
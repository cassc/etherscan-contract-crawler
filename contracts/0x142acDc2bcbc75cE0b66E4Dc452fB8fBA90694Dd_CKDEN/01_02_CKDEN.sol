// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// name: Checked Denza 2
// contract by: artgene.xyz

import "./Artgene721.sol";

contract CKDEN is Artgene721 {
    constructor() Artgene721("Checked Denza 2", "CKDEN", 0, 10, START_FROM_ONE, "https://metadata.artgene.xyz/api/g/checkedenza/",
                              MintConfig(0.01 ether, 20, 20, 0, 0xa8811a290c1690C39732118331329373693D9e2A, false, 1685221200, 1685307600)) {}
}
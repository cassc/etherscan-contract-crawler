// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./BaseERC721.sol";

contract DAYC is BaseERC721 {
    constructor()
        BaseERC721("Dick Ape Yacht Club", "DAYC", 3332, 1)
    {}
}
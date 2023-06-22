// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
RootKit
Because my suggestions of WootKit and GrootKit were overruled
*/

import "./GatedERC20.sol";

contract RootKit is GatedERC20("RootKit", "ROOT")
{
    constructor()
    {
        _mint(msg.sender, 10000 ether);
    }
}
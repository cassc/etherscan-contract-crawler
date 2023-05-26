// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: AiHounds
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract AIH is ERC721Community {
    constructor() ERC721Community("AiHounds", "AIH", 2035, 20, START_FROM_ONE, "ipfs://bafybeig6wm4gwj3dxkdu5phw4sbijvximccvfc75jokfm4rruz73euk5ha/",
                                  MintConfig(0.005 ether, 5, 20, 0, 0x4571E0821D7a8299C02Efe0A3Cc4b07EFB850705, false, false, false)) {}
}
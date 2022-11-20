// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface Moonshiners is IERC721Enumerable {}

contract ViralMinter {
    Moonshiners constant MOONSHINERS =
        Moonshiners(0x239aDEeed414D163214D9b8A563c862dcf2206d0);

    bool first = true;

    function mintFor(
        address owner,
        uint256 tokenId,
        uint256 amount
    ) public {
        for (uint256 i; i < amount; ) {
            MOONSHINERS.transferFrom(owner, owner, tokenId);
            unchecked {
                i++;
            }
        }
    }

    function mint(uint256 tokenId, uint256 amount) external {
        mintFor(msg.sender, tokenId, amount);
    }
}
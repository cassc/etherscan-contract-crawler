// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract AirdropHelper {
    IERC721 private constant SEALS = IERC721(0x364C828eE171616a39897688A831c2499aD972ec);
    address private constant STAKEDSEALSV1 = 0xdf8A88212FF229446e003f8f879e263D3616b57A;
    IERC721 private constant STAKEDSEALSV2 = IERC721(0x1C70D0A86475CC707b48aA79F112857e7957274f);

    IERC721 private immutable airdrop;
  
    constructor(IERC721 _airdrop) {
        airdrop = _airdrop;
    }

    function sendToOneOfOneHolders(uint16[27] calldata sending) external {
        uint16[27] memory toOwnerOf = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 63, 2093, 4920, 5403, 6666, 6969, 9950];

        for (uint256 i = 0; i < 27;) {
            uint256 id = toOwnerOf[i];
            address owner = SEALS.ownerOf(id);

            if(owner == STAKEDSEALSV1) {
                if(id == 12) owner = 0xFE2a16030B672f8f820D5780E399978D710552CE;
                if(id == 21) owner = 0x906F8c3305ED677748A2B207D10Bf992bC5b327E;
                if(id == 2093) owner = 0x163c1D864E91900f1993f57f5EafEE36f14b9cD2;
            }

            if(owner == address(STAKEDSEALSV2)) {
                owner = STAKEDSEALSV2.ownerOf(id);
            }

            airdrop.transferFrom(msg.sender, owner, sending[i]);
            unchecked {
                ++i;
            }
        }
    }

    function bulkTransfer(uint256[] calldata sending, address[] calldata to) external {
        if(sending.length != to.length) revert();
        for (uint256 i = 0; i < sending.length;) {
            airdrop.transferFrom(msg.sender, to[i], sending[i]);
            unchecked {
                ++i;
            }
        }
    }
}
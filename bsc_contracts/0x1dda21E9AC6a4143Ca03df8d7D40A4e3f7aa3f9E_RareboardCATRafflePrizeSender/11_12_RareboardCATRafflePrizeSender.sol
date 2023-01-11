// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./RareboardCATRaffle.sol";



contract RareboardCATRafflePrizeSender is Ownable {
    uint8 private constant TOKEN_TYPE_ERC20 = 1;
    uint8 private constant TOKEN_TYPE_ERC721 = 2;
    uint8 private constant TOKEN_TYPE_ERC1155 = 3;

    RareboardCATRaffle private immutable RAFFLE = RareboardCATRaffle(0x7592Ca9e98a7825a6811cf310176756aFd9eCeBB);
   

    function sendPrizes(uint256[] calldata raffleIds, address[] calldata from) external onlyOwner {
        for (uint256 i = 0; i < raffleIds.length; ++i) {
            ( 
                address tokenAddress,
                uint8 tokenType,
                uint32 tokenIdOrAmount,
            ) = RAFFLE.rafflePrizes(raffleIds[i]);
            (
                address winner,,,
            ) = RAFFLE.raffleWinners(raffleIds[i]);

            require(winner != address(0), "No winner yet");

            if (tokenType == TOKEN_TYPE_ERC20) {
                IERC20(tokenAddress).transferFrom(from[i], winner, uint256(tokenIdOrAmount) * 1 ether);
            } else if (tokenType == TOKEN_TYPE_ERC721) {
                IERC721(tokenAddress).safeTransferFrom(from[i], winner, tokenIdOrAmount);
            } else if (tokenType == TOKEN_TYPE_ERC1155) {
                IERC1155(tokenAddress).safeTransferFrom(from[i], winner, tokenIdOrAmount, 1, "");
            }
        }
    }
}
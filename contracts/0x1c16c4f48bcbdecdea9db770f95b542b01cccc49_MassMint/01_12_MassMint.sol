// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./interfaces/IGenesisTokenMinified.sol";
import "./interfaces/IHumansTokenMinified.sol";
import "../lib/openzepplin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../lib/openzepplin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../lib/openzepplin-contracts/contracts/access/Ownable.sol";

contract MassMint is ERC1155Holder, ERC721Holder, Ownable {
    IGenesisTokenMinified private genesisToken;
    IHumansTokenMinified private humansToken;

    constructor(address GENESIS_TOKEN_ADDRESS, address HUMAN_CONTRACT_ADDRESS) {
        genesisToken = IGenesisTokenMinified(GENESIS_TOKEN_ADDRESS);
        humansToken = IHumansTokenMinified(HUMAN_CONTRACT_ADDRESS);
    }

    function massMint() external onlyOwner {
        genesisToken.safeTransferFrom(msg.sender, address(this), 10, 2, "");
        genesisToken.safeTransferFrom(msg.sender, address(this), 8, 1, "");
        genesisToken.safeTransferFrom(msg.sender, address(this), 9, 1, "");
        genesisToken.safeTransferFrom(msg.sender, address(this), 5, 1, "");
        genesisToken.safeTransferFrom(msg.sender, address(this), 6, 1, "");

        humansToken.redeemAndMintGenesis(10, 2);
        humansToken.redeemAndMintGenesis(8, 1);
        humansToken.redeemAndMintGenesis(9, 1);
        humansToken.redeemAndMintGenesis(5, 1);
        humansToken.redeemAndMintGenesis(6, 1);

        uint256 balance = humansToken.balanceOf(address(this));

        for (uint256 i; i < balance; i++) {
            uint256 tokenId = humansToken.tokenOfOwnerByIndex(address(this), 0);
            humansToken.safeTransferFrom(address(this), msg.sender, tokenId, "");
        }
    }

    function transferHumans(address receiver, uint256 tokenId) external onlyOwner {
        humansToken.safeTransferFrom(address(this), receiver, tokenId, "");
    }

    function transferGenesisTokens(address receiver, uint256 tokenId, uint256 amount) external onlyOwner {
        genesisToken.safeTransferFrom(address(this), receiver, tokenId, amount, "");
    }
}
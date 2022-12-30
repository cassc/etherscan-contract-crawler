// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IArcadeGiveawayTokenHandler.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

contract ArcadeGiveawayHandler_ERC1155 is IArcadeGiveawayTokenHandler, OwnableUpgradeable, ERC1155HolderUpgradeable {

    address public tokenAddress;
    address public arcadeGiveawayAddress;

    function initialize(address _tokenAddress, address _arcadeGiveawayAddress) public initializer {
        __Ownable_init();
        __ERC1155Holder_init();

        tokenAddress = _tokenAddress;
        arcadeGiveawayAddress = _arcadeGiveawayAddress;
    }

    modifier onlyArcadeGiveaway() {
        require(msg.sender == arcadeGiveawayAddress, "GiveawayHandler1155: NOT_GIVEAWAY");
        _;
    }

    function handleGiveaway(address to, uint256 tokenId, uint256 amountTimes) external onlyArcadeGiveaway {
        IERC1155Upgradeable(tokenAddress).safeTransferFrom(
            address(this), 
            to, 
            tokenId, 
            amountTimes, 
            ""
        );
    }

    function withdrawTokens(uint256 tokenId, uint256 amount) external onlyOwner {
        IERC1155Upgradeable(tokenAddress).safeTransferFrom(
            address(this), 
            msg.sender, 
            tokenId, 
            amount, 
            ""
        );
    }
}
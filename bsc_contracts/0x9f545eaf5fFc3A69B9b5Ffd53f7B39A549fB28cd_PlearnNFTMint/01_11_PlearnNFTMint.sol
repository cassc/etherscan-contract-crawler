// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IWETH.sol";
import "./interfaces/IPlearnNFTMintHandler.sol";

contract PlearnNFTMint {
    using SafeERC20 for IERC20;

    IWETH public WBNB;
    IPlearnNFTMintHandler public mintHandler;

    constructor(IWETH initWBNB, IPlearnNFTMintHandler initMintHandler) {
        require(address(initWBNB) != address(0), "Marketplace: WBNB handle cant be zero");
        require(address(initMintHandler) != address(0), "Marketplace: Mint handle cant be zero");
        WBNB = initWBNB;
        mintHandler = initMintHandler;
    }

    function mint(
        address receiver,
        uint256 roundId,
        uint256[] memory itemIndices
    ) public payable {
        (, , , uint256 mintPrice, , , ) = mintHandler.getRound(roundId);
        IERC20 dealToken = mintHandler.dealToken();
        uint256 netPrice = itemIndices.length * mintPrice;
        if (msg.value > 0) {
            require(address(dealToken) == address(WBNB), "Marketplace: Unable to pay with BNB");
            require(msg.value <= netPrice, "Marketplace: Overpaid BNB");
            if (msg.value < netPrice) {
                uint256 wBNBPrice = netPrice - msg.value;
                dealToken.safeTransferFrom(msg.sender, address(this), wBNBPrice);
            }
            //Wrap BNB to WBNB
            WBNB.deposit{value: msg.value}();
        } else if (netPrice > 0) {
            // Transfer token from buyer to mint contract
            dealToken.safeTransferFrom(msg.sender, address(this), netPrice);
        }
        // Check if we have enough allowance and approve it if needed
        uint256 allowance = dealToken.allowance(address(this), address(mintHandler));
        if (allowance < netPrice) {
            dealToken.approve(address(mintHandler), type(uint256).max);
        }
        mintHandler.mint(receiver, roundId, itemIndices);
    }

    function mintToSender(uint256 roundId, uint256[] memory itemIndices) public payable {
        mint(msg.sender, roundId, itemIndices);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interface.sol";

contract GPCMiddleMan is Ownable {
    address panda3;
    address giftShop;
    address gpcHolderAddress;
    IERC20 GPCToken;
    IPandaNFT panda3SC;
    IPandaNFT giftShopSC;

    constructor(
        address _panda3,
        address _giftshop,
        address _gpcTokenAddress,
        address _gpcHolderAddress
    ) {
        panda3 = _panda3;
        giftShop = _giftshop;
        GPCToken = IERC20(_gpcTokenAddress);
        gpcHolderAddress = _gpcHolderAddress;
        panda3SC = IPandaNFT(panda3);
        giftShopSC = IPandaNFT(giftShop);
    }

    function mintPanda3(uint256[] memory tokenIds) private {
        uint256 totalGPC = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 idToMint = (1500 + tokenIds[i]);
            require(
                panda3SC.getMintTime(idToMint) == 0,
                string(
                    abi.encodePacked(
                        "Token ID ",
                        Strings.toString(idToMint),
                        " Already Minted"
                    )
                )
            );

            uint256 cost = panda3SC.getCost(idToMint);
            require(
                cost > 0,
                string(
                    abi.encodePacked(
                        "Cost of token ",
                        Strings.toString(idToMint),
                        "  not set"
                    )
                )
            );

            totalGPC += cost;
        }

        GPCToken.transferFrom(msg.sender, gpcHolderAddress, totalGPC);
        panda3SC.mint(tokenIds, msg.sender);
    }

    function mintShopItem(uint256[] memory tokenIds, uint256[] memory amounts)
        private
    {
        uint256 totalGPC = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 token_id = tokenIds[i];
            uint256 cost = giftShopSC.getPrices(token_id);

            require(cost > 0, "Token ID does not exist");

            uint256 totalSupply = giftShopSC.getSupply(token_id);
            uint256 totalMinted = giftShopSC.getMintedQuantity(token_id);
            uint256 balanceLeft = totalSupply - totalMinted;
            
            require(
                balanceLeft > 0,
                "No more supply. Purchase from secondary market"
            );

            require(amounts[i] <= balanceLeft, "Cannot mint more than supply");

            totalGPC += cost;
        }

        GPCToken.transferFrom(msg.sender, gpcHolderAddress, totalGPC);

        giftShopSC.mint(tokenIds, amounts, msg.sender);
    }

    function checkOut(
        uint256[] memory shopItems,
        uint256[] memory shopItemAmounts,
        uint256[] memory pandaIds
    ) public {
        if (shopItems.length > 0) {
            require(
                shopItems.length == shopItemAmounts.length,
                "Shop item IDS and Amounts length have to match"
            );
            mintShopItem(shopItems, shopItemAmounts);
        }

        if (pandaIds.length > 0) {
            mintPanda3(pandaIds);
        }
    }

    function setGPCTokenAddress(address _gpcTokenAddress)
        public
        virtual
        onlyOwner
    {
        GPCToken = IERC20(_gpcTokenAddress);
    }

    function setPandaContract(address _panda3) external onlyOwner {
        panda3 = _panda3;
        panda3SC = IPandaNFT(panda3);
    }

    function setGPCHolder(address _gpcHolderAddress) external onlyOwner {
        gpcHolderAddress = _gpcHolderAddress;
    }

    function setGSContract(address _giftshop) external onlyOwner {
        giftShop = _giftshop;
        giftShopSC = IPandaNFT(giftShop);
    }

    function withdraw() public onlyOwner {
        GPCToken.transfer(msg.sender, GPCToken.balanceOf(address(this)));
    }

    function withdrawEth() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
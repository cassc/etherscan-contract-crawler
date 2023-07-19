// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.6;

import "./NFTCollectableEx.sol";

contract BallerHeadz is NFTCollectableEx {
    //Name: BallerHeadz
    //Symbol: BHD
    //Initial price: 0.05 ether
    //Initial supply: 5000 items
    constructor() NFTCollectableEx("BallerHeadz", "BHD", 0.05 ether, 5000) {
        
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://www.ballerheadz.com/api/token/";
    }

    function mint() external payable mintingAllowed{
        require(
            msg.value >= mintPrice,
            "Sent value is insufficient for minting token!"
        );
        require(availableSupply() > 0, "Out of supply!");
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function mintBatch(uint256 numberOfItemsToMint) external payable mintingAllowed {
       
        require(availableSupply() - numberOfItemsToMint >= 0, "Out of supply!");

        //discount available for more items!
        //verification if sent value is sufficient... this logic must match client side code!
        uint256 discountMintPrice = mintPrice;

        if (numberOfItemsToMint >= 3 && numberOfItemsToMint < 5){
            discountMintPrice = 0.045 ether;
        }
        else if (numberOfItemsToMint >= 5 && numberOfItemsToMint < 9){
            discountMintPrice = 0.04 ether;
        }
        else if (numberOfItemsToMint >= 9 && numberOfItemsToMint <= 10){
            discountMintPrice = 0.038 ether;
        }

        require(
            msg.value >= discountMintPrice * numberOfItemsToMint,
            "Sent value is insufficient for minting tokens!"
        );

        for (uint256 i = 0; i < numberOfItemsToMint; i++) {
             _safeMint(msg.sender, totalSupply() + 1);

        }
    }
}
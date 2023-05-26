//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

library SaleLib {

    struct Sale {
        uint256 startTime;
        uint256 whitelistEndTime;
        uint256 price;
        uint256 endPrice;
        uint256 dutchTimeFrame;
        uint256 maxMintPerTx;
        uint256 maxMintPerAccount;
        bool isPaused;
        bytes32 merkleRoot;
        uint256 stock;
        uint256 minted;
    }

    function createSale(uint256 pStartTime,
        uint256 pWhitelistEndTime,
        uint256 pPrice,
        uint256 pEndPrice,
        uint256 pDutchTimeFrame,
        uint256 pMaxMintPerTx,
        uint256 pMaxMintPerAccount,
        bool pIsPaused,
        bytes32 pSaleMerkleRoot,
        uint256 pStock) public view returns (Sale memory) {
        require(pStock > 0, "Invalid sale stock");
        require(
            pStartTime > block.timestamp,
            "Start time must be in the future"
        );
        require(
            pStartTime <= pWhitelistEndTime,
            "Whitelist end time must be after or equal than start time"
        );

        require(pSaleMerkleRoot != 0, "Invalid merkle root. Must be non-zero");
        require(pPrice > 0, "Price must be greater than 0");
        return Sale(pStartTime,
                pWhitelistEndTime,
                pPrice,
                pEndPrice,
                pDutchTimeFrame,
                pMaxMintPerTx,
                pMaxMintPerAccount,
                pIsPaused,
                pSaleMerkleRoot,
                pStock,
                0);
    }

    function isActive(Sale memory sale) public view returns(bool) {
        return sale.startTime > 0 &&
               sale.startTime <= block.timestamp &&
               sale.isPaused == false &&
               sale.minted < sale.stock;
    }

    function getSalePrice(Sale memory sale) public view returns(uint256) {
        
        // Make sure that sale started.
        require(block.timestamp >= sale.startTime, "Sale not started");

        // if it's not a dutch sale, return the sale price
        if(sale.dutchTimeFrame == 0 || sale.price == sale.endPrice || sale.endPrice == 0) {
            return sale.price;
        }

        
        // Calculate elapsed time in seconds
        uint256 elapsed = block.timestamp - sale.startTime;

        // If elapsed is lower than the dutch sale time frame, calculate the price
        if(elapsed < sale.dutchTimeFrame) { 

            // Calculate price variation in seconds depending on decreasing or increasing dutch sale
            uint256 priceVariationPerSec = (sale.price > sale.endPrice ? sale.price - sale.endPrice : sale.endPrice - sale.price) / sale.dutchTimeFrame;
            return sale.price > sale.endPrice ? sale.price - priceVariationPerSec * elapsed : sale.price + priceVariationPerSec * elapsed;
        }
        
        // If we got here, dutch sale is over. Return the end price
        return sale.endPrice;
    }

    function updateSale(Sale storage sale, uint256 pStartTime,
        uint256 pWhitelistEndTime,
        uint256 pPrice,
        uint256 pEndPrice,
        uint256 pDutchTimeFrame,
        uint256 pMaxMintPerTx,
        uint256 pMaxMintPerAccount,
        bool pIsPaused,
        bytes32 pSaleMerkleRoot,
        uint256 pStock) public returns (Sale memory) {
        
        // Stock is greater than 0
        require(pStock > 0, "Invalid sale stock");
        // Start time is in the future
        require(
            pStartTime > block.timestamp,
            "Start time must be in the future"
        );

        // Whitelist end time is after start time
        require(
            pWhitelistEndTime >= pStartTime,
            "Whitelist end time must be after start time"
        );
        // Existing sale is not started
        require(sale.startTime == 0 ||
                sale.startTime > block.timestamp,
            "Sale already started");
        // Valid merkle root is passed
        require(pSaleMerkleRoot != 0, "Invalid merkle root. Must be non-zero");
        // Price is greater than 0
        require(pPrice > 0, "Price must be greater than 0");
        sale.price = pPrice;
        sale.endPrice = pEndPrice;
        sale.dutchTimeFrame = pDutchTimeFrame;
        sale.maxMintPerTx = pMaxMintPerTx;
        sale.maxMintPerAccount = pMaxMintPerAccount;
        sale.stock = pStock;
        sale.startTime = pStartTime;
        sale.whitelistEndTime = pWhitelistEndTime;
        sale.merkleRoot = pSaleMerkleRoot;
        sale.isPaused = pIsPaused;

        return sale;
    }
}
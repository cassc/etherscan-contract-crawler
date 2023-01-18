// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./INFT.sol";

interface INFTView is INFT {
    
    function getTokenSaleInfo(uint256 tokenId)
        external
        view
        returns (
            bool isOnSale,
            bool exists,
            SaleInfo memory data,
            address owner
        );

    function getSeriesInfo(uint64 seriesId) 
        external 
        view 
        returns(
            address payable, 
            uint32, 
            //INFT.SaleInfo memory, 
            uint64 onSaleUntil,
            address currency,
            uint256 price,
            //INFT.CommissionData memory, 
            uint64 value,
            address recipient,
            /////
            string memory, 
            string memory
        );
}
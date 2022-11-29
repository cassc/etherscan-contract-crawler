// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface INFT {
    struct SaleInfo {
        uint64 onSaleUntil;
        address currency;
        uint256 price;
    }
    struct CommissionInfo {
        uint64 maxValue;
        uint64 minValue;
        CommissionData ownerCommission;
    }

    struct CommissionData {
        uint64 value;
        address recipient;
    }

    struct SeriesInfo { 
        address payable author;
        uint32 limit;
        SaleInfo saleInfo;
        CommissionData commission;
        string baseURI;
        string suffix;
    }

    function getTokenSaleInfo(uint256 tokenId)
        external
        view
        returns (
            bool isOnSale,
            bool exists,
            SaleInfo memory data,
            address owner
        );

    function mintAndDistribute(uint256[] memory tokenIds, address[] memory addresses) external;

    // mapping (uint256 => SeriesInfo) public seriesInfo;  // seriesId => SeriesInfo
    function seriesInfo(uint256 seriesId) external view returns(address, uint32, INFT.SaleInfo memory, INFT.CommissionData memory, string memory, string memory);
}
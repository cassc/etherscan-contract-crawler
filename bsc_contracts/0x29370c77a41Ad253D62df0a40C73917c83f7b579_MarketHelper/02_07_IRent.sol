// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface IRent {
     struct RentalTokens {
        address mainOwner;
        address rentOwner;
        uint256 tokenId;
        uint256 price;
        uint256 tenancy;
        uint256 startTime;
        string asset_name;
    }
    struct Assets {
        string asset_name;
        uint256 supply;
    }
    
    function assetsCount() external view returns(uint256);
    function getRentAssets(uint256 assetId) external view returns(RentalTokens memory);
    function usersCounter() external view returns(uint256);
    function getHolderAddressByIndex(uint256) external view returns(address);
    function getLesseeTokens(address) external view returns(Assets[] memory);

    event AddRoRent(address indexed owner, uint256 indexed tokenId,uint256 price);

    //Lessor=> the man who add to rent
    //Lessee=> the man who get the rent
    event LeaseAsset(uint256 indexed tokenId,uint256 assetId,address Lessor,  address Lessee,  uint256 price);
    event ClaimAssetRent(uint256 indexed tokenId, address owner );

}
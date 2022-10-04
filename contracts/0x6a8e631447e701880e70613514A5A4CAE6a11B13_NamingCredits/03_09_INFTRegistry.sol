// SPDX-License-Identifier: GNU
pragma solidity >=0.8.0;

interface INFTRegistry {

    // Enums
    enum NamingCurrency {
        Ether,
        RNM,
        NamingCredits
    }
   
    function changeName(address nftAddress, uint256 tokenId, string calldata newName, NamingCurrency namingCurrency) external payable;
    function namingPriceEther() external view returns (uint256);
    function namingPriceRNM() external view returns (uint256);

}
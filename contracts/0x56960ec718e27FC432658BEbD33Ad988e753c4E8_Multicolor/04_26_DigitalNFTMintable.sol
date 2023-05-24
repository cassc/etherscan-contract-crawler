// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../DigitalNFTAdvanced.sol";

/// @notice Developed by DigitalNFT.it (https://digitalnft.it/)
abstract contract DigitalNFTMintable is DigitalNFTAdvanced {
    
    // ============================== Fields ============================== //

    mapping(uint256 => uint256) internal  _prices;


    // ============================= Errors ============================== //

    error priceError();


    // ============================ Functions ============================ //

    // ======================== //
    // === Public Functions === //
    // ======================== //

    function getPrice(uint256 tokenID) public view returns(uint256) {
        return _prices[tokenID];
    }

    // ======================= //
    // === Admin Functions === //
    // ======================= //

    function setPrice(uint256 tokenID, uint256 price) external onlyOwner {
        _prices[tokenID] = price;
    }

    function setPriceBatch(uint256[] calldata tokenIDs, uint256[] calldata prices) public onlyOwner {
        DigitalNFTUtilities._lengthCheck(tokenIDs, prices);
        for (uint256 i = 0; i < tokenIDs.length; i++) _prices[tokenIDs[i]] = prices[i];
    }
}
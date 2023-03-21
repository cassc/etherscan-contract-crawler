pragma solidity ^0.8.0;
interface INFTMintSaleMultiple {

    function buyNFT(address recipient, uint256 tier) external;
    function buyMultipleNFT(address recipient, uint256[] calldata tiersToBuy) external;
}
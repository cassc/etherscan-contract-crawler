// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
interface IMintVaultQuote {
    function initialize() external;
    function setPair(address _pair) external;
    function setUsdPrice(uint256 _usdPrice) external;
    function addDiscountToken(address _discountToken, uint256 amount, uint256 discount) external;
    function updateDiscountToken(uint256 index, address _discountToken, uint256 amount, uint256 discount) external;
    function removeDiscountToken(uint256 index) external;
    function addMintPass(address _mintPass, uint256 tokenId, uint256 price) external;
    function updateMintPass(uint256 index, address _mintPass, uint256 tokenId, uint256 price) external;
    function removeMintPass(uint256 index) external;
    function getUsdPriceInEth(uint256 _usdPrice) external view returns (uint256);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);
    function quoteExternalPrice(address buyer, uint256 _usdPrice) external view returns (uint256);
    function quoteStoredPrice(address buyer) external view returns (uint256);
}
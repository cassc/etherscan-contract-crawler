// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./OwnableUpgradeable.sol";
import "./IUniswapV2Pair.sol";


contract MintVaultQuote is Initializable, OwnableUpgradeable {
    IUniswapV2Pair public pair;
    uint256 public usdPrice;
    
    struct DiscountToken {
        address token;
        uint256 amount;
        uint256 discount;
    }

    struct MintPass {
        address token;
        uint256 tokenId;
        uint256 price;
    }

    DiscountToken[] public discountTokens;
    MintPass[] public mintPasses;

    function initialize() public initializer {
        __Ownable_init();
        pair = IUniswapV2Pair(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc);
    }

    function setPair(address _pair) external onlyOwner {
        pair = IUniswapV2Pair(_pair);
    }

    function setUsdPrice(uint256 _usdPrice) external onlyOwner {
        usdPrice = _usdPrice;
    }

    function addDiscountToken(address _discountToken, uint256 amount, uint256 discount) external onlyOwner {
        discountTokens.push(DiscountToken(_discountToken, amount, discount));
    }

    function updateDiscountToken(uint256 index, address _discountToken, uint256 amount, uint256 discount) external onlyOwner {
        require(index < discountTokens.length, "Index out of bounds");
        discountTokens[index] = DiscountToken(_discountToken, amount, discount);
    }

    function removeDiscountToken(uint256 index) external onlyOwner {
        require(index < discountTokens.length, "Index out of bounds");
        discountTokens[index] = discountTokens[discountTokens.length - 1];
        discountTokens.pop();
    }

    function addMintPass(address _mintPass, uint256 tokenId, uint256 price) external onlyOwner {
        mintPasses.push(MintPass(_mintPass, tokenId, price));
    }

    function updateMintPass(uint256 index, address _mintPass, uint256 tokenId, uint256 price) external onlyOwner {
        require(index < mintPasses.length, "Index out of bounds");
        mintPasses[index] = MintPass(_mintPass, tokenId, price);
    }

    function removeMintPass(uint256 index) external onlyOwner {
        require(index < mintPasses.length, "Index out of bounds");
        mintPasses[index] = mintPasses[mintPasses.length - 1];
        mintPasses.pop();
    }

    function getUsdPriceInEth(uint256 _usdPrice) public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        uint256 usdcInPair = pair.token0() == address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) ? reserve0 : reserve1; // USDC token address
        uint256 ethInPair = pair.token0() == address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) ? reserve0 : reserve1; // WETH token address
        uint256 usdPriceInEth = (_usdPrice * ethInPair) / usdcInPair;
        return usdPriceInEth;
    }

    function getReserves() public view returns (uint112 reserve0, uint112 reserve1) {
        (reserve0, reserve1,) = pair.getReserves();        
    }

    function quoteExternalPrice(address buyer, uint256 _usdPrice) external view returns (uint256) {
        uint256 price = getUsdPriceInEth(_usdPrice);
        return getQuoteFromPrice(buyer, price);
    }

    function quoteStoredPrice(address buyer) external view returns (uint256) {
        uint256 price = getUsdPriceInEth(usdPrice);
        return getQuoteFromPrice(buyer, price);
    }

    function getQuoteFromPrice(address buyer, uint256 price) internal view returns (uint256) {
        // Check for mint passes         
        for (uint i = 0; i < mintPasses.length; i++) {
            if (IERC1155(mintPasses[i].token).balanceOf(buyer, mintPasses[i].tokenId) > 0) {
                return getUsdPriceInEth(mintPasses[i].price);
            }
        }

        // Check for discount tokens
        uint256 highestDiscount = 0;
        for (uint i = 0; i < discountTokens.length; i++) {
            if (IERC20(discountTokens[i].token).balanceOf(buyer) >= discountTokens[i].amount && discountTokens[i].discount > highestDiscount) {
                highestDiscount = discountTokens[i].discount;
            }
        }

        price -= price * highestDiscount / 100;

        return price;
    }
}
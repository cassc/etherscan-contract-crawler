pragma solidity ^0.8.0;
import "../interfaces/IWETH.sol";
import "../interfaces/INFTMintSale.sol";
import "../interfaces/INFTMintSaleMultiple.sol";

contract NativeTokenHelper {
    IWETH private immutable WETH;
    constructor (IWETH weth) {
        WETH = weth;
    }

    function approveSale(address sale) external {
        WETH.approve(sale, type(uint256).max);
    }

    function buyNFT(INFTMintSale sale, address recipient) external payable {
        WETH.deposit{value: msg.value}();
        sale.buyNFT(recipient);
    }

    function buyNFT(INFTMintSaleMultiple sale, address recipient, uint256 tier) external payable {
        WETH.deposit{value: msg.value}();
        sale.buyNFT(recipient, tier);
    }
    function buyMultipleNFT(INFTMintSaleMultiple sale, address recipient, uint256[] calldata tiersToBuy) external payable {
        WETH.deposit{value: msg.value}();
        sale.buyMultipleNFT(recipient, tiersToBuy);
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./CryptoFoxesShopWithdraw.sol";
import "./CryptoFoxesShopProducts.sol";

contract CryptoFoxesShop is Ownable, CryptoFoxesShopProducts, CryptoFoxesShopWithdraw, ReentrancyGuard{

    mapping(string => uint256) public purchasedProduct;
    mapping(string => mapping(address => uint256)) public purchasedProductWallet;

    uint256 public purchaseId;

    event Purchase(address indexed _owner, string indexed _slug, uint256 _quantity, uint256 _id);

    constructor(address _cryptoFoxesSteak) CryptoFoxesShopWithdraw(_cryptoFoxesSteak) {}

    //////////////////////////////////////////////////
    //      TESTER                                  //
    //////////////////////////////////////////////////

    function checkPurchase(string memory _slug, uint256 _quantity, address _wallet) private{

        require(products[_slug].enable && _quantity > 0,"Product not available");

        if(products[_slug].start > 0 && products[_slug].end > 0){
            require(products[_slug].start <= block.timestamp && block.timestamp <= products[_slug].end, "Product not available");
        }

        if (products[_slug].quantityMax > 0) {
            require(purchasedProduct[_slug] + _quantity <= products[_slug].quantityMax, "Product sold out");
            purchasedProduct[_slug] += _quantity;
        }

        if(products[_slug].maxPerWallet > 0){
            require(purchasedProductWallet[_slug][_wallet] + _quantity <= products[_slug].maxPerWallet, "Max per wallet limit");
            purchasedProductWallet[_slug][_wallet] += _quantity;
        }
    }

    function _compareStrings(string memory a, string memory b) private pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    //////////////////////////////////////////////////
    //      PURCHASE                               //
    //////////////////////////////////////////////////

    function purchase(string memory _slug, uint256 _quantity) public nonReentrant {
        _purchase(_msgSender(), _slug, _quantity);
    }

    function purchaseCart(string[] memory _slugs, uint256[] memory _quantities) public nonReentrant {
        _purchaseCart(_msgSender(), _slugs, _quantities);
    }

    function _purchase(address _wallet, string memory _slug, uint256 _quantity) private {

        checkPurchase(_slug, _quantity, _wallet);

        uint256 price = products[_slug].price * _quantity;

        if(price > 0){
            cryptoFoxesSteak.transferFrom(_wallet, address(this), price);
        }

        purchaseId += 1;
        emit Purchase(_msgSender(), _slug, _quantity, purchaseId);
    }

    function _purchaseCart(address _wallet, string[] memory _slugs, uint256[] memory _quantities) private  {
        require(_slugs.length == _quantities.length, "Bad data length");

        uint256 price = 0;
        for (uint256 i = 0; i < _slugs.length; i++) {
            for (uint256 j = 0; j < i; j++) {
                if(_compareStrings(_slugs[j], _slugs[i]) == true) {
                    revert("Duplicate slug");
                }
            }
            checkPurchase(_slugs[i], _quantities[i], _wallet);
            price += products[_slugs[i]].price * _quantities[i];
        }

        if(price > 0){
            cryptoFoxesSteak.transferFrom(_wallet, address(this), price);
        }

        for (uint256 i = 0; i < _slugs.length; i++) {
            purchaseId += 1;
            emit Purchase(_wallet, _slugs[i], _quantities[i], purchaseId);
        }
    }

    //////////////////////////////////////////////////
    //      PURCHASE BY CONTRACT                   //
    //////////////////////////////////////////////////

    function purchaseByContract(address _wallet, string memory _slug, uint256 _quantity) public isFoxContract {
        _purchase(_wallet, _slug, _quantity);
    }

    function purchaseCartByContract(address _wallet, string[] memory _slugs, uint256[] memory _quantities) public isFoxContract {
        _purchaseCart(_wallet, _slugs, _quantities);
    }

    //////////////////////////////////////////////////
    //      PRODUCT GETTER                          //
    //////////////////////////////////////////////////

    function getProductPrice(string memory _slug, uint256 _quantity) public view returns(uint256){
        return products[_slug].price * _quantity;
    }
    function getProductStock(string memory _slug) public view returns(uint256){
        return products[_slug].quantityMax - getTotalProductPurchased(_slug);
    }
    function getTotalProductPurchased(string memory _slug) public view returns(uint256){
        return purchasedProduct[_slug];
    }
    function getTotalProductPurchasedWallet(string memory _slug, address _wallet) public view returns(uint256){
        return purchasedProductWallet[_slug][_wallet];
    }
}
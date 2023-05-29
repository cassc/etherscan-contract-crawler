// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICryptoFoxesShopProducts.sol";
import "./CryptoFoxesAllowed.sol";

contract CryptoFoxesShopProducts is ICryptoFoxesShopProducts, CryptoFoxesAllowed{

    mapping(string => Product) public products;
    string[] public productSlugs;

    //////////////////////////////////////////////////
    //      PRODUCT SETTER                          //
    //////////////////////////////////////////////////

    function addProduct(string memory _slug, Product memory _product) public isFoxContractOrOwner{
        require(!products[_slug].isValid, "Product slug already exist");
        require(_product.isValid, "Missing isValid param");
        products[_slug] = _product;
        productSlugs.push(_slug);
    }

    function editProduct(string memory _slug, Product memory _product) public isFoxContractOrOwner{
        require(products[_slug].isValid, "Product slug does not exist");
        require(_product.isValid, "Missing isValid param");

        if(products[_slug].maxPerWallet == 0){
            require(_product.maxPerWallet == 0, "maxPerWallet == 0, need to change slug");
        }

        products[_slug] = _product;
    }

    function statusProduct(string memory _slug, bool _enable) public isFoxContractOrOwner {
        require(products[_slug].isValid, "Product slug does not exist");
        products[_slug].enable = _enable;
    }

    //////////////////////////////////////////////////
    //      PRODUCT GETTER                          //
    //////////////////////////////////////////////////

    function getProduct(string memory _slug) public override view returns(Product memory) {
        return products[_slug];
    }
    function getProducts() public override view returns(Product[] memory) {
        Product[] memory prods = new Product[](productSlugs.length);
        for(uint256 i = 0; i < productSlugs.length; i ++){
            prods[i] = products[productSlugs[i]];
        }
        return prods;
    }
    function getSlugs() public view returns(string[] memory) {
        return productSlugs;
    }

}
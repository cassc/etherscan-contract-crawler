// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./Product.sol";
import "./ProductFactory.sol";
import "./IFactoryERC721.sol";
import "./ERC721Data.sol";

/**
 * @title ProductLootBox
 *
 * ProductLootBox - a tradeable loot box of Products.
 */
contract ProductLootBox is ERC721Tradable{
    uint256 NUM_PRODUCTS_PER_BOX = 1;
    uint256 OPTION_ID = 0;
    address factoryAddress;
    ProductFactory productFactory;

    constructor(address _factoryAddress)
        ERC721Tradable("GSMC Lootbox", "GSMCLB")
    {
        factoryAddress = _factoryAddress;
        productFactory = ProductFactory(factoryAddress);
        _setupRole(DEFAULT_ADMIN_ROLE,_factoryAddress);
    }

    function unpack(uint256 _tokenId) public {

        require(ownerOf(_tokenId) == _msgSender() || productFactory.isAdmin(_msgSender()),"Unauthorized unpack" );

        // Insert custom logic for configuring the item here.
        for (uint256 i = 0; i < NUM_PRODUCTS_PER_BOX; i++) {
            // Mint the ERC721 item(s).
            FactoryERC721 factory = FactoryERC721(factoryAddress);
            factory.mint(OPTION_ID, ownerOf(_tokenId));
        }
        // Burn the presale item.
        _burn(_tokenId);
    }

    function batchUnpack(uint256[] memory _tokenIds) public {
        for (uint i=0; i<_tokenIds.length; i++) {
            unpack(_tokenIds[i]);
        }
    }

    function allTokens() public view returns (uint256[] memory){
        return _allTokens;
    }

    function baseTokenURI() override public pure returns (string memory) {
        return "ipfs://bafybeiflynpx422wfhh4nxnwyymcudaseo75pirxdopeoonsmebmhlesdq/";
    }

    function productsPerLootbox() public view returns (uint256) {
        return NUM_PRODUCTS_PER_BOX;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        require(productFactory.lootboxMintedOf(to) < productFactory.maxMintQuantity(),"Receiver has reached maximum quantity allowed");
        _transfer(from, to, tokenId);
    }


}
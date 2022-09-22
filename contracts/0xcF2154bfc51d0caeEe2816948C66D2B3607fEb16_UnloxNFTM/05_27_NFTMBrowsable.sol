// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTM.sol";

abstract contract NFTMBrowsable is NFTM {

    function getAllSaleItemOfCollection(address tokenAddr)
        public
        view
        returns (string memory)
    {
        string memory returnText = "";

        uint256[] memory ids = _nftIDs[tokenAddr];
        SaleItem[] memory tmpItems = new SaleItem[](ids.length);

        for(uint i = 0 ; i < ids.length ; i++)
        {
            tmpItems[i]= _nftSaleItems[tokenAddr][ids[i]];
        }

        returnText = _saleItemArrayToJSON(tmpItems);

        return returnText;
    }

    function getAllNFTCollections() public view returns (string memory) {

        string memory returnText = '["0x';

        for (uint i = 0 ; i < _nftCollections.length ; i++)
        {
            address nftAddr = _nftCollections[i];
            returnText = string.concat(returnText,_toAsciiString(nftAddr));

            if(i != _nftCollections.length -1)
            {
                returnText = string.concat(returnText,'","0x');
            }
            else
            {
                returnText = string.concat(returnText,'"]');
            }

        }

        return returnText;
    }

    function getSaleItemBySeller(address sellerAddr)
        public
        view
        returns (string memory)
    {
        string memory returnText = "";

        SaleItem[] memory saleItems = _sellerSaleItems[sellerAddr];
        returnText = _saleItemArrayToJSON(saleItems);

        return returnText;
    }

    function getSaleItemDetails(address tokenAddr, uint256 tokenId)
        public
        view
        returns (string memory)
    {
        SaleItem memory saleItem = _nftSaleItems[tokenAddr][tokenId];

        string memory returnText = _saleItemToJSON(saleItem);

        return returnText;
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Constants.sol";


contract WineStorage is Constants{
    // tokenId => (key => value)
    mapping(uint256 => string) internal data;


    function setStorage(uint256 key, string memory value) internal
    {
        data[key] = value;
    }


    function getStorage(uint256 key) public view returns(string memory)
    {
        return data[key];
    }
    
    function getWineName() public view returns(string memory)
    {
        return data[WINE_NAME];
    }

    function getWineProductionCountry() public view returns(string memory)
    {
        return data[WINE_PRODUCTION_COUNTRY];
    }

    function getWineProductionRegion() public view returns(string memory)
    {
        return data[WINE_PRODUCTION_REGION];
    }

    function getWineProductionYear() public view returns(string memory)
    {
        return data[WINE_PRODUCTION_YEAR];
    }

    function getWineProducerName() public view returns(string memory)
    {
        return data[WINE_PRODUCTION_NAME];
    }

    function getWineBottleVolume() public view returns(string memory)
    {
        return data[WINE_PRODUCTION_VOLUME];
    }

    function getLinkToDocuments() public view returns(string memory)
    {
        return data[LINK_TO_DOCUMENTS];
    }


}
pragma solidity 0.8.15;

import "Ownable.sol";
import "AssetConverter.sol";


contract AssetConverterBatchUpdater is Ownable
{
	AssetConverter public assetConverter;

    constructor(AssetConverter _assetConverter) {
        assetConverter = _assetConverter;
    }

    function updateConverters(address[3][] memory updates) public onlyOwner {
        for (uint i = 0; i < updates.length; i++) {
            assetConverter.updateConverter(updates[i][0], updates[i][1], updates[i][2]);
        }
    }
}
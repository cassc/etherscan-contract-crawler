// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
import "LibEnvelopTypes.sol";
import "KTypes.sol";

interface IEnvelopNFTKiosk  {

    function DEFAULT_DISPLAY() external view returns (bytes32);
    
    function buyAssetItem(
        ETypes.AssetItem calldata _assetItem,
        uint256 _priceIndex,
        address _buyer,
        address _referrer,
        string calldata _promo
    ) external payable;
    
    function getDisplayOwner(
        bytes32 _displayNameHash
    ) external view returns (address);
    
    function getAssetItemPlace(
        ETypes.AssetItem memory _assetItem
    ) external view returns (KTypes.Place memory);
}
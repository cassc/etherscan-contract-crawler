// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

//import "IERC721Enumerable.sol";
import "LibEnvelopTypes.sol";
import "KTypes.sol";

interface IDisplayPriceModel  {
    
    event DiscountChanged(
        bytes32 indexed display,
        uint8 indexed DiscountType,
        bytes32 DiscountParam,
        uint16 DiscountPercent
    );

    event DefaultPriceChanged(
        bytes32 indexed display,
        address indexed payWithContract,
        uint256 indexed priceAmount
    );

    function getItemPrices(
        ETypes.AssetItem memory _assetItem
    ) external view returns (KTypes.Price[] memory);

    function getDefaultDisplayPrices(
        ETypes.AssetItem memory _assetItem
    ) external view returns (KTypes.Price[] memory);
    
    function getItemDiscounts(
        ETypes.AssetItem memory _assetItem,
        address _buyer,
        address _referrer,
        bytes32 _promoHash
    ) external view returns (KTypes.Discount[] memory);

    function getBatchPrices(
        ETypes.AssetItem[] memory _assetItemArray
    ) external view returns (KTypes.Price[] memory);
    
    function getBatchDiscounts(
        ETypes.AssetItem[] memory _assetItemArray,
        address _buyer,
        address _referrer,
        bytes32 _promoHash
    ) external view returns (KTypes.Discount[] memory);
}
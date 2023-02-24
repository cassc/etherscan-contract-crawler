// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) NFT(wNFT) Kiosk Default Price Model;

pragma solidity 0.8.16;

import "IDisplayPriceModel.sol";
import "IEnvelopNFTKiosk.sol";
import "IWNFT.sol";

/// @title Default price model implementation
/// @author Envelop Team
/// @notice This model operate sellings of erc20 collateral inside wNFTS V1
/// @dev ..
contract DefaultPriceModel is IDisplayPriceModel {

    struct DiscountUntil {
        uint256 untilDate;
        KTypes.Discount discount;
    }

    // mapping from displayNameHash to ERC20 collateral prices
    mapping (bytes32 => mapping(address => KTypes.DenominatedPrice[])) public erc20CollateralPricesForDisplays;

    // mapping from displayNameHash to default price for all NFT at the display
    mapping (bytes32 => KTypes.Price[]) public defaultNFTPriceForDisplay;
    
    // mapping from displayNameHash to time discounts
    mapping (bytes32 => DiscountUntil[]) public timeDiscounts;

    // mapping from displayNameHash to PROMO hash to PROMO discount
    mapping (bytes32 => mapping (bytes32 => DiscountUntil)) public promoDiscounts;

    // mapping from displayNameHash to referrer hash to PROMO discount
    mapping (bytes32 => mapping (bytes32 => DiscountUntil)) public referrerDiscounts;


    IEnvelopNFTKiosk public kiosk;

    event CollateralPriceChanged(
        bytes32 indexed display,
        address indexed erc20Collateral
    );

    constructor (address _kiosk){
        kiosk = IEnvelopNFTKiosk(_kiosk);
    }

    /**
     * @dev Throws if called by any account other than the display owner.
     */
    modifier onlyDisplayOwner(bytes32 _displayNameHash) {
        require(
            kiosk.getDisplayOwner(_displayNameHash) == msg.sender, 
            "Only for Display Owner"
        );
        _;
    }

    function setCollateralPriceForDisplay(
        bytes32 _displayNameHash,
        address _erc20,
        KTypes.DenominatedPrice[] calldata _prices
    ) 
        external virtual
        onlyDisplayOwner(_displayNameHash) 

    {
        KTypes.DenominatedPrice[] storage prices = erc20CollateralPricesForDisplays[_displayNameHash][_erc20];
        for (uint256 i = 0; i < _prices.length; ++ i) {
            prices.push(_prices[i]);
            emit CollateralPriceChanged(_displayNameHash, _erc20);    
        }
    }

    function editCollateralPriceRecordForDisplay(
        bytes32 _displayNameHash,
        address _erc20,
        uint256 _priceIndex,
        KTypes.DenominatedPrice calldata _price
    )
        external virtual
        onlyDisplayOwner(_displayNameHash)
    {
        erc20CollateralPricesForDisplays[_displayNameHash][_erc20][_priceIndex] = _price;
        emit CollateralPriceChanged(_displayNameHash, _erc20);
    }

    function setDefaultNFTPriceForDisplay(
        bytes32 _displayNameHash,
        KTypes.Price[] calldata _prices
    ) 
       external virtual
       onlyDisplayOwner(_displayNameHash)
    {
        KTypes.Price[] storage prices = defaultNFTPriceForDisplay[_displayNameHash];
        for (uint256 i = 0; i < _prices.length; ++ i) {
            prices.push(_prices[i]);
            emit DefaultPriceChanged(
                _displayNameHash,
                _prices[i].payWith,
                _prices[i].amount
            );    
        }
    }

    function editDefaultNFTPriceRecordForDisplay(
        bytes32 _displayNameHash,
        uint256 _priceIndex,
        KTypes.Price calldata _price
    )
        external virtual
        onlyDisplayOwner(_displayNameHash)
    {
        defaultNFTPriceForDisplay[_displayNameHash][_priceIndex] = _price;
        emit DefaultPriceChanged(
            _displayNameHash,
            _price.payWith,
            _price.amount
        );
    }

    function setTimeDiscountsForDisplay(
        bytes32 _displayNameHash,
        DiscountUntil[] calldata _discounts
    ) 
       external virtual
       onlyDisplayOwner(_displayNameHash)
    {
        DiscountUntil[] storage discounts = timeDiscounts[_displayNameHash];
        for (uint256 i = 0; i < _discounts.length; ++ i) {
            discounts.push(_discounts[i]);
            emit DiscountChanged(
            _displayNameHash,
            uint8(KTypes.DiscountType.TIME),
            bytes32(_discounts[i].untilDate),
            _discounts[i].discount.dsctPercent
        );    
        }
    }

    function editTimeDiscountsForDisplay(
        bytes32 _displayNameHash,
        uint256 _discountIndex,
        DiscountUntil calldata _discount
    )
        external virtual
        onlyDisplayOwner(_displayNameHash)
    {
        timeDiscounts[_displayNameHash][_discountIndex] = _discount;
        emit DiscountChanged(
            _displayNameHash,
            uint8(KTypes.DiscountType.TIME),
            bytes32(_discount.untilDate),
            _discount.discount.dsctPercent
        );
    }

    function setPromoDiscountForDisplay(
        bytes32 _displayNameHash,
        bytes32 _promoHash,
        DiscountUntil calldata _discount
    ) 
        external virtual
        onlyDisplayOwner(_displayNameHash) 

    {
        promoDiscounts[_displayNameHash][_promoHash] = _discount;
        emit DiscountChanged(
            _displayNameHash,
            uint8(KTypes.DiscountType.PROMO),
            _promoHash,
            _discount.discount.dsctPercent
        );
    }

    function setRefereerDiscountForDisplay(
        bytes32 _displayNameHash,
        address _referrer,
        DiscountUntil calldata _discount
    ) 
        external virtual
        onlyDisplayOwner(_displayNameHash) 

    {
        referrerDiscounts[_displayNameHash][keccak256(abi.encode(_referrer))] = _discount; 
        emit DiscountChanged(
            _displayNameHash,
            uint8(KTypes.DiscountType.REFERRAL),
            keccak256(abi.encode(_referrer)),
            _discount.discount.dsctPercent
        );
    }
    /////////////////////////

    function getItemPrices(
        ETypes.AssetItem memory _assetItem
    ) external view virtual returns (KTypes.Price[] memory)
    {
        // 1. Try get collateral
        IWNFT wnftContract = IWNFT(_assetItem.asset.contractAddress);
        try wnftContract.wnftInfo(_assetItem.tokenId) returns (ETypes.WNFT memory wnft){
            KTypes.Place memory pl = _getVirtualPlace(_assetItem);
            // Only first collateral asset is tradable in this pricemodel
            KTypes.DenominatedPrice[] memory denPrices = _getCollateralUnitPrice(
                pl.display,
                wnft.collateral[0].asset.contractAddress
            );
            KTypes.Price[] memory prices = new KTypes.Price[](denPrices.length);
            for (uint256 i = 0; i < denPrices.length; ++ i ){
                // Calc wNFT price
                prices[i].payWith = denPrices[i].payWith;
                prices[i].amount = denPrices[i].amount 
                    * wnft.collateral[0].amount / denPrices[i].denominator;
            }
            return prices; 
        } catch {
            return getDefaultDisplayPrices(_assetItem);
        }
    }

    function getDefaultDisplayPrices(
        ETypes.AssetItem memory _assetItem
    ) public view virtual returns (KTypes.Price[] memory _prices)
    {
        // get display of given item
        KTypes.Place memory pl = _getVirtualPlace(_assetItem);
        _prices = defaultNFTPriceForDisplay[pl.display];
    }

    function getDisplayTimeDiscounts(
        bytes32 _displayNameHash
    ) public view virtual returns (DiscountUntil[] memory)

    {
        return timeDiscounts[_displayNameHash];
    } 

    function getItemDiscounts(
        ETypes.AssetItem memory _assetItem,
        address _buyer,
        address _referrer,
        bytes32 _promoHash
    ) public view virtual returns (KTypes.Discount[] memory)
    {
        KTypes.Place memory pl = _getVirtualPlace(_assetItem);
        // 1.First check time discounts for this display
        DiscountUntil[] storage tdArray = timeDiscounts[pl.display];
        KTypes.Discount memory td;
        for (uint256 i = 0; i < tdArray.length; ++ i){
            if (tdArray[i].untilDate > block.timestamp){
                td = tdArray[i].discount;
                break;
            }
        }

        // This Price Model support 3 slots for discounts
        KTypes.Discount[] memory discounts = new KTypes.Discount[](3);
        for (uint256 i = 0; i < discounts.length; ++ i){
            // add time discount to result
            discounts[0] = td;
            // add promo discount to result
            if (promoDiscounts[pl.display][_promoHash].untilDate > block.timestamp) {
                discounts[1] = KTypes.Discount(
                    promoDiscounts[pl.display][_promoHash].discount.dsctType,
                    promoDiscounts[pl.display][_promoHash].discount.dsctPercent
                );
            }

            // add ref discount
            if (referrerDiscounts[pl.display][keccak256(abi.encode(_referrer))].untilDate > block.timestamp) {
                discounts[2] = KTypes.Discount(
                    referrerDiscounts[pl.display][keccak256(abi.encode(_referrer))].discount.dsctType,
                    referrerDiscounts[pl.display][keccak256(abi.encode(_referrer))].discount.dsctPercent
                );
            }

        }
        return discounts;
    }

    function getBatchPrices(
        ETypes.AssetItem[] memory _assetItemArray
    ) external view virtual returns (KTypes.Price[] memory)
    {

    }
    
    function getBatchDiscounts(
        ETypes.AssetItem[] memory _assetItemArray,
        address _buyer,
        address _referrer,
        bytes32 _promoHash
    ) external view virtual returns (KTypes.Discount[] memory)
    {

    }

    function getCollateralUnitPrice(
        bytes32 _displayNameHash, 
        address _erc20
    ) external view returns(KTypes.DenominatedPrice[] memory){
        return _getCollateralUnitPrice(_displayNameHash,_erc20);
    }
    ///////////////////////////////////////////////////////////////////
    function _getCollateralUnitPrice(
        bytes32 _displayNameHash, 
        address _erc20
    ) internal view returns(KTypes.DenominatedPrice[] memory){
        return erc20CollateralPricesForDisplays[_displayNameHash][_erc20];
    }

    function _getVirtualPlace(ETypes.AssetItem memory _assetItem) 
        internal view returns(KTypes.Place memory place) 
    {
        place = kiosk.getAssetItemPlace(_assetItem);
        if (place.display == bytes32(0)) {
               place.display = kiosk.DEFAULT_DISPLAY();
        }
    }
}
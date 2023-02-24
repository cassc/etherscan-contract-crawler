// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) NFT(wNFT) Kiosk.

pragma solidity 0.8.16;

import "TokenServiceExtended.sol";

import "ERC721Holder.sol";
import "ERC1155Holder.sol";
import "ReentrancyGuard.sol";

import "DefaultPriceModel.sol";



contract EnvelopNFTKiosk is TokenServiceExtended, DefaultPriceModel, ReentrancyGuard {

    uint256 constant public DEFAULT_INDEX = 0;
    uint256 constant public PERCENT_DENOMINATOR = 10000;
    bytes32 immutable public DEFAULT_DISPLAY = hlpHashString('NFTKiosk');

    mapping(bytes32 => KTypes.Display) public displays;

    // mapping from contract address & tokenId to Place(displayHash and index)
    mapping(address => mapping(uint256 => KTypes.Place)) public assetAtDisplay;

    event DisplayChanged(
        bytes32 indexed display,
        address indexed owner,
        address indexed beneficiary, // who will receive assets from sale
        uint256 enableAfter,
        uint256 disableAfter,
        address priceModel,
        string name
    );

    event DisplayTransfer(
        bytes32 indexed display,
        address indexed from,
        address indexed newOwner
    );

    event ItemAddedToDisplay(
        bytes32 indexed display,
        address indexed assetContract,
        uint256 indexed assetTokenId,
        uint256 placeIndex
    );

    event ItemPriceChanged(
        bytes32 indexed display,
        address indexed assetContract,
        uint256 indexed assetTokenId
    );

    event EnvelopPurchase(
        bytes32 indexed display,
        address indexed assetContract,
        uint256 indexed assetTokenId
    );

    event EnvelopReferrer(
        address indexed referrer,
        address indexed customer,
        address indexed payWithToken,
        uint256 payWithAmount,
        uint16 percentDiscount
    );

    constructor (address _beneficiary)
       DefaultPriceModel(address(this))
    {
        KTypes.Display storage d = displays[DEFAULT_DISPLAY];
        d.owner = msg.sender;
        d.beneficiary  = _beneficiary;
        d.enableAfter  = 0;
        d.disableAfter = type(uint256).max;
        d.priceModel   = address(this);
        emit DisplayChanged(
            DEFAULT_DISPLAY,
            msg.sender,
            _beneficiary, // who will receive assets from sale
            0,
            d.disableAfter,
            address(this),
            'NFTKiosk'
        );
    }

    
    function setDisplayParams(
        string calldata _name,
        address _beneficiary, // who will receive assets from sale
        uint256 _enableAfter,
        uint256 _disableAfter,
        address _priceModel
    ) external 
    {
        bytes32 _displayNameHash = hlpHashString(_name);
        require(
            (displays[_displayNameHash].owner == msg.sender    // edit existing
            ||displays[_displayNameHash].owner == address(0)), // create new
            "Only for Display Owner"
        );
        _setDisplayParams(
                _displayNameHash,
                msg.sender, 
                _beneficiary, // who will receive assets from sale
                _enableAfter,
                _disableAfter,
                _priceModel
        );
        
        emit DisplayChanged(
            _displayNameHash,
            msg.sender,
            _beneficiary, // who will receive assets from sale
            _enableAfter,
            _disableAfter,
            _priceModel,
            _name
        );
    }

    function transferDisplay(address _to, bytes32 _displayNameHash) 
        external 
    {
        require(displays[_displayNameHash].owner == msg.sender, "Only for Display Owner");
        displays[_displayNameHash].owner = _to;
        emit DisplayTransfer(_displayNameHash, msg.sender, _to);
    }

    // TODO  Check that display exists
    function addItemToDisplay(
        bytes32 _displayNameHash,
        ETypes.AssetItem memory _assetItem,
        KTypes.Price[] calldata _prices
    ) 
        public 
        returns  (KTypes.Place memory place) 
    {
        // We need two checks. 
        // 1. Only item with zero place (display and index) can be added 
        // to exact display
        
        KTypes.Place memory p = 
            assetAtDisplay[_assetItem.asset.contractAddress][_assetItem.tokenId];
        require(
            p.display == bytes32(0) && p.index == 0, 
            "Already at display"
        );
        
        // 2. Item has been transfered to this contract
        // Next check is For 721 only. Because 1155 standard 
        // has no `ownerOf` method. Hence we can't use simple (implicit)
        // erc1155 transfer for put item at display. 
        
        // In this implementation you cant`t 'edit'  display after
        // simple (implicit) adding item to display 
        // if (_ownerOf(_assetItem) != address(this)) {
        
        // Do transfer to this contract
        require(_assetItem.amount
            <=_transferSafe(_assetItem, msg.sender, address(this)),
            "Insufficient balance after NFT transfer"    
        );
        // }

        // DEFAULT_DISPLAY accept items from any  addresses
        if (msg.sender != displays[_displayNameHash].owner) {
            require(
                _displayNameHash == DEFAULT_DISPLAY, 
                "Only Default Display allow for any"
            );
        }

        place = _addItemRecordAtDisplay(
            _displayNameHash, 
            msg.sender,  // Item Owner
            _assetItem,
            _prices
        );

        emit ItemAddedToDisplay(
            place.display,
            _assetItem.asset.contractAddress,
            _assetItem.tokenId,
            place.index
        );
    }

    function addBatchItemsToDisplayWithSamePrice(
        bytes32 _displayNameHash,
        ETypes.AssetItem[] memory _assetItems,
        KTypes.Price[] calldata _prices
    ) 
        external 
        returns  (KTypes.Place[] memory) 
    {
        
        // Lets calc and create array var for result
        KTypes.Place[] memory pls = new KTypes.Place[](_assetItems.length);
        for (uint256 i = 0; i < _assetItems.length; ++i){
            pls[i] = addItemToDisplay(_displayNameHash,_assetItems[i],_prices);
        }
        return pls;
    }

    function addAssetItemPriceAtIndex(
        ETypes.AssetItem calldata _assetItem,
        KTypes.Price[] calldata _prices
    ) 
        external 
    {
        KTypes.Place memory p = getAssetItemPlace(_assetItem);
        // check that sender is item owner or display owner(if item owner not set)
        if (displays[p.display].items[p.index].owner != msg.sender) 
        {
            require(
                displays[p.display].owner == msg.sender, 
                "Only display owner can edit price"
            );
        }
        _addItemPriceAtIndex(p.display, p.index, _prices);
        emit ItemPriceChanged(
            p.display,
            _assetItem.asset.contractAddress,
            _assetItem.tokenId
        ); 
    }

    function editAssetItemPriceAtIndex(
        ETypes.AssetItem calldata _assetItem,
        uint256 _priceIndex,
        KTypes.Price calldata _price
    ) 
        external 
    {

        KTypes.Place memory p = getAssetItemPlace(_assetItem);
        // check that sender is item owner or display owner(if item owner not set)
        if (displays[p.display].items[p.index].owner != msg.sender) 
        {
            require(displays[p.display].owner == msg.sender, "Only for display owner");
        }
        _editItemPriceAtIndex(p.display, p.index, _priceIndex ,_price);
        emit ItemPriceChanged(
            p.display,
            _assetItem.asset.contractAddress,
            _assetItem.tokenId
        );

    }

    function removeLastPersonalPriceForAssetItem(
        ETypes.AssetItem calldata _assetItem
    ) 
        external 
    {
        KTypes.Place memory p = getAssetItemPlace(_assetItem);
        // check that sender is item owner or display owner(if item owner not set)
        if (displays[p.display].items[p.index].owner != msg.sender) 
        {
            require(displays[p.display].owner == msg.sender, "Only for display owner");
        }
        
        KTypes.Price[] storage priceArray = displays[p.display].items[p.index].prices;
        priceArray.pop();
        emit ItemPriceChanged(
            p.display,
            _assetItem.asset.contractAddress,
            _assetItem.tokenId
        );
    }

    function buyAssetItem(
        ETypes.AssetItem calldata _assetItem,
        uint256 _priceIndex,
        address _buyer,
        address _referrer,
        string calldata _promo
    ) external payable nonReentrant
    {
        // 1.Define exact asset price with discounts
        ETypes.AssetItem memory payWithItem;
        { // Against stack too deep
            (KTypes.Price[] memory pArray, KTypes.Discount[] memory dArray) 
                = _getAssetItemPricesAndDiscounts(
                    _assetItem, _buyer, _referrer, hlpHashString(_promo)
            );

            uint256 totalDiscountPercent;
            for (uint256 i = 0; i < dArray.length; ++ i){
                totalDiscountPercent += dArray[i].dsctPercent;
                if (dArray[i].dsctType ==KTypes.DiscountType.REFERRAL){
                    emit EnvelopReferrer(
                        _referrer, msg.sender, 
                        pArray[_priceIndex].payWith,
                        pArray[_priceIndex].amount,
                        uint16(totalDiscountPercent)
                    );
                }
            } 
            
            payWithItem = ETypes.AssetItem(    
                ETypes.Asset(
                    pArray[_priceIndex].payWith == address(0)
                        ?ETypes.AssetType.NATIVE
                        :ETypes.AssetType.ERC20, 
                        pArray[_priceIndex].payWith
                ), 
                0, 
                pArray[_priceIndex].amount 
                    * (PERCENT_DENOMINATOR - totalDiscountPercent) / PERCENT_DENOMINATOR
            );
        }
        
        // 2. Manage display records for different cases
        address beneficiary;
        KTypes.Place memory p = getAssetItemPlace(_assetItem);
        //  Case when NFT just transfered to kiosk contract
        if (p.display == bytes32(0)) {
            //isImplicitAdded = true;
            beneficiary = displays[DEFAULT_DISPLAY].beneficiary;
            p.display = DEFAULT_DISPLAY;
            p.index = DEFAULT_INDEX;
        } else {
            beneficiary = displays[p.display].items[p.index].owner; 
            // 2.1 remove item from display
            if (p.index != displays[p.display].items.length - 1) {
                // if asset item is not last array element
                // then replace it with last element
                displays[p.display].items[p.index] = displays[p.display].items[
                    displays[p.display].items.length - 1
                ]; 
                // and change last element that was moved in above string
                assetAtDisplay[
                    displays[p.display].items[p.index].nft.asset.contractAddress // address of just moved nft
                ][
                    displays[p.display].items[p.index].nft.tokenId
                ] = KTypes.Place(
                   p.display,
                   p.index
                );
            }
            // remove last element from array
            displays[p.display].items.pop();
            
            // delete mapping element
            delete assetAtDisplay[_assetItem.asset.contractAddress][_assetItem.tokenId];
        }
        
        require(
            displays[p.display].enableAfter < block.timestamp
            && displays[p.display].disableAfter >= block.timestamp, 
            "Only in time"
        );

               
        // 3.Receive payment
        // There are two different cases: native token and erc20
        if (payWithItem.asset.assetType ==ETypes.AssetType.NATIVE )
        //if (pArray[_priceIndex].payWith == address(0)) 
        {
            // Native token payment
            require(payWithItem.amount 
                <= _transferSafe(payWithItem, address(this), beneficiary),
                "Insufficient balance after payment transfer"
            );
            // Return change
            if  ((msg.value - payWithItem.amount) > 0) {
                address payable s = payable(msg.sender);
                s.transfer(msg.value - payWithItem.amount);
            }
        } else {
            // ERC20 token payment
            require(msg.value == 0, "Only ERC20 tokens");
            require(payWithItem.amount 
                <=_transferSafe(payWithItem, msg.sender, beneficiary),
                "Insufficient balance after payment transfer"
            );
        }

        // 4. Send asset to buyer
        _transferSafe(_assetItem, address(this), _buyer);

        emit EnvelopPurchase(p.display, _assetItem.asset.contractAddress, _assetItem.tokenId);
    }

    //////////////////////////////////////////////////////////////
    function getDisplayOwner(bytes32 _displayNameHash) public view returns (address) {
        return displays[_displayNameHash].owner;
    }

    function getDisplay(bytes32 _displayNameHash) 
        public 
        view 
        returns (KTypes.Display memory) 
    {
        return displays[_displayNameHash];
    }

    function getAssetItemPlace(ETypes.AssetItem memory _assetItem) 
        public 
        view 
        returns  (KTypes.Place memory) 
    {
        if (_assetItem.asset.assetType == ETypes.AssetType.ERC721) {
            // ERC721
            require(
                _ownerOf(_assetItem) == address(this), 
                "Asset not transfered to kiosk"
            );
        } else {
            //ERC1155 or other**
            require(
                _balanceOf(_assetItem, address(this)) >= _assetItem.amount, 
                "Asset not transfered to kiosk"
            );
        }
        return assetAtDisplay[_assetItem.asset.contractAddress][_assetItem.tokenId];
    }

    function getAssetItemPricesAndDiscounts(
        ETypes.AssetItem memory _assetItem,
        address _buyer,
        address _referrer,
        string calldata _promo
    ) 
        external 
        view
        returns (KTypes.Price[] memory, KTypes.Discount[] memory)
    {
        return _getAssetItemPricesAndDiscounts(
            _assetItem,
            _buyer,
            _referrer,
            hlpHashString(_promo)
        );
    }

    /// @notice Returns ONLY items that was added with `addItemToDisplay`.
    /// @dev For obtain all items please use envelop oracle
    function getDisplayAssetItems(bytes32 _displayNameHash) 
        public 
        view 
        virtual
        returns (KTypes.ItemForSale[] memory) 
    {
        return displays[_displayNameHash].items; 
    }

    function getAssetItem(ETypes.AssetItem memory _assetItem)
        public
        view
        returns (KTypes.ItemForSale memory)
    {
        KTypes.Place memory p = getAssetItemPlace(_assetItem);
        return displays[p.display].items[p.index];

    } 

    function hlpHashString(string memory _name) public pure returns (bytes32) {
        return keccak256(abi.encode(_name));
    }

    /////////////////////////////
    ///       Internals        //
    /////////////////////////////
    function _setDisplayParams(
        bytes32 _displayNameHash,
        address _owner,
        address _beneficiary, // who will receive assets from sale
        uint256 _enableAfter,
        uint256 _disableAfter,
        address _priceModel
    ) 
        internal 
    {
        KTypes.Display storage d = displays[_displayNameHash];
        d.owner = _owner;
        d.beneficiary  = _beneficiary;
        d.enableAfter  = _enableAfter;
        d.disableAfter = _disableAfter;
        d.priceModel   = _priceModel;
    }

    function _addItemRecordAtDisplay(
        bytes32 _displayNameHash,
        address _itemOwner,
        ETypes.AssetItem memory _nft,
        KTypes.Price[] calldata _prices
    ) 
        internal 
        returns (KTypes.Place memory)
    {
        KTypes.ItemForSale storage it = displays[_displayNameHash].items.push();
        it.owner = _itemOwner;
        it.nft = _nft;
        if (_prices.length > 0){
            for (uint256 i = 0; i < _prices.length; ++ i) {
                it.prices.push(_prices[i]);    
            }
        }
        // add to mapping assetAtDisplay
        assetAtDisplay[_nft.asset.contractAddress][_nft.tokenId] = KTypes.Place(
            _displayNameHash,
            displays[_displayNameHash].items.length - 1
        );
        return assetAtDisplay[_nft.asset.contractAddress][_nft.tokenId];
    }

    function _addItemPriceAtIndex(
        bytes32 _displayNameHash,
        uint256 _itemIndex,
        KTypes.Price[] calldata _prices
    )
        internal
    {
        KTypes.ItemForSale storage it = displays[_displayNameHash].items[_itemIndex];
        for (uint256 i = 0; i < _prices.length; ++ i) {
            it.prices.push(_prices[i]);    
        }

    }


    function _editItemPriceAtIndex(
        bytes32 _displayNameHash,
        uint256 _itemIndex,
        uint256 _priceIndex,
        KTypes.Price calldata _price
    )
        internal
    {
        displays[_displayNameHash].items[_itemIndex].prices[_priceIndex] = _price;
    }

    function _getAssetItemPricesAndDiscounts(
        ETypes.AssetItem memory _assetItem,
        address _buyer,
        address _referrer,
        bytes32 _promoHash
    ) 
        internal
        view
        virtual
        returns(KTypes.Price[] memory, KTypes.Discount[] memory) 
    {
        // Define current asset Place
        KTypes.Place memory pl = getAssetItemPlace(_assetItem);
        if (pl.display == bytes32(0) && pl.index == 0){
            return (
                IDisplayPriceModel(displays[DEFAULT_DISPLAY].priceModel).getItemPrices(_assetItem),
                IDisplayPriceModel(displays[DEFAULT_DISPLAY].priceModel).getItemDiscounts(
                    _assetItem,
                    _buyer,
                    _referrer,
                    _promoHash
                )
            );
            //}
        }

        if (displays[pl.display].items[pl.index].prices.length > 0) 
        {
            return (
                displays[pl.display].items[pl.index].prices,
                IDisplayPriceModel(displays[pl.display].priceModel).getItemDiscounts(
                    _assetItem,
                    _buyer,
                    _referrer,
                    _promoHash
                )
            );
        }

        // If there is no individual prices then need ask priceModel contract of display
        return (
            IDisplayPriceModel(displays[pl.display].priceModel).getItemPrices(_assetItem),
            IDisplayPriceModel(displays[pl.display].priceModel).getItemDiscounts(
                _assetItem,
                _buyer,
                _referrer,
                _promoHash
            )
        );
    }
}
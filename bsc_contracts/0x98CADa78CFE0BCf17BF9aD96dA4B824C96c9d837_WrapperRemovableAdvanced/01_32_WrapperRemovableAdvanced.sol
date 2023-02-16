// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. 

import "WrapperBaseV1.sol";
import "IWrapperRemovable.sol";
import "IChecker.sol";

pragma solidity 0.8.16;

contract WrapperRemovableAdvanced is WrapperBaseV1, IWrapperRemovable {

    IChecker public checker;
    error UnSupported();

    constructor (address _erc20)
    WrapperBaseV1(_erc20) 
    {
    } 

    function wrap(
        ETypes.INData      calldata _inData, 
        ETypes.AssetItem[] calldata _collateral, 
        address _wrappFor
    ) 
        public 
        override(WrapperBaseV1, IWrapper)
        payable
        //onlyTrusted 
        nonReentrant 
        returns (ETypes.AssetItem memory) 
    {
        
        checker.isWrapEnabled(
            msg.sender,
            _inData, 
            _collateral, 
            _wrappFor
        );

        // 1. take original if not EMPTY wrap
        if (_inData.inAsset.asset.assetType != ETypes.AssetType.EMPTY) {  
            _transfer(_inData.inAsset, _inData.unWrapDestination, address(this));
        }    

        // 2. Mint wNFT
        _mintNFT(
            _inData.outType,     // what will be minted instead of wrapping asset
            lastWNFTId[_inData.outType].contractAddress, // wNFT contract address
            _wrappFor,                                   // wNFT receiver (1st owner) 
            lastWNFTId[_inData.outType].tokenId + 1,        
            _inData.outBalance                           // wNFT tokenId
        );
        lastWNFTId[_inData.outType].tokenId += 1;        //Save just minted id 


        // 4. Safe wNFT info
        _saveWNFTinfo(
            lastWNFTId[_inData.outType].contractAddress, 
            lastWNFTId[_inData.outType].tokenId,
            _inData
        );
        
        // 5. Add collateral
        _addCollateral(
            lastWNFTId[_inData.outType].contractAddress, 
            lastWNFTId[_inData.outType].tokenId, 
            _collateral
        );

        emit WrappedV1(
            _inData.inAsset.asset.contractAddress,        // inAssetAddress
            lastWNFTId[_inData.outType].contractAddress,  // outAssetAddress
            _inData.inAsset.tokenId,                      // inAssetTokenId 
            lastWNFTId[_inData.outType].tokenId,          // outTokenId 
            _wrappFor,                                    // wnftFirstOwner
            msg.value,                                    // nativeCollateralAmount
            _inData.rules                                 // rules
        );
        return ETypes.AssetItem(
            ETypes.Asset(_inData.outType, lastWNFTId[_inData.outType].contractAddress),
            lastWNFTId[_inData.outType].tokenId,
            _inData.outBalance
        );
    }

    function removeERC20Collateral(
        address _wNFTAddress, 
        uint256 _wNFTTokenId,
        address _collateralAddress
    ) external {
        revert UnSupported();
    }

    /**
     * @dev Function implement remove collateral logic 
     * enabled for address from  royalties array 
     *
     * @param _wNFTAddress address of wNFT contract
     * @param _wNFTTokenId id of wNFT 
     * @param _collateralAddress asset address for remove
     * @param _removeAmount amount for remove
     * @return _removedValue actualy removed amount
     */
    function removeERC20CollateralAmount(
        address _wNFTAddress, 
        uint256 _wNFTTokenId,
        address _collateralAddress,
        uint256 _removeAmount
    ) 
        public
        nonReentrant
        returns (uint256 _removedValue) 
    {
        checker.isRemoveEnabled(
            msg.sender,
            _wNFTAddress, 
            _wNFTTokenId,
            _collateralAddress,
            _removeAmount
        );
        
        (uint256 removeBalance, uint256 removeIndex) = getCollateralBalanceAndIndex(
                _wNFTAddress, 
                _wNFTTokenId,
                ETypes.AssetType(2), 
                _collateralAddress,
                0
        );
        require(removeBalance >= _removeAmount, 'Amount exceed balance');
        
        // TODO replace with internal for case update record 
        //wrappedTokens[_wNFTAddress][_wNFTTokenId].fees.push(Fee(0x04,_collateralAddress,_removeAmount));

        wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[removeIndex].amount 
            -= _removeAmount;
        
        emit CollateralRemoved(
            _wNFTAddress,
            _wNFTTokenId,
            2,
            _collateralAddress,
            0,
            _removeAmount
        );    
        
        // remove collateral
        _removedValue = _transferSafe(
            ETypes.AssetItem(
                ETypes.Asset(ETypes.AssetType.ERC20, _collateralAddress),
                0,
                _removeAmount
            ), 
            address(this), 
            msg.sender
        );

    }

    /////////////////////////////////////////////////////////////////////
    //                    Admin functions                              //
    ///////////////////////////////////////////////////////////////////// 
    function setTrustedAddress(address _operator, bool _status) public onlyOwner {
        
    }
    
    function setCheckerAddress(address _checker) public onlyOwner {
        checker = IChecker(_checker);
    }
}
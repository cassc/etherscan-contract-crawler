// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. 

import "WrapperBaseV1.sol";

pragma solidity 0.8.16;

contract TrustedWrapper is WrapperBaseV1 {

	address immutable public trustedOperator;

    constructor (address _erc20, address _trusted)
    WrapperBaseV1(_erc20) 
    {
    	trustedOperator = _trusted;
    } 

	modifier onlyTrusted() {
        require (trustedOperator == msg.sender, "Only trusted address");
        _;
    }


    function wrapUnsafe(
        ETypes.INData calldata _inData, 
        ETypes.AssetItem[] calldata _collateral, 
        address _wrappFor
    ) 
        public
        virtual 
        payable
        onlyTrusted 
        nonReentrant 
        returns (ETypes.AssetItem memory) 
    {
        // 1. Take users inAsset
        //////////////////////////////////////////
        //  !!!! All transfer logic must        // 
        //  be impemented in caller contract    //   
        // instead of here                      //
        //////////////////////////////////////////

        // 2. Mint wNFT
        _mintNFT(
            _inData.outType,     // what will be minted instead of wrapping asset
            lastWNFTId[_inData.outType].contractAddress, // wNFT contract address
            _wrappFor,                                   // wNFT receiver (1st owner) 
            lastWNFTId[_inData.outType].tokenId + 1,        
            _inData.outBalance                           // wNFT tokenId
        );
        lastWNFTId[_inData.outType].tokenId += 1;  //Save just minted id 


        // 4. Safe wNFT info
        _saveWNFTinfo(
            lastWNFTId[_inData.outType].contractAddress, 
            lastWNFTId[_inData.outType].tokenId,
            _inData
        );

        //////////////////////////////////////////
        //  !!!! All add collateral logic must  // 
        //  be impemented in caller contract    //   
        // instead of internal _addCollateral   //
        //////////////////////////////////////////
        for (uint256 i = 0; i <_collateral.length; i ++) {
            _updateCollateralInfo(
                    lastWNFTId[_inData.outType].contractAddress, 
                    lastWNFTId[_inData.outType].tokenId,
                    _collateral[i]
                );  
            emit CollateralAdded(
                lastWNFTId[_inData.outType].contractAddress, 
                lastWNFTId[_inData.outType].tokenId, 
                uint8(_collateral[i].asset.assetType),
                _collateral[i].asset.contractAddress,
                _collateral[i].tokenId,
                _collateral[i].amount
            );
        }
        //////////////////////////////////////////

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

    function transferIn(
        ETypes.AssetItem memory _assetItem,
        address _from
    ) 
        external 
        onlyTrusted 
        nonReentrant 
    returns (uint256 _transferedValue) 
    {
        return _transferSafe(_assetItem, _from, address(this));
    }

    // receive() external payable {
    //     require(msg.sender == trustedOperator);
    // }

    ////////////////////////////////////////
    //     Admin functions               ///
    ////////////////////////////////////////

    function setMaxCollateralSlots(uint256 _count) public onlyOwner {
        MAX_COLLATERAL_SLOTS = _count;
    }

}
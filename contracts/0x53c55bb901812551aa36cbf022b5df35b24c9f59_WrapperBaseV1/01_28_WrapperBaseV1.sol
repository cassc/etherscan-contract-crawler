// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. Wrapper - main protocol contract
pragma solidity 0.8.13;

import "Ownable.sol";
import "ERC721Holder.sol";
import "ERC1155Holder.sol";
import "ReentrancyGuard.sol";
import "IFeeRoyaltyModel.sol";
import "IWrapper.sol";
import "IAdvancedWhiteList.sol";
import "TokenService.sol";

// #### Envelop ProtocolV1 Rules
// 15   14   13   12   11   10   9   8   7   6   5   4   3   2   1   0  <= Bit number(dec)
// ------------------------------------------------------------------------------------  
//  1    1    1    1    1    1   1   1   1   1   1   1   1   1   1   1
//  |    |    |    |    |    |   |   |   |   |   |   |   |   |   |   |
//  |    |    |    |    |    |   |   |   |   |   |   |   |   |   |   +-No_Unwrap
//  |    |    |    |    |    |   |   |   |   |   |   |   |   |   +-No_Wrap 
//  |    |    |    |    |    |   |   |   |   |   |   |   |   +-No_Transfer
//  |    |    |    |    |    |   |   |   |   |   |   |   +-No_Collateral
//  |    |    |    |    |    |   |   |   |   |   |   +-reserved_core
//  |    |    |    |    |    |   |   |   |   |   +-reserved_core
//  |    |    |    |    |    |   |   |   |   +-reserved_core  
//  |    |    |    |    |    |   |   |   +-reserved_core
//  |    |    |    |    |    |   |   |
//  |    |    |    |    |    |   |   |
//  +----+----+----+----+----+---+---+
//      for use in extendings
/**
 * @title Non-Fungible Token Wrapper
 * @dev Make  wraping for existing ERC721 & ERC1155 and empty 
 */
contract WrapperBaseV1 is 
    ReentrancyGuard, 
    ERC721Holder, 
    ERC1155Holder, 
    IWrapper, 
    TokenService, 
    Ownable 
{

    uint256 public MAX_COLLATERAL_SLOTS = 25;
    address public protocolTechToken;
    address public protocolWhiteList;

    // Map from wrapping asset type to wnft contract address and last minted id
    mapping(ETypes.AssetType => ETypes.NFTItem) public lastWNFTId;  
    
    // Map from wNFT address to it's type (721, 1155)
    mapping(address => ETypes.AssetType) public wnftTypes;

    // Map from wrapped token address and id => wNFT record 
    mapping(address => mapping(uint256 => ETypes.WNFT)) internal wrappedTokens; 

    constructor(address _erc20) {
        require(_erc20 != address(0), "ProtocolTechToken cant be zero value");
        protocolTechToken = _erc20;
        // This because default trnaferFe moddel included in techToken code
        IFeeRoyaltyModel(protocolTechToken).registerModel(); 
    }

    
    function wrap(
        ETypes.INData calldata _inData, 
        ETypes.AssetItem[] calldata _collateral, 
        address _wrappFor
    ) 
        public 
        virtual
        payable 
        nonReentrant 
        returns (ETypes.AssetItem memory) 
    {

        // 0. Check assetIn asset
        require(_checkWrap(_inData,_wrappFor),
            "Wrap check fail"
        );
        // 1. Take users inAsset
        if ( _inData.inAsset.asset.assetType != ETypes.AssetType.NATIVE &&
             _inData.inAsset.asset.assetType != ETypes.AssetType.EMPTY
        ) 
        {
            require(
                _mustTransfered(_inData.inAsset) == _transferSafe(
                    _inData.inAsset, 
                    msg.sender, 
                    address(this)
                ),
                "Suspicious asset for wrap"
            );
        }
        
        // 2. Mint wNFT
        lastWNFTId[_inData.outType].tokenId += 1;  //Save just will minted id 
        _mintNFT(
            _inData.outType,     // what will be minted instead of wrapping asset
            lastWNFTId[_inData.outType].contractAddress, // wNFT contract address
            _wrappFor,                                   // wNFT receiver (1st owner) 
            lastWNFTId[_inData.outType].tokenId,        
            _inData.outBalance                           // wNFT tokenId
        );
        
        // 3. Safe wNFT info
        _saveWNFTinfo(
            lastWNFTId[_inData.outType].contractAddress, 
            lastWNFTId[_inData.outType].tokenId,
            _inData
        );

        
        addCollateral(
            lastWNFTId[_inData.outType].contractAddress, 
            lastWNFTId[_inData.outType].tokenId,
            _collateral
        ); 
         
        // Charge Fee Hook 
        // There is No Any Fees in Protocol
        // So this hook can be used in b2b extensions of Envelop Protocol 
        // 0x02 - feeType for WrapFee
        _chargeFees(
            lastWNFTId[_inData.outType].contractAddress, 
            lastWNFTId[_inData.outType].tokenId, 
            msg.sender, 
            address(this), 
            0x02
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

    function addCollateral(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        ETypes.AssetItem[] calldata _collateral
    ) public payable virtual  {
        if (_collateral.length > 0 || msg.value > 0) {
            require(
                _checkAddCollateral(
                    _wNFTAddress, 
                    _wNFTTokenId,
                    _collateral
                ),
                "Forbidden add collateral"
            );
            _addCollateral(
                _wNFTAddress, 
                _wNFTTokenId, 
                _collateral
            );
        }
    }

    

    function unWrap(address _wNFTAddress, uint256 _wNFTTokenId) external virtual {
        unWrap(wnftTypes[_wNFTAddress], _wNFTAddress, _wNFTTokenId, false);
    }

    function unWrap(
        ETypes.AssetType _wNFTType, 
        address _wNFTAddress, 
        uint256 _wNFTTokenId
    ) external virtual {
        unWrap(_wNFTType, _wNFTAddress, _wNFTTokenId, false);
    }

    function unWrap(
        ETypes.AssetType _wNFTType, 
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        bool _isEmergency
    ) public virtual {
        // 1. Check core protocol logic:
        // - who and what possible to unwrap
        (address burnFor, uint256 burnBalance) = _checkCoreUnwrap(_wNFTType, _wNFTAddress, _wNFTTokenId);

        // 2. Check  locks = move to _checkUnwrap
        require(
            _checkLocks(_wNFTAddress, _wNFTTokenId)
        );

        // 3. Charge Fee Hook 
        // There is No Any Fees in Protocol
        // So this hook can be used in b2b extensions of Envelop Protocol 
        // 0x03 - feeType for UnWrapFee
        // 
        _chargeFees(_wNFTAddress, _wNFTTokenId, msg.sender, address(this), 0x03);
        
        (uint256 nativeCollateralAmount, ) = getCollateralBalanceAndIndex(
            _wNFTAddress, 
            _wNFTTokenId,
            ETypes.AssetType.NATIVE,
            address(0),
            0
        );
        ///////////////////////////////////////////////
        ///  Place for hook                        ////
        ///////////////////////////////////////////////
        // 4. Safe return collateral to appropriate benificiary

        if (!_beforeUnWrapHook(_wNFTAddress, _wNFTTokenId, _isEmergency)) {
            return;
        }
        
        // 5. BurnWNFT
        _burnNFT(
            _wNFTType, 
            _wNFTAddress, 
            burnFor,  // msg.sender, 
            _wNFTTokenId, 
            burnBalance
        );

        emit UnWrappedV1(
            _wNFTAddress,
            wrappedTokens[_wNFTAddress][_wNFTTokenId].inAsset.asset.contractAddress,
            _wNFTTokenId, 
            wrappedTokens[_wNFTAddress][_wNFTTokenId].inAsset.tokenId,
            wrappedTokens[_wNFTAddress][_wNFTTokenId].unWrapDestination, 
            nativeCollateralAmount,  // TODO Check  GAS
            wrappedTokens[_wNFTAddress][_wNFTTokenId].rules 
        );
    } 

    function chargeFees(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        address _from, 
        address _to,
        bytes1 _feeType
    ) 
        public
        virtual  
        returns (bool) 
    {
        //TODO  only wNFT contract can  execute  this(=charge fee)
        require(msg.sender == _wNFTAddress || msg.sender == address(this), 
            "Only for wNFT or wrapper"
        );
        require(_chargeFees(_wNFTAddress, _wNFTTokenId, _from, _to, _feeType),
            "Fee charge fail"
        );
    }
    /////////////////////////////////////////////////////////////////////
    //                    Admin functions                              //
    /////////////////////////////////////////////////////////////////////
    function setWNFTId(
        ETypes.AssetType  _assetOutType, 
        address _wnftContract, 
        uint256 _tokenId
    ) external onlyOwner {
        require(_wnftContract != address(0), "No zero address");
        lastWNFTId[_assetOutType] = ETypes.NFTItem(_wnftContract, _tokenId);
        wnftTypes[_wnftContract] =  _assetOutType;
    }

    function setWhiteList(address _wlAddress) external onlyOwner {
        protocolWhiteList = _wlAddress;
    }
    /////////////////////////////////////////////////////////////////////


    function getWrappedToken(address _wNFTAddress, uint256 _wNFTTokenId) 
        public 
        view 
        returns (ETypes.WNFT memory) 
    {
        return wrappedTokens[_wNFTAddress][_wNFTTokenId];
    }

    function getOriginalURI(address _wNFTAddress, uint256 _wNFTTokenId) 
        public 
        view 
        returns(string memory uri_) 
    {
        ETypes.AssetItem memory _wnftInAsset = getWrappedToken(
                _wNFTAddress, _wNFTTokenId
        ).inAsset;

        if (_wnftInAsset.asset.assetType == ETypes.AssetType.ERC721) {
            uri_ = IERC721Metadata(_wnftInAsset.asset.contractAddress).tokenURI(_wnftInAsset.tokenId);
        
        } else if (_wnftInAsset.asset.assetType == ETypes.AssetType.ERC1155) {
            uri_ = IERC1155MetadataURI(_wnftInAsset.asset.contractAddress).uri(_wnftInAsset.tokenId);
        
        } else {
            uri_ = '';
        } 
    }

    function getCollateralBalanceAndIndex(
        address _wNFTAddress, 
        uint256 _wNFTTokenId,
        ETypes.AssetType _collateralType, 
        address _erc,
        uint256 _tokenId
    ) public view returns (uint256, uint256) 
    {
        for (uint256 i = 0; i < wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.length; i ++) {
            if (wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i].asset.contractAddress == _erc &&
                wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i].tokenId == _tokenId &&
                wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i].asset.assetType == _collateralType 
            ) 
            {
                return (wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i].amount, i);
            }
        }
    } 
    /////////////////////////////////////////////////////////////////////
    //                    Internals                                    //
    /////////////////////////////////////////////////////////////////////
    function _saveWNFTinfo(
        address wNFTAddress, 
        uint256 tokenId, 
        ETypes.INData calldata _inData
    ) internal virtual 
    {
        wrappedTokens[wNFTAddress][tokenId].inAsset = _inData.inAsset;
        // We will use _inData.unWrapDestination  ONLY for RENT implementation
        // wrappedTokens[wNFTAddress][tokenId].unWrapDestination = _inData.unWrapDestination;
        wrappedTokens[wNFTAddress][tokenId].unWrapDestination = address(0);
        wrappedTokens[wNFTAddress][tokenId].rules = _inData.rules;
        
        // Copying of type struct ETypes.Fee memory[] 
        // memory to storage not yet supported.
        for (uint256 i = 0; i < _inData.fees.length; i ++) {
            wrappedTokens[wNFTAddress][tokenId].fees.push(_inData.fees[i]);            
        }

        for (uint256 i = 0; i < _inData.locks.length; i ++) {
            wrappedTokens[wNFTAddress][tokenId].locks.push(_inData.locks[i]);            
        }

        for (uint256 i = 0; i < _inData.royalties.length; i ++) {
            wrappedTokens[wNFTAddress][tokenId].royalties.push(_inData.royalties[i]);            
        }

    }

    function _addCollateral(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        ETypes.AssetItem[] calldata _collateral
    ) internal virtual 
    {
        // Process Native Colleteral
        if (msg.value > 0) {
            _updateCollateralInfo(
                _wNFTAddress, 
                _wNFTTokenId,
                ETypes.AssetItem(
                    ETypes.Asset(ETypes.AssetType.NATIVE, address(0)),
                    0,
                    msg.value
                )
            );
            emit CollateralAdded(
                    _wNFTAddress, 
                    _wNFTTokenId, 
                    uint8(ETypes.AssetType.NATIVE),
                    address(0),
                    0,
                    msg.value
                );
        }
       
        // Process Token Colleteral
        for (uint256 i = 0; i <_collateral.length; i ++) {
            if (_collateral[i].asset.assetType != ETypes.AssetType.NATIVE) {
                
                // Check WhiteList Logic
                if  (protocolWhiteList != address(0)) {
                    require(
                        IAdvancedWhiteList(protocolWhiteList).enabledForCollateral(
                        _collateral[i].asset.contractAddress),
                        "WL:Some assets are not enabled for collateral"
                    );
                } 
                require(
                    _mustTransfered(_collateral[i]) == _transferSafe(
                        _collateral[i], 
                        msg.sender, 
                        address(this)
                    ),
                    "Suspicious asset for wrap"
                );
                _updateCollateralInfo(
                    _wNFTAddress, 
                    _wNFTTokenId,
                    _collateral[i]
                );
                emit CollateralAdded(
                    _wNFTAddress, 
                    _wNFTTokenId, 
                    uint8(_collateral[i].asset.assetType),
                    _collateral[i].asset.contractAddress,
                    _collateral[i].tokenId,
                    _collateral[i].amount
                );
            }
        }
    }

    function _updateCollateralInfo(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        ETypes.AssetItem memory collateralItem
    ) internal virtual 
    {
        /////////////////////////////////////////
        //  ERC20 & NATIVE Collateral         ///
        /////////////////////////////////////////
        if (collateralItem.asset.assetType == ETypes.AssetType.ERC20  ||
            collateralItem.asset.assetType == ETypes.AssetType.NATIVE) 
        {
            require(collateralItem.tokenId == 0, "TokenId must be zero");
        }

        /////////////////////////////////////////
        //  ERC1155 Collateral                ///
        // /////////////////////////////////////////
        // if (collateralItem.asset.assetType == ETypes.AssetType.ERC1155) {
        //  No need special checks
        // }    

        /////////////////////////////////////////
        //  ERC721 Collateral                 ///
        /////////////////////////////////////////
        if (collateralItem.asset.assetType == ETypes.AssetType.ERC721 ) {
            require(collateralItem.amount == 0, "Amount must be zero");
        }
        /////////////////////////////////////////
        if (wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.length == 0 
            || collateralItem.asset.assetType == ETypes.AssetType.ERC721 
        )
        {
            // First record in collateral or 721
            _newCollateralItem(_wNFTAddress,_wNFTTokenId,collateralItem);
        }  else {
             // length > 0 
            (uint256 _amnt, uint256 _index) = getCollateralBalanceAndIndex(
                _wNFTAddress, 
                _wNFTTokenId,
                collateralItem.asset.assetType, 
                collateralItem.asset.contractAddress,
                collateralItem.tokenId
            );

            if (_index > 0 ||
                   (_index == 0 
                    && wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[0].asset.contractAddress 
                        == collateralItem.asset.contractAddress 
                    ) 
                ) 
            {
                // We dont need addition if  for erc721 because for erc721 _amnt always be zero
                wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[_index].amount 
                += collateralItem.amount;

            } else {
                // _index == 0 &&  and no this  token record yet
                _newCollateralItem(_wNFTAddress,_wNFTTokenId,collateralItem);
            }
        }
    }

    function _newCollateralItem(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        ETypes.AssetItem memory collateralItem
    ) internal virtual 

    {
        require(
            wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.length < MAX_COLLATERAL_SLOTS, 
            "Too much tokens in collateral"
        );

        for (uint256 i = 0; i < wrappedTokens[_wNFTAddress][_wNFTTokenId].locks.length; i ++) 
        {
            // Personal Collateral count Lock check
            if (wrappedTokens[_wNFTAddress][_wNFTTokenId].locks[i].lockType == 0x02) {
                require(
                    wrappedTokens[_wNFTAddress][_wNFTTokenId].locks[i].param 
                      >= (wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.length + 1),
                    "Too much collateral slots for this wNFT"
                );
            }
        }
        wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.push(collateralItem);
    }


    function _chargeFees(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        address _from, 
        address _to,
        bytes1 _feeType
    ) 
        internal
        virtual  
        returns (bool) 
    {
        if (_feeType == 0x00) {// Transfer fee
            for (uint256 i = 0; i < wrappedTokens[_wNFTAddress][_wNFTTokenId].fees.length; i ++){
                /////////////////////////////////////////
                // For Transfer Fee -0x00             ///  
                /////////////////////////////////////////
                if (wrappedTokens[_wNFTAddress][_wNFTTokenId].fees[i].feeType == 0x00){
                   // - get modelAddress.  Default feeModel adddress always live in
                   // protocolTechToken. When white list used it is possible override that model.
                   // default model always  must be set  as protocolTechToken
                   address feeModel = protocolTechToken;
                    if  (protocolWhiteList != address(0)) {
                        feeModel = IAdvancedWhiteList(protocolWhiteList).getWLItem(
                            wrappedTokens[_wNFTAddress][_wNFTTokenId].fees[i].token).transferFeeModel;
                    }

                    // - get transfer list from external model by feetype(with royalties)
                    (ETypes.AssetItem[] memory assetItems, 
                     address[] memory from, 
                     address[] memory to
                    ) =
                        IFeeRoyaltyModel(feeModel).getTransfersList(
                            wrappedTokens[_wNFTAddress][_wNFTTokenId].fees[i],
                            wrappedTokens[_wNFTAddress][_wNFTTokenId].royalties,
                            _from, 
                            _to 
                        );
                    // - execute transfers
                    uint256 actualTransfered;
                    for (uint256 j = 0; j < to.length; j ++){
                        // if transfer receiver(to) = address(this) lets consider
                        // wNFT as receiver. in this case received amount
                        // will be added to collateral
                        if (to[j]== address(this)){
                            _updateCollateralInfo(
                              _wNFTAddress, 
                              _wNFTTokenId, 
                               assetItems[j]
                            ); 
                        }
                        actualTransfered = _transferSafe(assetItems[j], from[j], to[j]);
                        emit EnvelopFee(to[j], _wNFTAddress, _wNFTTokenId, actualTransfered); 
                    }
                }
                //////////////////////////////////////////
            }
            return true;
        }
    }


    /**
     * @dev This hook may be overriden in inheritor contracts for extend
     * base functionality.
     *
     * @param _wNFTAddress -wrapped token address
     * @param _wNFTTokenId -wrapped token id
     * 
     * must returns true for success unwrapping enable 
     */
    function _beforeUnWrapHook(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        bool _emergency
    ) internal virtual returns (bool)
    {
        uint256 transfered;
        address receiver = msg.sender;
        if (wrappedTokens[_wNFTAddress][_wNFTTokenId].unWrapDestination != address(0)) {
            receiver = wrappedTokens[_wNFTAddress][_wNFTTokenId].unWrapDestination;
        }

        for (uint256 i = 0; i < wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.length; i ++) {
            if (wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i].asset.assetType 
                != ETypes.AssetType.EMPTY
            ) {
                if (_emergency) {
                    // In case of something is wrong with any collateral (attack)
                    // user can use  this mode  for skip  malicious asset
                    transfered = _transferEmergency(
                        wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i],
                        address(this),
                        receiver
                    );
                } else {
                    transfered = _transferSafe(
                        wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i],
                        address(this),
                        receiver
                    );
                }

                // we collect info about contracts with not standard behavior
                if (transfered != wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i].amount ) {
                    emit SuspiciousFail(
                        _wNFTAddress, 
                        _wNFTTokenId, 
                        wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i].asset.contractAddress
                    );
                }

                // mark collateral record as returned
                wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i].asset.assetType = ETypes.AssetType.EMPTY;                
            }
            // dont pop due in some case it c can be very costly
            // https://docs.soliditylang.org/en/v0.8.9/types.html#array-members  

            // For safe exit in case of low gaslimit
            // this strange part of code can prevent only case 
            // when when some collateral tokens spent unexpected gas limit
            if (
                gasleft() <= 1_000 &&
                    i < wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.length - 1
                ) 
            {
                emit PartialUnWrapp(_wNFTAddress, _wNFTTokenId, i);
                //allReturned = false;
                return false;
            }
        }

        // 5. Return Original
        if (wrappedTokens[_wNFTAddress][_wNFTTokenId].inAsset.asset.assetType != ETypes.AssetType.NATIVE && 
            wrappedTokens[_wNFTAddress][_wNFTTokenId].inAsset.asset.assetType != ETypes.AssetType.EMPTY
        ) 
        {

            if (!_emergency){
                _transferSafe(
                    wrappedTokens[_wNFTAddress][_wNFTTokenId].inAsset,
                    address(this),
                    receiver
                );
            } else {
                _transferEmergency (
                    wrappedTokens[_wNFTAddress][_wNFTTokenId].inAsset,
                    address(this),
                    receiver
                );
            }
        }
        return true;
    }
    ////////////////////////////////////////////////////////////////////////////////////////////

    function _mustTransfered(ETypes.AssetItem calldata _assetForTransfer) 
        internal 
        pure 
        returns (uint256 mustTransfered) 
    {
        // Available for wrap assets must be good transferable (stakable).
        // So for erc721  mustTransfered always be 1
        if (_assetForTransfer.asset.assetType == ETypes.AssetType.ERC721) {
            mustTransfered = 1;
        } else {
            mustTransfered = _assetForTransfer.amount;
        }
    }
     
    function _checkRule(bytes2 _rule, bytes2 _wNFTrules) internal view returns (bool) {
        return _rule == (_rule & _wNFTrules);
    }

    // 0x00 - TimeLock
    // 0x01 - TransferFeeLock
    // 0x02 - Personal Collateral count Lock check
    function _checkLocks(address _wNFTAddress, uint256 _wNFTTokenId) internal view returns (bool) 
    {
        // Lets check that inAsset
        for (uint256 i = 0; i < wrappedTokens[_wNFTAddress][_wNFTTokenId].locks.length; i ++) {
            // Time Lock check
            if (wrappedTokens[_wNFTAddress][_wNFTTokenId].locks[i].lockType == 0x00) {
                require(
                    wrappedTokens[_wNFTAddress][_wNFTTokenId].locks[i].param <= block.timestamp,
                    "TimeLock error"
                );
            }

            // Fee Lock check
            if (wrappedTokens[_wNFTAddress][_wNFTTokenId].locks[i].lockType == 0x01) {
                // Lets check this lock rule against each fee record
                for (uint256 j = 0; j < wrappedTokens[_wNFTAddress][_wNFTTokenId].fees.length; j ++){
                    // Fee Lock depend  only from Transfer Fee - 0x00
                    if ( wrappedTokens[_wNFTAddress][_wNFTTokenId].fees[j].feeType == 0x00) {
                        (uint256 _bal,) = getCollateralBalanceAndIndex(
                            _wNFTAddress, 
                            _wNFTTokenId,
                            ETypes.AssetType.ERC20,
                            wrappedTokens[_wNFTAddress][_wNFTTokenId].fees[j].token,
                            0
                        );
                        require(
                            wrappedTokens[_wNFTAddress][_wNFTTokenId].locks[i].param <= _bal,
                            "TransferFeeLock error"
                        );
                    }   
                }
            }
        }
        return true;
    }


    function _checkWrap(ETypes.INData calldata _inData, address _wrappFor) 
        internal 
        view 
        returns (bool enabled)
    {
        // Lets check that inAsset 
        // 0x0002 - this rule disable wrap already wrappednFT (NO matryoshka)
        enabled = !_checkRule(0x0002, getWrappedToken(
            _inData.inAsset.asset.contractAddress, 
            _inData.inAsset.tokenId).rules
            ) 
            && _wrappFor != address(this);
        // Check WhiteList Logic
        if  (protocolWhiteList != address(0)) {
            require(
                !IAdvancedWhiteList(protocolWhiteList).getBLItem(_inData.inAsset.asset.contractAddress),
                "WL:Asset disabled for wrap"
            );
            require(
                IAdvancedWhiteList(protocolWhiteList).rulesEnabled(_inData.inAsset.asset.contractAddress, _inData.rules),
                "WL:Some rules are disabled for this asset"
            );

            for (uint256 i = 0; i < _inData.fees.length; i ++){
                require(
                    IAdvancedWhiteList(protocolWhiteList).enabledForFee(
                    _inData.fees[i].token),
                    "WL:Some assets are not enabled for fee"
                );
            }
        }    
    }
    
    function _checkAddCollateral(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        ETypes.AssetItem[] calldata _collateral
    ) 
        internal 
        view 
        returns (bool enabled)
    {
        // Check  that wNFT exist
        if (wnftTypes[_wNFTAddress] == ETypes.AssetType.ERC721) {
            require(IERC721Mintable(_wNFTAddress).exists(_wNFTTokenId), "wNFT not exists");
        } else if(wnftTypes[_wNFTAddress] == ETypes.AssetType.ERC1155) {
            require(IERC1155Mintable(_wNFTAddress).exists(_wNFTTokenId), "wNFT not exists");
        } else {
            revert UnSupportedAsset(
                ETypes.AssetItem(ETypes.Asset(wnftTypes[_wNFTAddress],_wNFTAddress),_wNFTTokenId, 0)
            );
        }
        // Lets check wNFT rules 
        // 0x0008 - this rule disable add collateral
        enabled = !_checkRule(0x0008, getWrappedToken(_wNFTAddress, _wNFTTokenId).rules); 
    }

    function _checkCoreUnwrap(
        ETypes.AssetType _wNFTType, 
        address _wNFTAddress, 
        uint256 _wNFTTokenId
    ) 
        internal 
        view 
        virtual 
        returns (address burnFor, uint256 burnBalance) 
    {
        
        // Lets wNFT rules 
        // 0x0001 - this rule disable unwrap wrappednFT 
        require(!_checkRule(0x0001, getWrappedToken(_wNFTAddress, _wNFTTokenId).rules),
            "UnWrapp forbidden by author"
        );

        if (_wNFTType == ETypes.AssetType.ERC721) {
            // Only token owner can UnWrap
            burnFor = IERC721Mintable(_wNFTAddress).ownerOf(_wNFTTokenId);
            require(burnFor == msg.sender, 
                'Only owner can unwrap it'
            ); 

        } else if (_wNFTType == ETypes.AssetType.ERC1155) {
            burnBalance = IERC1155Mintable(_wNFTAddress).totalSupply(_wNFTTokenId);
            burnFor = msg.sender;
            require(
                burnBalance ==
                IERC1155Mintable(_wNFTAddress).balanceOf(burnFor, _wNFTTokenId)
                ,'ERC115 unwrap available only for all totalSupply'
            );
            
        } else {
            revert UnSupportedAsset(ETypes.AssetItem(ETypes.Asset(_wNFTType,_wNFTAddress),_wNFTTokenId, 0));
        }
    }
}
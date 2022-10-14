// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IFactory {
    function DIAMONDPASS() external view returns (address);
    function price() external view returns (uint256);
    function minBreakPrice() external view returns (uint256);
    function checkDiamondSpecial(address _contractAddress, uint256 _tokenId) external view returns(bool);
}

abstract contract ERC721Interface {
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public virtual;
  function balanceOf(address _owner) public virtual view returns (uint256);
}

abstract contract ERC1155Interface {
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) public virtual;
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory i_ds, uint256[] memory _amounts, bytes memory _data) public virtual;
  function balanceOf(address _owner, uint256 _id) external virtual view returns (uint256);
}

/// @title A time-locked vault for ERC721, ERC1155, ERC20 and ETH with emergency unlock functionality. Supports withdrawal of airdropped tokens
/// @author Momo Labs

contract DiamondVault is Initializable, ERC721Holder, ERC1155Holder {
    bool public isLogic;       //Only the implementation logic contract will have this as true. Will ensure base contract can't be initialized
    address payable public factoryContractAddress;     //Address of factory contract that deployed this vault
    address public vaultOwner;                  
    uint256 public vaultNumber;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    Counters.Counter private diamondIds;

    /** Structs & Enums **/
    enum diamondStatus { Holding, Broken, Released} //Diamond Status (Holding for still diamond-handing, broken = used emergency break, released = claimed after time passed)
    enum assetType { ERC721, ERC1155, ERC20, ETH} //Type of asset being diamond-handed

    /**
    * @dev Struct for asset that is to be diamond-handed
    * @param contractAddress Address of the token contract that is to be diamond-handed
    * @param tokenType AssetType referring to type of asset being diamond-handed (ERC721, ERC1155, ERC20, or ETH)
    * @param tokenID ID of token
    * @param quantity Amount (for ERC1155 tokens, ERC20, and ETH)
    * @param data Other data
    */
    struct diamondStruct {
        address contractAddress;      
        bytes data;             
        assetType tokenType;    
        uint256[] tokenId;      
        uint256[] quantity;     
    }

     /**
    * @dev Struct to hold diamond-hand information
    * @param id DiamondID (unique ID for each diamond-hand created)
    * @param diamondStartTime Timestamp of when this diamond-hand is initially created
    * @param releaseTime Timestamp of when this diamond-hand order is unlocked (when asset becomes withdrawable)
    * @param breakPrice Price to unlock diamond-hand in case of emergency
    * @param status diamondStatus representing the status of this diamond-hand
    */
    struct diamondHands {
        uint256 id;
        uint256 diamondStartTime;
        uint256 releaseTime;
        uint256 breakPrice;
        diamondStatus status;
    }

    /**
    * @dev Struct to store information of NFTs on the diamondSpecial list. diamondSpecial can be used to reward certain communities with free Diamond-Hand usage
    * @param contractAddress Address of the NFT
    * @param tokenId tokenId of the NFT
    * @param tokenType Type of the NFT (ERC721 or ERC1155)
    */
    struct diamondSpecialStruct {
        address contractAddress;
        assetType tokenType;
        uint256 tokenId;
    }
    
    //MAPPINGS 
    mapping (uint256 => diamondStruct[]) private diamondAssets;    //Asset Mapping (maps a diamondhand ID to corresponding diamondStruct asset)
    mapping (uint256 => diamondHands) private diamondList;    //Mapping a diamondhand ID to corresponding diamondHand information
    mapping (bytes32 => bool) private currentlyDiamondHanding;    //Mapping to check if an asset is currently being diamondHanded (used to separate assets when claiming airdrops)
    mapping (bytes32 => uint256) private currentlyDiamondHandingQuantities;    //Mapping to check quantities of an asset being diamondhanded (ERC1155, ERC20, ETH)

    /** EVENTS **/
    event DiamondHandCreated(uint256 indexed _diamondId, uint256 _currentTime, uint256 indexed _releaseTime, uint256 _breakPrice, diamondStatus _status);
    event DiamondHandBroken(uint256 indexed _diamondId, uint256 indexed _currentTime, uint256 _releaseTime, uint256 _breakPrice, diamondStatus _status);
    event DiamondHandReleased(uint256 indexed _diamondId, uint256 indexed _currentTime, uint256 _releaseTime, uint256 _breakPrice, diamondStatus _status);
    event WithdrawnERC20(address indexed _contractAddress, uint256 indexed amount);
    event WithdrawnERC721(address indexed _contractAddress, uint256 indexed _tokenId);
    event WithdrawnERC1155(address indexed _contractAddress, uint256 indexed _tokenId, uint256 indexed amount);
    event WithdrawnETH(uint256 indexed amount);
    event ReceivedEther(address indexed sender);

    constructor(){
        //Ensures that base logic contract cannot be initialized
        isLogic = true;
    }
    
      /**
    * @notice Initializer to initialize proxy from factory
    * @param _vaultNumber The vault number of this proxy
    * @param _vaultOwner The owner of this vault (set to whoever called createDiamondVault in factory contract)
    * @param _vaultFactoryContractAddress The address of factory contract
    */
    function initialize(
        uint256 _vaultNumber,
        address _vaultOwner,
        address _vaultFactoryContractAddress
    ) external initializer {
        require(isLogic == false, "Can't initialize base contract");
        vaultNumber = _vaultNumber;
        vaultOwner = _vaultOwner;
        factoryContractAddress = payable(_vaultFactoryContractAddress);
    }

    /**
    * @dev Modifier for functions to restrict to vaultOwner
    */
    modifier onlyVaultOwner() {
        require(
            msg.sender == vaultOwner,
            "Must be owner"
        );
        _;
    }

    /**
    * @notice Transfers asset to contract and stores relevant diamond-hand information
    * @param _diamondAsset diamondStruct storing relevant information for the asset to be diamond-handed (see struct declaration above)
    * @param _releaseTime Timestamp when this diamond-hand is unlocked (when asset becomes withdrawable)
    * @param _breakPrice Price to unlock diamond-hand in case of emergency
    * @param _diamondSpecial diamondSpecialStruct, if user owns an NFT that is on the diamondSpecial list, they can createDiamondHands for free
    */
    function createDiamondHands(diamondStruct memory _diamondAsset, uint256 _releaseTime, uint256 _breakPrice, diamondSpecialStruct memory _diamondSpecial) payable external onlyVaultOwner {
        require(_releaseTime > block.timestamp, "Release time in the past");
        require(_breakPrice >= getMinBreakPrice(), "Break price too low");
        if(_diamondAsset.tokenType != assetType.ETH){
            require(_diamondAsset.contractAddress != address(0), "Invalid contract address");
        }

        bool needsPayment;
        if (ERC721Interface(getDiamondPassAddress()).balanceOf(msg.sender) == 0){
            //If caller does not have a diamond pass
            if (checkDiamondSpecial(_diamondSpecial.contractAddress, _diamondSpecial.tokenId)){
                if(_diamondSpecial.tokenType == assetType.ERC721){
                    if(ERC721Interface(_diamondSpecial.contractAddress).balanceOf(msg.sender) == 0 ){
                        //If caller claims they have an NFT that is on the diamondSpecial but actually doesn't
                        require(msg.value >= getPrice(), "Not enough ETH");
                        needsPayment = true;
                    }
                } else if (_diamondSpecial.tokenType == assetType.ERC1155){
                    if(ERC1155Interface(_diamondSpecial.contractAddress).balanceOf(msg.sender, _diamondSpecial.tokenId) == 0){
                        //If caller claims they have an NFT that is on the diamondSpecial but actually doesn't
                        require(msg.value >= getPrice(), "Not enough ETH");
                        needsPayment = true;
                    }
                }
            } else {
                //If caller does not have an NFT on diamondSpecial
                require(msg.value >= getPrice(), "Not enough ETH");
                needsPayment = true;
            }
        }
        //Create diamondHand information
        diamondHands memory _diamondHands;
        
        _diamondHands.id = diamondIds.current();
        _diamondHands.releaseTime = _releaseTime;
        _diamondHands.diamondStartTime = block.timestamp;
        _diamondHands.breakPrice = _breakPrice;
        _diamondHands.status = diamondStatus.Holding;

        diamondList[_diamondHands.id] = (_diamondHands);

        uint256 depositedETH;   //Used to keep track of additional ETH deposited by user (if they choose to diamond-hand ETH)
        
        //Add assets to list of diamondAssets in contract
        require(_diamondAsset.tokenType == assetType.ERC721 || _diamondAsset.tokenType == assetType.ERC1155 || _diamondAsset.tokenType == assetType.ERC20 || _diamondAsset.tokenType == assetType.ETH, "diamondAsset not supported");
        require(_diamondAsset.tokenId.length == _diamondAsset.quantity.length, "tokenId & quantity mismatch");
        diamondAssets[_diamondHands.id].push(_diamondAsset);

        //Transfer asset to vault for storage
        if(_diamondAsset.tokenType == assetType.ERC721) {
            require(_diamondAsset.tokenId.length == 1, "Invalid tokenId quantity");
            currentlyDiamondHanding[keccak256(abi.encodePacked(_diamondAsset.contractAddress, _diamondAsset.tokenId[0]))] = true;
            ERC721Interface(_diamondAsset.contractAddress).safeTransferFrom(msg.sender, address(this), _diamondAsset.tokenId[0], _diamondAsset.data);
        }
        else if(_diamondAsset.tokenType == assetType.ERC1155) {
            for(uint256 i; i < _diamondAsset.tokenId.length; i++){
                currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(_diamondAsset.contractAddress, _diamondAsset.tokenId[i]))] += _diamondAsset.quantity[i];
            }
            ERC1155Interface(_diamondAsset.contractAddress).safeBatchTransferFrom(msg.sender, address(this), _diamondAsset.tokenId, _diamondAsset.quantity, _diamondAsset.data);
        }
        else if (_diamondAsset.tokenType == assetType.ERC20){
            require(_diamondAsset.quantity.length == 1, "Invalid quantity input");
            currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(_diamondAsset.contractAddress))] += _diamondAsset.quantity[0];
            IERC20(_diamondAsset.contractAddress).safeTransferFrom(msg.sender, address(this), _diamondAsset.quantity[0]);
        }
        else if (_diamondAsset.tokenType == assetType.ETH){
            if (needsPayment){
                require(msg.value == getPrice() + _diamondAsset.quantity[0], "ETH amount mismatch");
            } else {
                require(msg.value == _diamondAsset.quantity[0], "ETH amount mismatch");
            }
            currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetType.ETH))] += _diamondAsset.quantity[0];
            depositedETH += _diamondAsset.quantity[0];
        }

        if (msg.value > 0){
            //Transfer payment (payment = msg value - any deposited ETH)
            (bool success, ) = factoryContractAddress.call{value: msg.value - depositedETH}("");
            require(success, "ETH payment failed");
        }

        emit DiamondHandCreated(_diamondHands.id, block.timestamp, _diamondHands.releaseTime, _diamondHands.breakPrice, _diamondHands.status);
        diamondIds.increment();
    }

     /**
    * @notice Transfers assets to contract and stores relevant diamond-hand information (in batch)
    * @param _diamondAsset diamondStruct storing relevant information for the assets to be diamond-handed (see struct declaration above)
    * @param _releaseTime Timestamp when this diamond-hand is unlocked (when asset becomes withdrawable)
    * @param _breakPrice Price to unlock diamond-hand in case of emergency
    * @param _diamondSpecial diamondSpecialStruct, if user owns an asset that is on the diamondSpecial list, they can createDiamondHands for free
    */
    function createDiamondHandsBatch(diamondStruct[] memory _diamondAsset, uint256 _releaseTime, uint256 _breakPrice, diamondSpecialStruct memory _diamondSpecial) payable external onlyVaultOwner {
        require(_releaseTime > block.timestamp, "Release time in the past");
        require(_breakPrice >= getMinBreakPrice(), "Break price too low");
        require(_diamondAsset.length > 0, "Empty diamondAsset");

        bool needsPayment;
        if (ERC721Interface(getDiamondPassAddress()).balanceOf(msg.sender) == 0){
            //If caller does not have a diamond pass
            if (checkDiamondSpecial(_diamondSpecial.contractAddress, _diamondSpecial.tokenId)){
                if(_diamondSpecial.tokenType == assetType.ERC721){
                    if(ERC721Interface(_diamondSpecial.contractAddress).balanceOf(msg.sender) == 0 ){
                        //If caller claims they have an NFT that is on the diamondSpecial but actually doesn't
                        require(msg.value >= getPrice(), "Not enough ETH");
                        needsPayment = true;
                    }
                } else if (_diamondSpecial.tokenType == assetType.ERC1155){
                    if(ERC1155Interface(_diamondSpecial.contractAddress).balanceOf(msg.sender, _diamondSpecial.tokenId) == 0){
                        //If caller claims they have an NFT that is on the diamondSpecial but actually doesn't
                        require(msg.value >= getPrice(), "Not enough ETH");
                        needsPayment = true;
                    }
                }
            } else {
                //If caller does not have an NFT on diamondSpecial
                require(msg.value >= getPrice(), "Not enough ETH");
                needsPayment = true;
            }
        }
        //Create diamondHand information
        diamondHands memory _diamondHands;
        
        _diamondHands.id = diamondIds.current();
        _diamondHands.releaseTime = _releaseTime;
        _diamondHands.diamondStartTime = block.timestamp;
        _diamondHands.breakPrice = _breakPrice;
        _diamondHands.status = diamondStatus.Holding;
        
        diamondList[_diamondHands.id] = (_diamondHands);

        uint256 depositedETH;   //Used to keep track of additional ETH deposited by user (if they choose to diamond-hand ETH)
        uint256 i;
        //Add assets to list of diamondAssets in contract
        for(i = 0; i < _diamondAsset.length; i++) {
            require(_diamondAsset[i].tokenType == assetType.ERC721 || _diamondAsset[i].tokenType == assetType.ERC1155 || _diamondAsset[i].tokenType == assetType.ERC20 || _diamondAsset[i].tokenType == assetType.ETH, "diamondAsset not supported");
            require(_diamondAsset[i].tokenId.length == _diamondAsset[i].quantity.length, "tokenId & quantity mismatch");
            diamondAssets[_diamondHands.id].push(_diamondAsset[i]);
        }
        
        //Transfer each asset in array into vault for storage
        for(i = 0; i < _diamondAsset.length; i++) {
            if(_diamondAsset[i].tokenType != assetType.ETH) {
                require(_diamondAsset[i].contractAddress != address(0), "Invalid contract address");
            }
            if(_diamondAsset[i].tokenType == assetType.ERC721) {
                require(_diamondAsset[i].tokenId.length == 1, "Invalid tokenId quantity");
                currentlyDiamondHanding[keccak256(abi.encodePacked(_diamondAsset[i].contractAddress, _diamondAsset[i].tokenId[0]))] = true;
                ERC721Interface(_diamondAsset[i].contractAddress).safeTransferFrom(msg.sender, address(this), _diamondAsset[i].tokenId[0], _diamondAsset[i].data);

            }
            else if(_diamondAsset[i].tokenType == assetType.ERC1155) {
                for(uint256 j; j < _diamondAsset[i].tokenId.length; j++){
                    currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(_diamondAsset[i].contractAddress, _diamondAsset[i].tokenId[j]))] += _diamondAsset[i].quantity[j];
                }
                ERC1155Interface(_diamondAsset[i].contractAddress).safeBatchTransferFrom(msg.sender, address(this), _diamondAsset[i].tokenId, _diamondAsset[i].quantity, _diamondAsset[i].data);
            }
            else if (_diamondAsset[i].tokenType == assetType.ERC20){
                currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(_diamondAsset[i].contractAddress))] += _diamondAsset[i].quantity[0];
                IERC20(_diamondAsset[i].contractAddress).safeTransferFrom(msg.sender, address(this), _diamondAsset[i].quantity[0]);
            }
            else if (_diamondAsset[i].tokenType == assetType.ETH){
                if (needsPayment){
                    require(msg.value == getPrice() + _diamondAsset[i].quantity[0], "ETH amount mismatch");
                } else {
                    require(msg.value == _diamondAsset[i].quantity[0], "ETH amount mismatch");
                }
                currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetType.ETH))] += _diamondAsset[i].quantity[0];
                depositedETH += _diamondAsset[i].quantity[0];
            }
        }

        //Transfer payment (payment = msg value - any deposited ETH)
        (bool success, ) = factoryContractAddress.call{value: msg.value - depositedETH}("");
        require(success, "ETH payment failed");

        emit DiamondHandCreated(_diamondHands.id, block.timestamp, _diamondHands.releaseTime, _diamondHands.breakPrice, _diamondHands.status);
        diamondIds.increment();
    }

    /**
    * @notice Release all the assets inside a specific diamondHand order (matched by _diamondId) if unlock time has passed
    * @param _diamondId Corresponding ID for the diamond-hand order 
    */
    function releaseDiamond(uint _diamondId) external onlyVaultOwner{
        require(_diamondId < diamondIds.current(), "Invalid diamondId");
        diamondHands memory diamondHandOrder = getDiamondHand(_diamondId);
        require(diamondHandOrder.status == diamondStatus.Holding, "Asset no longer held");
        require(block.timestamp >= diamondHandOrder.releaseTime, "Asset not yet unlocked");

        //Update status
        diamondList[_diamondId].status = diamondStatus.Released;
        
        //Release all the assets in this diamondHandOrder
        uint256 numAssets = getDiamondStructSize(_diamondId);
        uint256 i;
        for (i = 0; i < numAssets; i++){
            diamondStruct memory assetToRelease = getDiamondStruct(_diamondId, i);
            if (assetToRelease.tokenType == assetType.ERC721) {
                currentlyDiamondHanding[keccak256(abi.encodePacked(assetToRelease.contractAddress, assetToRelease.tokenId[0]))] = false;
                ERC721Interface(assetToRelease.contractAddress).safeTransferFrom(address(this), msg.sender, assetToRelease.tokenId[0], assetToRelease.data);
            } else if (assetToRelease.tokenType == assetType.ERC1155) {
                for(uint256 j; j < assetToRelease.tokenId.length; j++){
                    currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetToRelease.contractAddress, assetToRelease.tokenId[j]))] -= assetToRelease.quantity[j];
                }
                ERC1155Interface(assetToRelease.contractAddress).safeBatchTransferFrom(address(this), msg.sender, assetToRelease.tokenId, assetToRelease.quantity, assetToRelease.data);
            } else if (assetToRelease.tokenType == assetType.ERC20) {
                currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetToRelease.contractAddress))] -= assetToRelease.quantity[0];
                IERC20(assetToRelease.contractAddress).safeTransfer(msg.sender, assetToRelease.quantity[0]);
            } else if (assetToRelease.tokenType == assetType.ETH) {
                currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetType.ETH))] -= assetToRelease.quantity[0];
                (bool success, ) = msg.sender.call{value: assetToRelease.quantity[0]}("");
                require(success, "ETH withdrawal failed");
            }
        }

        emit DiamondHandReleased(_diamondId, block.timestamp, diamondHandOrder.releaseTime, diamondHandOrder.breakPrice, diamondStatus.Released);
    }

    /**
    * @notice Use emergency break to forcibly unlock (needs to pay what was specified by vaultOwner upon locking the asset)
    * @param _diamondId Corresponding ID for the diamond-hand order 
    */
    function breakUnlock(uint _diamondId) payable external onlyVaultOwner{
        require(_diamondId < diamondIds.current(), "Invalid diamondId");
        diamondHands memory diamondHandOrder = getDiamondHand(_diamondId);
        require(diamondHandOrder.status == diamondStatus.Holding, "Asset no longer held");
        require(msg.value == diamondHandOrder.breakPrice, "Incorrect ETH amount");
        
        //Update status
        diamondList[_diamondId].status = diamondStatus.Broken;
        
         //Release all the assets in this diamondHandOrder
        uint256 numAssets = getDiamondStructSize(_diamondId);
        uint256 i;
        for (i = 0; i < numAssets; i++){
            diamondStruct memory assetToRelease = getDiamondStruct(_diamondId, i);
            if (assetToRelease.tokenType == assetType.ERC721) {
                currentlyDiamondHanding[keccak256(abi.encodePacked(assetToRelease.contractAddress, assetToRelease.tokenId[0]))] = false;
                ERC721Interface(assetToRelease.contractAddress).safeTransferFrom(address(this), msg.sender, assetToRelease.tokenId[0], assetToRelease.data);
            } else if (assetToRelease.tokenType == assetType.ERC1155) {
                for(uint256 j; j < assetToRelease.tokenId.length; j++){
                    currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetToRelease.contractAddress, assetToRelease.tokenId[j]))] -= assetToRelease.quantity[j];
                }
                ERC1155Interface(assetToRelease.contractAddress).safeBatchTransferFrom(address(this), msg.sender, assetToRelease.tokenId, assetToRelease.quantity, assetToRelease.data);
            } else if (assetToRelease.tokenType == assetType.ERC20) {
                currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetToRelease.contractAddress))] -= assetToRelease.quantity[0];
                IERC20(assetToRelease.contractAddress).safeTransfer(msg.sender, assetToRelease.quantity[0]);
            } else if (assetToRelease.tokenType == assetType.ETH) {
                currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetType.ETH))] -= assetToRelease.quantity[0];
                (bool success, ) = msg.sender.call{value: assetToRelease.quantity[0]}("");
                require(success, "ETH withdrawal failed");
            }
        }

        //Transfer value to factory
        (bool paymentSuccess, ) = factoryContractAddress.call{value: msg.value}("");
        require(paymentSuccess, "ETH payment failed");

        emit DiamondHandBroken(_diamondId, block.timestamp, diamondHandOrder.releaseTime, diamondHandOrder.breakPrice, diamondStatus.Broken);
    }


    /**CLAIMING AIRDROPS **/
    /// @notice withdraw an ERC721 token (not currently diamond-handing) from this contract
    /// @param _contractAddress the address of the NFT you are withdrawing
    /// @param _tokenId the ID of the NFT you are withdrawing
    function withdrawERC721(address _contractAddress, uint256 _tokenId) external onlyVaultOwner {
        require(!currentlyDiamondHanding[keccak256(abi.encodePacked(_contractAddress, _tokenId))], "Currently diamond-handing");
        ERC721Interface(_contractAddress).safeTransferFrom(address(this), msg.sender, _tokenId, "");
        emit WithdrawnERC721(_contractAddress, _tokenId);
    }

    /// @notice withdraw ERC1155 tokens (not currently diamond-handing) from this contract
    /// @param _contractAddress the address of the NFT you are withdrawing
    /// @param _tokenId the ID of the NFT you are withdrawing
    function withdrawERC1155(address _contractAddress, uint256 _tokenId) external onlyVaultOwner{
        require(ERC1155Interface(_contractAddress).balanceOf(address(this), _tokenId) > currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(_contractAddress, _tokenId))], "Currently diamond-handing");
        uint256 withdrawAmount = ERC1155Interface(_contractAddress).balanceOf(address(this), _tokenId) - currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(_contractAddress, _tokenId))];
        ERC1155Interface(_contractAddress).safeTransferFrom(address(this), msg.sender, _tokenId, withdrawAmount, "");
        emit WithdrawnERC1155(_contractAddress, _tokenId, withdrawAmount);
    }

    /// @notice withdraw ERC20 (not currently diamond-handing) from this contract
    function withdrawERC20(address _contractAddress) external onlyVaultOwner{
        require(IERC20(_contractAddress).balanceOf(address(this)) > currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(_contractAddress))], "No excess ERC20 to withdraw");
        uint256 withdrawAmount = IERC20(_contractAddress).balanceOf(address(this)) - currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(_contractAddress))]; 
        IERC20(_contractAddress).safeTransfer(msg.sender, withdrawAmount);

        emit WithdrawnERC20(_contractAddress, withdrawAmount);
    }

    /// @notice withdraw ETH (not currently diamond-handing) from this contract
    function withdrawETH() external onlyVaultOwner{
        require(address(this).balance > currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetType.ETH))], "No excess ETH to withdraw");
        uint256 withdrawAmount = address(this).balance - currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetType.ETH))];
        (bool success, ) = msg.sender.call{value: withdrawAmount}("");
        require(success, "ETH withdrawal failed");

        emit WithdrawnETH(withdrawAmount);
    }

    receive() external payable {
        emit ReceivedEther(msg.sender);
    }

    /** GETTING INFORMATION FROM FACTORY **/

    function getPrice() internal view returns(uint256) {
        return IFactory(factoryContractAddress).price();
    }
    function getMinBreakPrice() internal view returns(uint256) {
        return IFactory(factoryContractAddress).minBreakPrice();
    }
    function getDiamondPassAddress() internal view returns(address) {
        return IFactory(factoryContractAddress).DIAMONDPASS();
    }
    function checkDiamondSpecial(address _contractAddress, uint256 _tokenId) internal view returns(bool) {
        return IFactory(factoryContractAddress).checkDiamondSpecial(_contractAddress, _tokenId);
    }
    
    /** GETTERS **/
    /**
    * @dev Get the diamond-hand order given a diamondId
    * @param _diamondId diamondId to fetch diamondHand information for
    * @return diamondHands
    */
    function getDiamondHand(uint256 _diamondId) public view returns (diamondHands memory) {
        return diamondList[_diamondId];

    }

    /**
    * @dev Get all the diamondHand information of this vault
    * @return diamondHands[] All diamondHand information in this vault
    */
    function getDiamondList() public view returns (diamondHands[] memory) {
        require(diamondIds.current() > 0, "No diamondHand record");
        diamondHands[] memory allDiamondHands = new diamondHands[](diamondIds.current());
        for(uint256 i; i < diamondIds.current(); i++){
            allDiamondHands[i] = (getDiamondHand(i));
        }
        return allDiamondHands;
    }

    /**
    * @dev Get all the diamondStruct information of this vault
    * @return diamondStruct[][] All diamondstruct information in this vault
    */
    function getDiamondAssets() public view returns (diamondStruct[][] memory) {
        require(diamondIds.current() > 0, "No diamondHand record");
        diamondStruct[][] memory allDiamondStructs = new diamondStruct[][](diamondIds.current());
        for(uint256 i; i < diamondIds.current(); i++){
            uint256 size = getDiamondStructSize(i);
            diamondStruct[] memory currentStruct = new diamondStruct[](size);
            for (uint256 j; j < size; j++){
                currentStruct[j] = (getDiamondStruct(i, j));
            }
            allDiamondStructs[i] = currentStruct;
        }
        return allDiamondStructs;
    }
    
    /**
    * @dev Get length of diamondStruct by id
    * @param _diamondId Corresponding ID
    * @return uint256 number of assets being diamond-handed
    */
    function getDiamondStructSize(uint256 _diamondId) public view returns(uint256) {
        return diamondAssets[_diamondId].length;
    }

    /**
    * @dev Get diamondStruct by ID and index
    * @param _diamondId Corresponding ID
    * @param _index Corresponding index within the list of assets being diamondhanded in this order
    * @return diamondStruct with relevant information about the asset
    */
    function getDiamondStruct(uint256 _diamondId, uint256 _index) public view returns(diamondStruct memory) {
        return diamondAssets[_diamondId][_index] ;
    }
    
    /** SUPPORTS ERC721, ERC1155 **/
    function supportsInterface(bytes4 interfaceID) public view virtual override(ERC1155Receiver) returns (bool) {
        return  interfaceID == 0x01ffc9a7 || interfaceID == 0x4e2312e0;
    }
}
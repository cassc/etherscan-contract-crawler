// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./TokenBridgeRegistryUpgradeable.sol";
import "./BridgeUpgradeable.sol";
import "./FeePoolUpgradeable.sol";
import "./RegistryStorage.sol";
import "./BridgeStorage.sol";

contract BridgeUtilsUpgradeable is Initializable, OwnableUpgradeable, RegistryStorage, BridgeStorage {

    TokenBridgeRegistryUpgradeable public tokenBridgeRegistryUpgradeable;

    BridgeUpgradeable public bridgeUpgradeable;

    FeePoolUpgradeable public feePoolUpgradeable;

    function initialize(
        TokenBridgeRegistryUpgradeable _tokenBridgeRegistryUpgradeable, 
        BridgeUpgradeable _bridgeUpgradeable, 
        FeePoolUpgradeable _feePoolUpgradeable
    ) public initializer {
        __Ownable_init();
        tokenBridgeRegistryUpgradeable = _tokenBridgeRegistryUpgradeable;
        bridgeUpgradeable = _bridgeUpgradeable;
        feePoolUpgradeable = _feePoolUpgradeable;
    }

    function updateRegistryAddress(TokenBridgeRegistryUpgradeable _registryAddress) external onlyOwner {
        tokenBridgeRegistryUpgradeable = _registryAddress;
    }

    function updateBridgeAddress(BridgeUpgradeable _bridgeAddress) external onlyOwner {
        bridgeUpgradeable = _bridgeAddress;
    }
    
    function updateFeePoolAddress(FeePoolUpgradeable _feePoolAddress) external onlyOwner {
        feePoolUpgradeable = _feePoolAddress;
    }

    function getEpochLength(string calldata _tokenTicker) public view returns (uint256) {
        (
            ,
            ,
            ,
            uint256 epochLength,
            ,
            ,
            
        ) = tokenBridgeRegistryUpgradeable.tokenBridge(_tokenTicker);
        return epochLength;
    }

    function getStartBlockAndEpochLength(string calldata _tokenTicker) public view returns (uint256, uint256) {
        (
            ,
            ,
            uint256 startBlock,
            uint256 epochLength,
            ,
            ,
            
        ) = tokenBridgeRegistryUpgradeable.tokenBridge(_tokenTicker);
        return (startBlock, epochLength);
    } 

    function getTokenAddress(string calldata _tokenTicker) public view returns (address) {
        (
            ,
            ,
            address tokenAddress
        ) = tokenBridgeRegistryUpgradeable.bridgeTokenMetadata(_tokenTicker);
        return tokenAddress;
    }

    function getBridgeType(string calldata _tokenTicker) public view returns (uint8) {
        (
            uint8 bridgeType,
            ,
            ,
            ,
            ,
            ,
            
        ) = tokenBridgeRegistryUpgradeable.tokenBridge(_tokenTicker);
        return bridgeType;
    }

    function isTokenBridgeActive(string calldata _tokenTicker) public view returns (bool) {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            bool isActive
        ) = tokenBridgeRegistryUpgradeable.tokenBridge(_tokenTicker);
        return isActive;
    }

    function getFeeTypeAndFeeInBips(string calldata _tokenTicker) public view returns (uint8, uint256) {
        (
            ,
            ,
            ,
            ,
            FeeConfig memory fee,
            ,
            
        ) = tokenBridgeRegistryUpgradeable.tokenBridge(_tokenTicker);
        return (fee.feeType, fee.feeInBips);
    }

    function getNoOfDepositors(string calldata _tokenTicker) public view returns (uint256) {
        (
            ,
            ,
            ,
            ,
            ,
            uint256 noOfDepositors,
            
        ) = tokenBridgeRegistryUpgradeable.tokenBridge(_tokenTicker);
        return noOfDepositors;
    }



    function getUserTotalDeposit(
        string calldata tokenTicker,
        address account,
        uint256 index
    ) public view returns (uint256) {
        (
            uint256 depositedAmount,
            ,
            ,
            ,
            ,
            ,
            
        ) = bridgeUpgradeable.liquidityPosition(tokenTicker, account, index);
        return depositedAmount;
    }

    function getEpochTotalDepositors(
        string memory _tokenTicker,
        uint256 _epochIndex
    ) public view returns (uint256) {
        (
            ,
            ,
            ,
            ,
            uint256 noOfDepositors
        ) = bridgeUpgradeable.epochs(_tokenTicker, _epochIndex - 1);
        return noOfDepositors;
    } 

    function getEpochTotalFees(
        string memory _tokenTicker,
        uint256 _epochIndex
    ) public view returns (uint256) {
        (
            ,
            ,
            uint256 totalFeesCollected,
            ,
            
        ) = bridgeUpgradeable.epochs(_tokenTicker, _epochIndex-1);
        return totalFeesCollected;
    } 

    function getCurrentTransferIndexHash(
        string calldata _tokenTicker,
        address _userAddress,
        uint8 _fromChainId,
        uint8 _toChainId
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_tokenTicker, _userAddress, _fromChainId, _toChainId));
    }

    function getTransferMappingHash(
        string calldata _tokenTicker,
        address _userAddress,
        uint8 _fromChainId,
        uint8 _toChainId,
        uint256 _index
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_tokenTicker, _userAddress, _fromChainId, _toChainId, _index));
    }

}
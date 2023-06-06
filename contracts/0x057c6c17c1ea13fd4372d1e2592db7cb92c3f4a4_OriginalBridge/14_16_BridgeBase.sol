// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {NonblockingLzApp} from "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";

abstract contract BridgeBase is NonblockingLzApp,ReentrancyGuard{
    
    uint8 public constant PT_MINT = 0; 
    uint8 public constant PT_UNLOCK = 1;
    bool  public useCustomAdapterParams;

    event SetUseCustomAdapterParams(bool useCustomAdapterParams);
    
    constructor(address _endpoint)NonblockingLzApp(_endpoint){}
    
    function setUseCustomAdapterParams(bool _useCustomAdapterParams) external onlyOwner{
        useCustomAdapterParams = _useCustomAdapterParams;
        emit SetUseCustomAdapterParams(_useCustomAdapterParams);
    }
    
    function _checkAdapterParams(uint16 remoteId,uint8 pkType,bytes memory adapterParams)internal virtual {
        if (useCustomAdapterParams){
            _checkGasLimit(remoteId, pkType, adapterParams, 0);
        }else {
            require(adapterParams.length == 0,"BridgeBase:adapterParams must be empty");
        }
    }

    function renounceOwnership() public override onlyOwner {}
}
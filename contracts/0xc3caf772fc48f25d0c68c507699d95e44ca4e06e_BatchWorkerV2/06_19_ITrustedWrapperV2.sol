// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "IWrapper.sol";

interface ITrustedWrapperV2 is IWrapper  {

    function trustedOperator(address _operator) external view returns(bool);    
    
    function wrapUnsafe(
        ETypes.INData calldata _inData, 
        ETypes.AssetItem[] calldata _collateral, 
        address _wrappFor
    ) 
        external
        payable
        returns (ETypes.AssetItem memory); 

    function transferIn(
        ETypes.AssetItem memory _assetItem,
        address _from
    ) 
        external
        payable  
    returns (uint256 _transferedValue);
   
}
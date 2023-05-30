// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./IWitnetBytecodes.sol";
import "../../requests/WitnetRequest.sol";

interface IWitnetRequestFactory {
    
    event WitnetRequestBuilt(WitnetRequest request);
    event WitnetRequestTemplateBuilt(WitnetRequestTemplate template, bool parameterized);
    
    function buildRequest(
            bytes32[] memory sourcesIds,
            bytes32 aggregatorId,
            bytes32 tallyId,
            uint16  resultDataMaxSize
        ) external returns (WitnetRequest request);
    
    function buildRequestTemplate(
            bytes32[] memory sourcesIds,
            bytes32 aggregatorId,
            bytes32 tallyId,
            uint16  resultDataMaxSize
        ) external returns (WitnetRequestTemplate template);
    
    function class() external view returns (bytes4);    
    function registry() external view returns (IWitnetBytecodes);

}
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";

interface IOracle is IComponent {
    
    event LogOracleCreated (address oracleAddress);
    event LogOracleProposed (uint256 componentId);
    event LogOracleApproved (uint256 componentId);
    event LogOracleDeclined (uint256 componentId);
    
    function request(uint256 requestId, bytes calldata input) external;
    function cancel(uint256 requestId) external;
}
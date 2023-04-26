// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";

interface IProduct is IComponent {

    event LogProductCreated (address productAddress);
    event LogProductProposed (uint256 componentId);
    event LogProductApproved (uint256 componentId);
    event LogProductDeclined (uint256 componentId);

    function getToken() external view returns(address token);
    function getPolicyFlow() external view returns(address policyFlow);
    function getRiskpoolId() external view returns(uint256 riskpoolId);

    function getApplicationDataStructure() external view returns(string memory dataStructure);
    function getClaimDataStructure() external view returns(string memory dataStructure);
    function getPayoutDataStructure() external view returns(string memory dataStructure);

    function riskPoolCapacityCallback(uint256 capacity) external;
}
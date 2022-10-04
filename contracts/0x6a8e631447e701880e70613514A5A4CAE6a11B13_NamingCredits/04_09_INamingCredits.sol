// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface INamingCredits {
    function credits(address sender) external view returns (uint256);
    function reduceNamingCredits(address sender, uint256 numberOfCredits) external;
    function assignNamingCredits(address user, uint256 numberOfCredits) external;
    function shutOffAssignments() external;
    function shutOffAssignerAssignments() external;
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external;
}
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICrossChainGovernable {
    /**
     * @param pendingGovernor The new pending governor address.
     * @param pendingGovernorChainSelector The chain selector of the new pending governor.
     * @notice A call to transfer governance is required to promote the new pending governor to the governor role.
     */
    function setPendingGovernor(address pendingGovernor, uint64 pendingGovernorChainSelector) external;

    /**
     * @param intervalCommunicationLost The new interval after which, if no message has been received, the communication with the base portal is assumed lost.
     */
    function setIntervalCommunicationLost(uint32 intervalCommunicationLost) external;

    /**
     * @notice Promote the pending governor to the governor role.
     */
    function transferGovernance() external;

    function getGovernor() external view returns (address);

    function getGovernorChainSelector() external view returns (uint64);

    function getPendingGovernor() external view returns (address);

    function getPendingGovernorChainSelector() external view returns (uint64);

    function getGovTransferReqTimestamp() external view returns (uint64);
}
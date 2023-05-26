// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "../utils/MetaPtr.sol";

interface IRoundImplementation {
    struct ApplicationStatus {
        uint256 index;
        uint256 statusRow;
    }

    function initialize(
        bytes calldata encodedParameters,
        address _alloSettings
    ) external;

    function updateMatchAmount(uint256 newAmount) external;

    function updateRoundFeePercentage(uint32 newFeePercentage) external;

    function updateRoundFeeAddress(address payable newFeeAddress) external;

    function updateRoundMetaPtr(MetaPtr memory newRoundMetaPtr) external;

    function updateApplicationMetaPtr(
        MetaPtr memory newApplicationMetaPtr
    ) external;

    function updateStartAndEndTimes(
        uint256 newApplicationsStartTime,
        uint256 newApplicationsEndTime,
        uint256 newRoundStartTime,
        uint256 newRoundEndTime
    ) external;

    function applyToRound(
        bytes32 projectID,
        MetaPtr calldata newApplicationMetaPtr
    ) external;

    function getApplicationIndexesByProjectID(
        bytes32 projectID
    ) external view returns (uint256[] memory);

    function setApplicationStatuses(
        ApplicationStatus[] memory statuses
    ) external;

    function getApplicationStatus(
        uint256 applicationIndex
    ) external view returns (uint256);

    function vote(bytes[] memory encodedVotes) external payable;

    function setReadyForPayout() external payable;

    function withdraw(address tokenAddress, address payable recipent) external;
}
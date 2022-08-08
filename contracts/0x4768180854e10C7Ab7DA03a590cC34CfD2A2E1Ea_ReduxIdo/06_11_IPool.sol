// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

interface IPool {
    struct PoolModel {
        uint256 hardCap; // how much project wants to raise
        uint256 startDateTime;
        uint256 endDateTime;
        PoolStatus status; //: by default “Upcoming”,
    }

    struct IDOInfo {
        address investmentTokenAddress; //the address of the token in which project will raise funds
        uint256 minAllocationPerUser;
        uint256 maxAllocationPerUser;
    }

    // Pool data that needs to be retrieved:
    struct CompletePoolDetails {
        Participations participationDetails;
        PoolModel pool;
        IDOInfo poolDetails;
        uint256 totalRaised;
    }

    struct Participations {
        ParticipantDetails[] investorsDetails;
        uint256 count;
    }

    struct ParticipantDetails {
        address addressOfParticipant;
        uint256 totalRaisedAmount;
    }

    enum PoolStatus {
        Upcoming,
        Ongoing,
        Finished,
        Paused,
        Cancelled
    }

    function addIDOInfo(IDOInfo memory _detailedPoolInfo) external;

    function getCompletePoolDetails()
        external
        view
        returns (CompletePoolDetails memory poolDetails);

    function getInvestmentTokenAddress()
        external
        view
        returns (address investmentTokenAddress);

    function updatePoolStatus(uint256 _newStatus) external;

    function deposit(address _sender, uint256 _amount) external;
}
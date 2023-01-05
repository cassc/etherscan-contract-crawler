// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRental {
    struct LandLords {
        address owner;
        uint256[] landId;
        uint256 lordId;
        uint256[] LandCatorgy;
        uint256 LordCatorgy;
        uint256 lastClaimTime;
        uint256 currentPoolId;
        uint256 totalLandWeight;
        bool status;
    }

    struct Pool {
        uint256 poolTimeSlot;
        uint256 poolRoyalty;
        uint256[] poolTotalWeight;
        uint256 poolMonth;
        uint256 poolStartTime;
        uint256 poolEndTime;
    }

    struct Deposite {
        uint256[] _landId;
        uint256 _lordId;
        uint256[] _landCatorgy;
        uint256 _lordCatory;
    }

    struct corrdinate {
        uint256[] land1;
        uint256[] land2;
        uint256[] land3;
    }

    event Blacklisted(address account, bool value);
    event DepositeLandLord(
        address owner,
        uint256 _rewardId,
        uint256[] landId,
        uint256 lordId,
        uint256[] landCatorgy,
        uint256 lordCatory
    );
    event Pausable(bool state);
    event UpdateOwner(address oldOwner, address newOwner);
    event UpdateLandContract(address newContract, address oldContract);
    event UpdateLordContract(address newContract, address oldContract);
    event WithdrawLandLord(
        address owner,
        uint256 _rewardId,
        uint256[] landId,
        uint256 lordId
    );
}
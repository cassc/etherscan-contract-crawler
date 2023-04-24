// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IPiggyBankDefination {
    struct SeasonInfo {
        uint256 totalAmount;
        bytes32 stopedHash;
        address verifySigner; // Used for verification the next time stop is called
        uint32 startTime;
        bool stoped;
    }

    struct RoundInfo {
        uint256 totalAmount;
        uint256 target;
        uint32 currentIndex;
        uint32 startTime;
    }

    struct UserInfo {
        uint256 amount;
        uint256 claimedAmount;
    }

    event InitializeSeason(
        uint256 season,
        uint32 seasonStartTime,
        RoundInfo roundInfo
    );
    event SetNewMultiple(uint8 multiple);
    event SetMinTimeLong(uint64 minTimeLong);
    event NewSeason(uint256 season, uint256 startTime);
    event Deposit(
        uint256 season,
        address account,
        uint256 roundIndex,
        uint256 amount,
        uint256 roundTotalAmount
    );
    event SeasonStoped(uint256 season, uint256 stopTime);
    event SignerUpdate(address indexed signer, bool valid);
    event SetStopedHash(
        uint256 season,
        bytes32 stopedHash,
        address verifySigner
    );
    event ClaimedReward(uint256 season, address account, uint256 amount);

    error CallerNotPortal();
    error InvalidRoundInfo();
    error SeasonOver();
    error InvalidSeason();
    error AlreadyClaimed();
    error SeasonNotOver();
}

interface IPiggyBank is IPiggyBankDefination {
    function deposit(
        uint256 season,
        address account,
        uint256 income
    ) external payable;

    function setMultiple(uint8 multiple_) external;

    function setMinTimeLong(uint64 minTimeLong_) external;

    function checkIsSeasonEnd(uint256 season) external view returns (bool);

    function newSeason(uint256 season, uint256 startTime) external;

    function setSeasonStopedHash(
        uint256 season,
        bytes32 stopedHash,
        address verifySigner
    ) external;

    function stop(uint256 season) external;
}
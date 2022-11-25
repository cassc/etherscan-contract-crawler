pragma solidity ^0.8.0;

interface IMarket {
    struct TeamData {
        uint256 id;
        uint256 liquidReserved;
        uint256 liquid;
        uint256 shares;
        uint256 strength;
        bool pause;
        bool eliminated;
        uint256 groupId;
    }

    struct InitData {
        uint256 teamCount;
        uint256 startTime;
        uint256 openTime;
        uint256 initShares;
        address acceptedToken;
        uint256 refPrice;
        uint256 eventFee;
        uint256 prizeFee;
        uint256 sellTax;
        uint256[] strengthData;
    }

    function getAllPositions(address user)
        external
        view
        returns (uint256[] memory);

    function getAllTeam() external view returns (TeamData[] memory);

    function setInitData(InitData calldata _initData) external;
}
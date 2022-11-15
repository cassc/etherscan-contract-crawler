// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Iinvite {
    function checkInviter(address) external view returns (address);

    function checkTeam(address user_) external view returns (address[] memory);

    function checkTeamLength(address user_) external view returns (uint);

    function checkInviterOrign(address addr_) external view returns (address);

    function whoIsYourInviter(address, address) external returns (bool);
}

interface IPreSale {
    function preSaleTeam(address) external view returns (address[] memory);

    function checkTeamLength(address user_) external view returns (uint);

    function checkNftBouns(address) external view returns (uint, uint);

    function calculate(address user_) external view returns (uint);

    function userInfo(address)
        external
        view
        returns (
            bool isPreSale,
            uint amount,
            uint toClaim,
            uint lastClaimedTime,
            uint claimed
        );

    function checkPreSaleInfo()
        external
        view
        returns (
            uint,
            uint,
            uint,
            uint
        );

    function checkPreSaleReceived()
        external
        view
        returns (
            uint,
            uint,
            uint,
            uint
        );
}

interface Iido {
    function checkTeamLength(address user_) external view returns (uint);

    function checkNftBouns(address user_)
        external
        view
        returns (uint limit, uint minted);

    function mutiCheck(address user_)
        external
        view
        returns (
            uint[4] memory list,
            bool[2] memory b,
            uint[2] memory idoTime
        );
}

interface IMPOT {
    function checkPhase() external view returns (uint);

    function checkPhaseStatus() external view returns (bool);

    function buyTBonusInfo(uint)
        external
        view
        returns (
            bool,
            uint,
            uint,
            uint,
            uint
        );

    function checkPhaseUserBonus(uint phase_, address user_)
        external
        view
        returns (uint);

    function setBuyTokensBonusPhaseStatus(bool b_) external;
}

interface IbuyTokenBonus {
    function setThisRoundBonus(uint bonus_) external;

    function setLowestHold(uint lowestHold_) external;
}
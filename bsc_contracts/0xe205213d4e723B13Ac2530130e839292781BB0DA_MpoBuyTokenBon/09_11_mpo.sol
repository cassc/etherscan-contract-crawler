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

    function isidoClaimed(address) external view returns (bool);
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

    function absolutePrice() external returns (uint);

    function checkPhaseBuyAmountTotal(uint phase_, address user_)
        external
        view
        returns (uint);
}

interface IbuyTokenBonus {
    function f_userInfo(uint, address) external view returns (uint, uint);

    function finance_checktoClaimBonus(address user_)
        external
        view
        returns (uint aa);

    function f_thisRoundClaimed() external view returns (uint);

    function setThisRoundBonus(uint bonus_) external;

    function setLowestHold(uint lowestHold_) external;
}

interface InftFinance {
    function USDT() external view returns (address);

    function BuyBoxCostToken() external view returns (address);

    function distribute(uint amount_) external;

    function userNftRewardClaimed(address) external view returns (uint);

    function calculateUserReward(address user_) external view returns (uint re);

    function nftDistribute()
        external
        view
        returns (
            uint,
            uint,
            uint,
            uint
        );

    function boxPrice() external view returns (uint);

    function openedBox() external view returns (uint);

    function costUsdtProportion() external view returns (uint);

    function boxInfo()
        external
        view
        returns (
            uint,
            uint,
            uint,
            uint
        );
}

interface INfts {
    function cardInfoes(uint)
        external
        view
        returns (
            uint,
            uint,
            uint,
            uint,
            string memory
        );

    function tokenOfOwnerForAll(address addr_)
        external
        view
        returns (uint[] memory, uint[] memory);

    function tokenURI(uint) external view returns (string memory);

    function getNowTokenId() external view returns (uint);

    function batchTokenURI(address) external view returns (string[] memory);
}
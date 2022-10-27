// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICOW {
    function getGender(uint tokenId_) external view returns (uint);

    function getEnergy(uint tokenId_) external view returns (uint);

    function getAdult(uint tokenId_) external view returns (bool);

    function getAttack(uint tokenId_) external view returns (uint);

    function getStamina(uint tokenId_) external view returns (uint);

    function getDefense(uint tokenId_) external view returns (uint);

    function getPower(uint tokenId_) external view returns (uint);

    function getLife(uint tokenId_) external view returns (uint);

    function getBronTime(uint tokenId_) external view returns (uint);

    function getGrowth(uint tokenId_) external view returns (uint);

    function getMilk(uint tokenId_) external view returns (uint);

    function getMilkRate(uint tokenId_) external view returns (uint);

    function getCowParents(uint tokenId_) external view returns (uint[2] memory);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function mintNormall(address player, uint[2] memory parents) external;

    function mint(address player) external;

    function setApprovalForAll(address operator, bool approved) external;

    function growUp(uint tokenId_) external;

    function isCreation(uint tokenId_) external view returns (bool);

    function burn(uint tokenId_) external returns (bool);

    function deadTime(uint tokenId_) external view returns (uint);

    function addDeadTime(uint tokenId, uint time_) external;

    function checkUserCowListType(address player, bool creation_) external view returns (uint[] memory);

    function checkUserCowList(address player) external view returns (uint[] memory);

    function getStar(uint tokenId_) external view returns (uint);

    function mintNormallWithParents(address player) external;

    function currentId() external view returns (uint);

    function upGradeStar(uint tokenId) external;

    function starLimit(uint stars) external view returns (uint);

    function creationIndex(uint tokenId) external view returns (uint);

    function mintNormalAdultWithoutParents(address player) external;
}

interface IBOX {
    function mint(address player, uint[2] memory parents_) external;

    function burn(uint tokenId_) external returns (bool);

    function checkParents(uint tokenId_) external view returns (uint[2] memory);

    function checkGrow(uint tokenId_) external view returns (uint[2] memory);

    function checkLife(uint tokenId_) external view returns (uint[2] memory);

    function checkEnergy(uint tokenId_) external view returns (uint[2] memory);
}

interface IStable {
    function isStable(uint tokenId) external view returns (bool);

    function rewardRate(uint level) external view returns (uint);

    function isUsing(uint tokenId) external view returns (bool);

    function changeUsing(uint tokenId, bool com_) external;

    function CattleOwner(uint tokenId) external view returns (address);

    function getStableLevel(address addr_) external view returns (uint);

    function energy(uint tokenId) external view returns (uint);

    function grow(uint tokenId) external view returns (uint);

    function costEnergy(uint tokenId, uint amount) external;

    function addStableExp(address addr, uint amount) external;

    function userInfo(address addr) external view returns (uint, uint);

    function checkUserCows(address addr_) external view returns (uint[] memory);

    function growAmount(uint time_, uint tokenId) external view returns (uint);

    function refreshTime() external view returns (uint);

    function feeding(uint tokenId) external view returns (uint);

    function levelLimit(uint index) external view returns (uint);

    function compoundCattle(uint tokenId) external;

    function growAmountItem(uint times, uint tokenID) external view returns (uint);

    function useCattlePower(address addr, uint amount) external;
}

interface IMilk {
    function userInfo(address addr) external view returns (uint, uint);

}

interface IFight {
    function userInfo(address addr) external view returns (uint, uint);
}

interface IClaim {
    function userInfo(address addr) external view returns (bool, bool, bool, bool, bool);
}
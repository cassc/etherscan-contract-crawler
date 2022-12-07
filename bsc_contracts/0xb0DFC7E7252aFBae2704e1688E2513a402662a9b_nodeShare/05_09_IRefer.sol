// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

interface IRefer {
    function getUserLevel(address addr) external view returns (uint);

    function getUserRefer(address addr) external view returns (uint);

    function getUserLevelRefer(address addr, uint level) external view returns (uint);

    function bond(address addr, address invitor, uint amount, uint stakeAmount) external;

    function checkUserInvitor(address addr) external view returns (address);

    function checkUserToClaim(address addr) external view returns (uint);

    function claimReward(address addr) external;

    function isRefer(address addr) external view returns (bool);

    function setIsRefer(address addr, bool b) external;

    function updateReferList(address addr) external;

    function checkReferList(address addr) external view returns (address[] memory, uint[] memory, uint[] memory);
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IConfig {
    function getGlobalFrozenState() external view  returns (bool);

    function getFlashableState() external view  returns (bool);

    function getProtocolFee() external view  returns (int128);

    function getProtocolTreasury() external view  returns (address);

    function setGlobalFrozen(bool) external;

    function toggleGlobalGuarded () external;

    function setPoolGuarded (address, bool) external;

    function setGlobalGuardAmount (uint256) external;

    function setPoolCap (address, uint256) external;

    function setPoolGuardAmount (address, uint256) external;

    function isPoolGuarded (address) external view returns (bool);

    function getPoolGuardAmount (address) external view returns (uint256);

    function getPoolCap (address) external view returns (uint256);
    
    function setFlashable(bool) external;

    function updateProtocolTreasury(address) external;

    function updateProtocolFee(int128) external;

}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IVesting {
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function hfd() external view returns (address);

    function isStakingContract(address _address) external view returns (bool);

    function lockPeriod() external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function unlockDisabledUntil() external view returns (uint256);

    function vesting(address, uint256) external view returns (uint256 time, uint256 amount, bool claimed);

    function removeStakingContract(address _address) external;

    function grantRole(bytes32 role, address account) external;

    function removeStuckToken(address _address) external;

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function transfer(address to, uint256 amount) external returns (bool);

    function transferAdmin(address _newAdmin) external;

    function claimUserVesting(uint256 _id) external;

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function addStakingContract(address _address) external;

    function addVesting(address _wallet, uint256 _amount) external;

    function mint(address _wallet, uint256 _amount) external;

    function burn(address _wallet, uint256 _amount) external;
}
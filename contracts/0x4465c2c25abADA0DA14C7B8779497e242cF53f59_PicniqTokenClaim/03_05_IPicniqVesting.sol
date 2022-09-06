// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPicniqVesting {
    struct UserVest {
        uint8 length;
        uint64 endTime;
        uint256 amount;
        uint256 withdrawn;
    }

    function owner() external view returns (address);
    function SNACK() external view returns (address);
    function totalVested() external view returns (uint256);
    function vestedOfDetails(address account) external view returns (UserVest memory);
    function vestedOf(address account) external view returns (uint256);
    function unvest() external;
    function vestTokens(address account, uint256 amount, uint256 length) external;
}
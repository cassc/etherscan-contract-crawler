// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface IReferral {
    event Assign(address indexed account, address indexed referrer);

    function ASSIGN_ROLE() external pure returns (bytes32);

    function referrer(address account) external view returns (address);
    function assign(address account, address referrer_) external returns (bool success);

    function referrers(address account, uint256 depth) external view returns (address[] memory);
}
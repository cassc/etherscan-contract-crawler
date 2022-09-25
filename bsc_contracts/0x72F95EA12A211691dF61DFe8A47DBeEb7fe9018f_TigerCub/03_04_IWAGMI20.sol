// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.4;


/**
 * @dev Interface of the WAGMI20 standard
 */
interface IWAGMI20 {
    function quickRundown(address account) external view returns (uint256);
    function heBought(address account, uint256 amount) external;
    function heSold(address account, uint256 amount) external;
    function fundsAreSafu() external pure returns (bool);
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IProxyToken is IERC165 {
    function rebalanceFlag() external view returns (bool);

    function owner() external view returns (address);

    function token() external view returns (address);

    function setRebalanceFlag(bool value) external;

    function upgradeTo(address newToken) external;

    function transferOwnership(address newAdmin) external;

    function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    function deposit(uint256[] memory tokenAmounts, bytes memory params) external;

    function withdraw(uint256 lpAmount, bytes memory params) external;

    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}
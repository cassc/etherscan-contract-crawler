// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IXVIX {
    function maxSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address account, uint256 amount) external returns (bool);
    function toast(uint256 amount) external returns (bool);
    function rebase() external returns (bool);
}
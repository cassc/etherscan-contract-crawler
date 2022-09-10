// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ITOPIA {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}
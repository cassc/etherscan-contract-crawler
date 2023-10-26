// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
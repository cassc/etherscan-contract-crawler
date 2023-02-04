// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IgWETH {
    function mint() external payable;
    function mintTo(address account) external payable;
    function unwrap(uint256 amount) external;
}
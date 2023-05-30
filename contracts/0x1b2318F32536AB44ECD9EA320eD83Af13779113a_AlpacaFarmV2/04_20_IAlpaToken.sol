// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAlpaToken is IERC20 {
    function mint(address _to, uint256 _amount) external;
}
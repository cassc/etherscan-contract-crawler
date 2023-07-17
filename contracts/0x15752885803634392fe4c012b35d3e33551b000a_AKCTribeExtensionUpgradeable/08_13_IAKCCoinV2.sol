// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAKCCoinV2 is IERC20 {
    function mint(uint256 amount, address to) external;
    function burn(uint256 amount, address from) external;
}
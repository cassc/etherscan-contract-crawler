// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IUSDC is IERC20 {
    function isBlacklisted(address account_) external returns(bool);
}
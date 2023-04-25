// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INaivePegToken is IERC20 {
    function mint(address to_, uint256 amount_) external;

    function burnFrom(address account_, uint256 amount_) external;

    function originalToken() external returns (address);
}
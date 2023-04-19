// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IDEDToken is IERC20 {
    function claim(uint256 amount) external;

    function claimTo(uint256 amount, address recipient) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISaleToken is IERC20 {
    function currentRound() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function burnFrom(address account, uint256 amount) external;
}
//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITrueMultiFarm {
    function stake(IERC20 token, uint256 amount) external;
    function unstake(IERC20 token, uint256 amount) external;
    function claim(IERC20[] calldata tokens) external;
    function exit(IERC20[] calldata tokens) external;
}
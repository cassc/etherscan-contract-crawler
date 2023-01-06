// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISushiBar is IERC20 {
    function sushi() external view returns (IERC20);

    function enter(uint256 _amount) external;

    function leave(uint256 _share) external;
}
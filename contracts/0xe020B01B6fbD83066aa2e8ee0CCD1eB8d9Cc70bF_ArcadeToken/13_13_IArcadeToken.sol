// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IArcadeToken is IERC20 {
    function setMinter(address _newMinter) external;

    function mint(address _to, uint256 _amount) external;
}
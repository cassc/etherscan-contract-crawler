// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface iEGoldToken is IERC20 {

    function createSnapshot() external returns (uint256);

    function pauseToken() external returns (bool);

    function unpauseToken() external returns (bool);

    function burn(address _to, uint256 _value) external returns (bool);

    function freeze(address _to) external returns (bool);

    function unfreeze(address _to) external returns (bool);

    function isFrozen(address _to) external view  returns (bool);

}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMeritToken is IERC20, IERC20Permit {
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
}
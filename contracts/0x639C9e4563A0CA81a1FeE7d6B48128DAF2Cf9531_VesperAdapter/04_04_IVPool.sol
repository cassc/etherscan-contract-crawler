// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVPool is IERC20 {
    function token() external view returns (address _token);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _shares) external;
}
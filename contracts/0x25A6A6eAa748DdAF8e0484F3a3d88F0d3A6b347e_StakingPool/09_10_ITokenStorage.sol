// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenStorage {
    function charge(uint256 _amount) external;

    function charge(address _to, uint256 _amount) external;

    function allowance(address _spender) external view returns (uint256 balance);

    function getBalance() external view returns (uint256 balance);

    function token() external view returns (IERC20);
}
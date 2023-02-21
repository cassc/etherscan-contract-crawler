// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IYieldImplementation {
    function initialize(address _token) external;

    function exit(address _token) external;

    function invest(address _token, uint256 _amount) external;

    function withdraw(address _token, uint256 _amount) external;

    function farmExtra(address _token, address _to, bytes calldata _data) external returns (bytes memory);

    function investedAmount(address _token) external returns (uint256);
}
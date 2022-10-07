// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Project {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function ultimate_supply() external view returns (uint256);

    function price() external view returns (uint256);

    function access_token() external view returns (address);
}
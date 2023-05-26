// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAuthToken is IERC20 {
    function batchTransfer(
        address[] memory accounts,
        uint256[] memory amounts
    ) external;
}
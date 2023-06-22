// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Interface used for checking swaps and deposits
interface ApprovalInterface {
    function approveSwap(address recipient) external view returns (bool);
    function approveDeposit(address depositor, uint nDays) external view returns (bool);
}
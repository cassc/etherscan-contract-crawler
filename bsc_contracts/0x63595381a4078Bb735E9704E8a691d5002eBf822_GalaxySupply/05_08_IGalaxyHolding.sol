//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IGalaxyHolding {
    function takeLoan(address loanToken, uint256 amount) external;
    function loanPayment(address loanToken, address loanContract, uint256 amount) external;
}
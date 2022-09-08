/**
 * @title Interface Ops
 * @dev IOps contract
 *
 * @author - <MIDGARD TRUST>
 * for the Midgard Trust
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 * File: @openzeppelin/contracts/token/ERC20/IERC20.sol
 *
 **/

pragma solidity 0.6.12;

interface IOps {
    function gelato() external view returns (address payable);

    function getFeeDetails() external view returns (uint256, address);
}

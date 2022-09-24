// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// Solmate
import { ERC20 } from 'solmate/tokens/ERC20.sol';

abstract contract BEP20 is ERC20 {
	function getOwner() external view virtual returns (address);
}
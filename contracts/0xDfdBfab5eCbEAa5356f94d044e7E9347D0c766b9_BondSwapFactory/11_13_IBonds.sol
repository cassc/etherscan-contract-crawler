// SPDX-License-Identifier: UNLICENSED
// Created by DegenLabs https://bondswap.org

pragma solidity ^0.8.15;

import "../libs/BondInit.sol";

interface IBonds {
	function initialize(BondInit.BondContractConfig memory _conf) external;
}
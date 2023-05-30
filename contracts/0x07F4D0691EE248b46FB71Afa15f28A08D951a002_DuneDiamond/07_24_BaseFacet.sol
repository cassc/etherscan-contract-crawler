// SPDX-License-Identifier: UNLICENSED
// © 2022 [XXX]. All rights reserved.
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { AppStorage } from "../Structs.sol";
import "../Interfaces.sol";
import "../LibDiamond.sol";

/*
    @dev
    This contract is part of a diamond / facets implementation as described
    in EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535)
*/
contract BaseFacet is Ownable, Pausable, ReentrancyGuard {
	function getState()
		internal pure returns (AppStorage storage s)
	{
		return LibDiamond.appStorage();
	}
}
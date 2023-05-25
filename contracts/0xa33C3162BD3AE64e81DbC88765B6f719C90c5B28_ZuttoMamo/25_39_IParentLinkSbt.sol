// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import { IERC5192PL } from "./IERC5192PL.sol";

interface IParentLinkSbt is IERC5192PL {
	function exists(uint256 tokenId) external view returns (bool);
}
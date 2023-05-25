// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import { IERC721A } from "erc721a/contracts/interfaces/IERC721A.sol";
import { IERC5192PLTop } from "./IERC5192PLTop.sol";
import { IERC721Lockable } from "../base/ERC721AntiScam/lockable/IERC721Lockable.sol";

import { DataType } from "../lib/type/DataType.sol";

interface IZuttoMamo is IERC721A, IERC721Lockable, IERC5192PLTop {
	function getTokenLocation(uint256 _tokenId) external view returns (DataType.TokenLocation);

	function refreshMetadata(uint256 _tokenId) external;

	function refreshMetadata(uint256 _fromTokenId, uint256 _toTokenId) external;

	function birth(address _to, uint256 _amount) external;

	function birthWithSleeping(address _to, uint256 _amount) external;
}
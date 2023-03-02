//  SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./IRestriction.sol";

interface IRestrictionV2 is IRestriction {
	function untradeable(address _token, uint256 _tokenId) external;
	function unrestrict(address _token, uint256 _tokenId) external;
}
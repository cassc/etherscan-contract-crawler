// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ITK {
		function claim(address _recipient, uint256[] memory _claimIds) external;
		function claims(uint256) external view returns(bool);
}
// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
interface IXNFTBase is IERC1155
{
	function mint(address _to, uint256 _grade) external;
	function burn(uint256 _id, uint256 _amount) external;
	function get_grade(uint256 _id) external pure returns(uint256);
}
// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
interface IXNFT
{
	function mint(address _to, uint256 _id, uint256 _amount, uint16 _grade) external;
	function get_grade(uint256 _id) external pure returns(uint16);
	function burn(uint256 _amount) external;
	function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) external;
}
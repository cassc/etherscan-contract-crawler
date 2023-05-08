// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Interface
//---------------------------------------------------------
interface IXNFTBase
{
	function mint(address _to, uint256 _grade) external;
	function burn(uint256 _id, uint256 _amount) external;
	function get_grade(uint256 _id) external pure returns(uint256);
	function get_nft_id(uint256 _grade, uint256 _serial) external pure returns(uint256);
	function uri(uint256 _id) external view returns(string memory);
	function get_list(uint256 /*count*/) external view returns(uint256[] memory);
	function get_my_id_list() external view returns(uint256[] memory);
	function set_operator(address _new_address) external;
	function set_controller(address _new_address, bool _is_set) external;
}
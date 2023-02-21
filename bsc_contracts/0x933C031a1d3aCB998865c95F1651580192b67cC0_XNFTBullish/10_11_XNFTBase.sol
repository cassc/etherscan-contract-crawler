// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract XNFTBase is ERC1155, Ownable
{
	address public address_operator;
	mapping(uint256 => uint256) amount_info; // grade_e6 / mint amount

	// URI Format
	// https://ipfs.io/ipfs/CID/{id}.json
	// ipfs://bafybeidajqcl52q4jlk7dz3wzfj4f665x6mzdjer5abzeh4ib7p6dz6cme
	// https://dweb.link/ipfs/bafybeidajqcl52q4jlk7dz3wzfj4f665x6mzdjer5abzeh4ib7p6dz6cme/{id}.json
	// https://bafkreigdgroagua3ti2yfmzbntdf6r6fmeirb2qrcsbn5ek2di6mqpmb6a.ipfs.dweb.link/
	string internal uri_base_str = "https://dweb.link/ipfs/";
	string internal uri_param_str = "/{id}.json";

	string[] internal metadata_list;
	// OpenSea MetaData
	// {
	//   "description": "Friendly OpenSea Creature that enjoys long swims in the ocean.", 
	//   "external_url": "https://openseacreatures.io/3", 
	//   "image": "https://storage.googleapis.com/opensea-prod.appspot.com/puffs/3.png", 
	//   "name": "Dave Starbelly",
	//   "attributes": [ ... ]
	// }

	//---------------------------------------------------------------
	// Front-end connectors
	//---------------------------------------------------------------
	event SetOperatorCB(address indexed operator, address _new_address_operator, address _new_address);

	//---------------------------------------------------------------
	// Modifier
	//---------------------------------------------------------------
	modifier onlyOperator() { require(address_operator == msg.sender, "onlyOperator: caller is not the operator");	_; }

	//---------------------------------------------------------------
	// Setters
	//---------------------------------------------------------------
	function set_operator(address _new_address) public onlyOperator
	{
		require(_new_address != address(0), "set_operator: Wrong address");

		address_operator = _new_address;
		emit SetOperatorCB(msg.sender, address_operator, _new_address);
	}

	//---------------------------------------------------------------
	// External Method
	//---------------------------------------------------------------
	constructor(string memory CID) ERC1155(string.concat(string.concat(uri_base_str, CID), uri_param_str))
	{
		address_operator = msg.sender;
	}

	function mint(address _to, uint256 _grade) external onlyOperator
	{
		require(_grade > 1, "mint: wrong grade");

		uint256 grade_e6 = _grade * 1e6;
		require(amount_info[grade_e6] < 1e6, "mint: total mint limit exceed");

		uint256 nft_id = grade_e6 + amount_info[grade_e6];

		_mint(_to, nft_id, 1, "");

		amount_info[grade_e6] += 1;
	}
	
	function burn(uint256 _id, uint256 _amount) external onlyOperator
	{
		_burn(msg.sender, _id, _amount);
	}

	function get_grade(uint256 _id) public pure returns(uint256)
	{
		require(_id > 1e6, "get_grade: Wrong ID");
		return _id / 1e6;
	}

	function uri(uint256 _id) public view virtual override returns (string memory) {
    	return super.uri(get_grade(_id));
	}
}
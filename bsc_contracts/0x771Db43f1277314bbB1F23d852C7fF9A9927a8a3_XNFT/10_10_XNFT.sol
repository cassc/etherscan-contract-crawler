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
contract XNFT is ERC1155, Ownable
{
	uint256 public constant LEVEL_1 = 1000000;
	uint256 public constant LEVEL_2 = 2000000;
	uint256 public constant LEVEL_3 = 3000000;

	address public address_operator;
	
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
	constructor() ERC1155("ipfs://x10.farm/xnft/{id}.json")
	{
		address_operator = msg.sender;
	}

	function mint(address _to, uint256 _id, uint256 _amount, uint16 _grade) external onlyOperator
	{
		require(_grade >= 1 && _grade <= 3, "mint: Wrong NFT grade");
		require(_id < LEVEL_1, "mint: Wrong NFT ID");
		require(_amount == 1, "mint: Minting amount always should be 1.");

		uint256 mint_id = (_grade * 1e6) + _id;
		_mint(_to, mint_id, 1, "");
	}
	
	function burn(uint256 _id, uint256 _amount) external onlyOperator
	{
		super._burn(msg.sender, _id, _amount);
	}

	function safeTransferFrom(address _from, address _to, uint256 _id, 
		uint256 _amount, bytes memory _data) public override
	{
		super.safeTransferFrom(_from, _to, _id, _amount, _data);
	}

	function get_grade(uint256 _id) external pure returns(uint16)
	{
		require(_id > LEVEL_1, "get_grade: Wrong ID");

		if(_id < LEVEL_2) return 1;
		else if(_id < LEVEL_3) return 2;
		else return 3;
	}
}
// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract HypeToon is ERC20, Ownable
{
	using SafeERC20 for IERC20;

	uint256 public constant TOTAL_SUPPLY_LIMIT = 2000000000000000000000000000;

	//---------------------------------------------------------------
	// Events
	//---------------------------------------------------------------
	event Mint(address indexed to, uint256 amount);
	event Burn(address indexed from, uint256 amount);

	//---------------------------------------------------------------
	// External Method
	//---------------------------------------------------------------
	constructor(address address_genesis_vault, uint256 mint_amount) ERC20("HypeToon: Decentralized Webtoon Content Platform run by DAO", "HYPE") Ownable()
	{
		require(address_genesis_vault != address(0), "constructor: Wrong vault address");
		mint(address_genesis_vault, mint_amount);
	}

	function mint(address _to, uint256 _amount) public onlyOwner
	{
		require(totalSupply()+_amount <= TOTAL_SUPPLY_LIMIT, "mint: limit exceed");
		super._mint(_to, _amount);
		emit Mint(_to, _amount);
	}

	function burn(uint256 _amount) external onlyOwner
	{
		super._burn(msg.sender, _amount);
		emit Burn(msg.sender, _amount);
	}
}
// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract HypeToon is ERC20
{
	uint256 public constant TOTAL_SUPPLY_LIMIT = 2000000000000000000000000000; // Wei
	address public constant GENESIS_VAULT_ADDRESS = 0x11FFc5bA95377eA1aFb7a8f62Ee394d91371Bd63; // Safe Multi-Sig Vault

	//---------------------------------------------------------------
	// Events
	//---------------------------------------------------------------
	event Mint(address indexed to, uint256 amount);

	//---------------------------------------------------------------
	// External Method
	//---------------------------------------------------------------
	constructor() ERC20("Hypetoon", "HYPE")
	{
		mint(GENESIS_VAULT_ADDRESS, TOTAL_SUPPLY_LIMIT);
	}

	//---------------------------------------------------------------
	// Internal Method
	//---------------------------------------------------------------
	function mint(address _to, uint256 _amount) private
	{
		require(totalSupply()+_amount <= TOTAL_SUPPLY_LIMIT, "mint: limit exceed");
		super._mint(_to, _amount);
		emit Mint(_to, _amount);
	}
}
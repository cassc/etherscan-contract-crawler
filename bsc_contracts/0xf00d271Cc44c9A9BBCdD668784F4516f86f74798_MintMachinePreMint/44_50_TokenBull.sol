// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract TokenBull is ERC20
{
	constructor(address _address_vault, uint256 _initial_mint_amount) ERC20("BULL on xTEN", "BULL")
	{
		_mint(_address_vault, _initial_mint_amount);
	}
}
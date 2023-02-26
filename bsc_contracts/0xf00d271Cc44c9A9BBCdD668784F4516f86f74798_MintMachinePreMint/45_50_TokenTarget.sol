// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "./TokenXBaseV3.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract TokenTarget is TokenXBaseV3
{
	constructor(address _address_vault, uint256 _initial_mint_amount) TokenXBaseV3("TARGET on xTEN", "TokenTarget")
	{
		tax_rate_send_e6 = 100000; // 10%
		tax_rate_recv_e6 = 50000; // 5%

		_mint(_address_vault, _initial_mint_amount);
	}
}
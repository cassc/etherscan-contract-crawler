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
	constructor(address arrow_vault, uint256 initial_mint_amount) TokenXBaseV3("TARGET on xTEN farm", "TGET")
	{
		tax_rate_send_e4 = 1000; // 10%
		tax_rate_recv_e4 = 500; // 5%

		_mint(arrow_vault, initial_mint_amount);
	}
}
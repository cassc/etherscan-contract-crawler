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
	constructor() TokenXBaseV3("TARGET on xTEN farm", "TGET")
	{
		tax_rate_send_e4 = 1000; // 10%
		tax_rate_recv_e4 = 500; // 5%

		super._mint(msg.sender, 10000 * (10 ** 18));
	}
}
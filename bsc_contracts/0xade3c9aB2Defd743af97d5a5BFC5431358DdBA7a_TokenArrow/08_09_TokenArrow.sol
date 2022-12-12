// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "./TokenXBaseV3.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract TokenArrow is TokenXBaseV3
{
	constructor() TokenXBaseV3("ARROW on xTEN farm", "AROW")
	{
		tax_rate_send_e4 = 1000; // 10%
		tax_rate_recv_e4 = 200; // 2%

		super._mint(msg.sender, 40000 * (10 ** 18));
	}
}
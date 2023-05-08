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
	constructor(address _address_vault, uint256 _initial_mint_amount) TokenXBaseV3("ARROW on xTEN", "AROW")
	{
		tax_rate_send_e6 = 100000; // 10%
		tax_rate_send_with_nft_e6 = 50000; // 5%

		tax_rate_recv_e6 = 20000; // 2%
		tax_rate_recv_with_nft_e6 = 20000; // 2%

		_mint(_address_vault, _initial_mint_amount);
		set_tax_free(_address_vault, true);
	}
}
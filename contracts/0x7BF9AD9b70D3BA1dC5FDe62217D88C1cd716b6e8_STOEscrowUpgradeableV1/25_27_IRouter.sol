/// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title IRouter
/// @custom:security-contact [email protected]
interface IRouter {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) 	external;

	function swapExactETHForTokens(
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	)	external
        returns (uint[] memory amounts);
}
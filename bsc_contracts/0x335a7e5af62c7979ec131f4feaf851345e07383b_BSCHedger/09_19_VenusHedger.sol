// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import { ERC20 } from 'openzeppelin-contracts/token/ERC20/ERC20.sol';
import { Strings } from 'openzeppelin-contracts/utils/Strings.sol';
// import { console } from 'forge-std/console.sol';

// https://github.com/VenusProtocol/venus-protocol/blob/develop/contracts/VToken.sol
// https://github.com/VenusProtocol/venus-protocol/blob/develop/contracts/Comptroller.sol

import { BSCHedgerBase } from './base/BSCHedgerBase.sol';
import { VBep20Interface, VTokenInterface } from './interfaces/Venus/VTokenInterfaces.sol';
import { EasyMath } from './library/EasyMath.sol';

contract BSCHedger is BSCHedgerBase {
	constructor(address _config) BSCHedgerBase(_config) {}

	/// @dev Deposit USDC directly as the collateral
	function depositCollateral(uint256 amount) public onlyOwner {
		USDC.transferFrom(msg.sender, address(this), amount);
		vUSDC.mint(amount);
	}

	/// @dev Hedge and gives negative delta
	/// @dev Slippage is multiplied by 10^4, e.g. 0.01% => 100 // 0.05% => 500
	function hedge(address vToken, uint256 amount, uint256 slippage, bool forceZeroMin)
		public
		onlyOwner
	{
		require(config.whitelist().isSupportedVToken(vToken), 'VToken not supported, support it first.');
		// Collateral check, param: USDC price of vToken (e.g. vETH)
		// decimal division:
		// - Oracle deicmals: 18
		// - vToken to USDC decimals: (vToken decimals - 18 USDC) = 0
		// ==> total: 18
		uint amountInUSDC = amount * oracle.getUnderlyingPrice(VTokenInterface(vToken)) / (10 ** (18));
		_manageCollateral(amountInUSDC);

		// Borrow succeed => returns 0
		// console.log("This vToken bal b: ", VBep20Interface(VBep20Interface(vToken).underlying()).balanceOf(address(this)));
		uint err = VBep20Interface(vToken).borrow(amount);
		require(err == 0, string.concat('Borrow failed with ', Strings.toString(err)));
		// console.log("This vToken bal a: ", VBep20Interface(VBep20Interface(vToken).underlying()).balanceOf(address(this)));

		// Swap borrowed token (underlying of vToken) to USDC to short it
		address[] memory path = new address[](2);
		path[0] = VBep20Interface(vToken).underlying();
		path[1] = address(USDC);
		// console.log(ERC20(VBep20Interface(vToken).underlying()).allowance(address(this), address(router)));
		// console.log(USDC.allowance(address(this), address(router)));
		// console.log(ERC20(VBep20Interface(vToken).underlying()).name());
		// console.log(amount);
		// console.log(amountInUSDC, EasyMath.amountLessSlippage(amountInUSDC, slippage));
		router.swapExactTokensForTokens(
			amount, // amountIn
			forceZeroMin ? 0 : EasyMath.amountLessSlippage(amountInUSDC, slippage), // amountOutMin
			path,
			address(this), // to
			block.timestamp + 60 // 60 seconds deadline
		);
		// console.log("This vToken bal a2: ", VBep20Interface(VBep20Interface(vToken).underlying()).balanceOf(address(this)));
	}

	/// @dev Pay back the hedge
	function payback(address vToken, uint256 amount)
		public
		onlyOwner
	{
		require(config.whitelist().isSupportedVToken(vToken), 'VToken not supported, support it first.');
		// VBep20Interface vuToken = VBep20Interface(VBep20Interface(vToken).underlying());
		// require(
		// 	vuToken.balanceOf(address(this)) >= amount,
		// 	'Insufficient vToken amount for repayment'
		// );
		require(VBep20Interface(vToken).repayBorrow(amount) == 0, 'Repay borrow failed');
	}

	function swapAndPayback(address vToken, uint256 amount, uint256 slippage, bool forceMaxMin)
		public
		onlyOwner
	{
		require(config.whitelist().isSupportedVToken(vToken), 'VToken not supported, support it first.');
		VBep20Interface vuToken = VBep20Interface(VBep20Interface(vToken).underlying()); // token underlying vToken

		if (address(vuToken) != address(USDC)) {
			// Swap USDC to vToken.underlying only if there's shortfall to repay `amount` of vToken.underlying
			if (amount > vuToken.balanceOf(address(this))) {
				uint price = oracle.getUnderlyingPrice(VTokenInterface(vToken));
				uint diff = amount - vuToken.balanceOf(address(this));
				uint inMax = EasyMath.amountMoreSlippage(diff * price / (10 ** 18), slippage);
				// uint buffered = EasyMath.amountMoreSlippage(diff, slippage); // << errors out without enough buffer amount in wallet
				// swapDirect(address(USDC), address(vuToken), amountInUSDC, slippage);

				address[] memory path = new address[](2);
				path[0] = address(USDC);
				path[1] = address(vuToken);
				// console.log("vUSDC bal: ", vUSDC.balanceOf(address(this)));
				// console.log("USDC bal: ", USDC.balanceOf(address(this)));
				// console.log("vuToken bal: ", vuToken.balanceOf(address(this)));
				// console.log("amount out", diff);
				// console.log("amount inMax", inMax);

				if (inMax > USDC.balanceOf(address(this))) {
					// Not enough USDC in wallet, so redeem just enough vUSDC (to USDC) to cover the difference
					uint buffer = EasyMath.amountMoreSlippage(inMax - USDC.balanceOf(address(this)), 1000); // 0.1%
					vUSDC.redeemUnderlying(buffer);
				}

				router.swapTokensForExactTokens(
					diff, // amountOut
					forceMaxMin ? type(uint).max : inMax, // amountInMax
					path,
					address(this), // to
					block.timestamp + 60 // 60 seconds deadline
				);
			}
		}

		payback(vToken, amount);
	}

	/// @dev
	/// @param amountUSDC amount to borrow, in USDC
	function _manageCollateral(uint256 amountUSDC) internal {
		// 1. Get how much available collateral
		// uint256 collateral = getVTokenValue(vUSDC, vUSDC.balanceOf(msg.sender));
		(uint err,uint availableCollateral,) = comptroller.getAccountLiquidity(address(this));
		require(err == 0, 'Error in getting account liquidity!');
		
		uint requiredCollateral = amountUSDC * 1e4 / config.LTV();
		// console.log("Hedge amount USDC: ", amountUSDC);
		// console.log("Available Collateral: ", availableCollateral);
		// console.log("Required Collateral: ", requiredCollateral);
		// console.log("Current USDC bal: ", USDC.balanceOf(msg.sender));
		// console.log("Allowance for USDC: ", USDC.allowance(msg.sender, address(this)));

		VTokenInterface[] memory tokens = comptroller.getAssetsIn(address(this));
		for (uint i = 0; i < tokens.length; i++) {
			VTokenInterface token = tokens[i];
			(, uint vTokenBalance, uint borrowBalance,) = token.getAccountSnapshot(address(this));
			// console.log("vToken: ", address(token));
			// console.log("vTokenBalance: ", vTokenBalance);
			// console.log("borrowBalance: ", borrowBalance);
		}

		// Not enough collateral, need to deposit collateral
		if (requiredCollateral > availableCollateral) {
			uint diff = requiredCollateral - availableCollateral;

			require(USDC.allowance(msg.sender, address(this)) >= diff, "Insufficient USDC allowance");
			require(USDC.balanceOf(msg.sender) >= diff, "Insufficient USDC to transfer");

			USDC.transferFrom(msg.sender, address(this), diff);
			// @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
			require(vUSDC.mint(diff) == 0, 'Mint failed');
			// console.log("vUSDC balance: ", ERC20(address(vUSDC)).balanceOf(msg.sender));
		}
	}

	/// @dev Close all hedges of all tokens and exit immediately
	function exitAll() public onlyOwner {
		// USDC.transfer(msg.sender, USDC.balanceOf(address(this)));
		// vUSDC.transfer(msg.sender, vUSDC.balanceOf(address(this)));
		VTokenInterface[] memory vtokens = comptroller.getAssetsIn(address(this));
		for (uint i = 0; i < vtokens.length; i++) {
			VTokenInterface vtoken = vtokens[i];
			(, uint vTokenBalance, uint borrowBalance,) = vtoken.getAccountSnapshot(address(this));
			// console.log("vToken: ", address(vtoken));
			// console.log("vTokenBalance: ", vTokenBalance);
			// console.log("borrowBalance: ", borrowBalance);
			if (borrowBalance > 0) {
				swapAndPayback(address(vtoken), borrowBalance, config.defaultSlippage(), false);
				VBep20Interface(address(vtoken)).redeemUnderlying(borrowBalance);
				(,vTokenBalance,,) = vtoken.getAccountSnapshot(address(this)); // update vTken balance
			}

			if (vTokenBalance > 0) {
				VBep20Interface(address(vtoken)).redeem(vTokenBalance);
				(,vTokenBalance,,) = vtoken.getAccountSnapshot(address(this)); // update vTken balance
				if (vTokenBalance > 0) VBep20Interface(address(vtoken)).redeemUnderlying(vTokenBalance);
				withdrawERC(VBep20Interface(address(vtoken)).underlying());
			}
		}
	}
}
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import { Strings } from 'openzeppelin-contracts/utils/Strings.sol';
import { Ownable } from 'openzeppelin-contracts/access/Ownable.sol';
import { EnumerableSet } from 'openzeppelin-contracts/utils/structs/EnumerableSet.sol';
// import { console } from 'forge-std/console.sol';

// https://github.com/VenusProtocol/venus-protocol/blob/develop/contracts/VToken.sol
// https://github.com/VenusProtocol/venus-protocol/blob/develop/contracts/Comptroller.sol

// import { EasyMath } from './library/EasyMath.sol';
import { PriceOracle } from './interfaces/Venus/PriceOracle.sol';
import { VBep20Interface, VTokenInterface } from './interfaces/Venus/VTokenInterfaces.sol';
import { ComptrollerInterface } from './interfaces/Venus/ComptrollerInterface.sol';
// import { IPancakeRouter01 } from './interfaces/Venus/PancakeStuff.sol';
import { IERC20Detailed } from './interfaces/tokens/IERC20Detailed.sol';
import { IParaSwapAugustus } from './external/paraswap/IParaSwapAugustus.sol';
import { Config } from './components/Config.sol';

contract VenusHedger is Ownable {
	using EnumerableSet for EnumerableSet.AddressSet;

	VBep20Interface constant internal vUSDC = VBep20Interface(0xecA88125a5ADbe82614ffC12D0DB554E2e2867C8);
	IERC20Detailed immutable internal USDC = IERC20Detailed(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d); // underlying of vUSDC

	IParaSwapAugustus public paraswap = IParaSwapAugustus(0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57); // proxy (don't need to approve this addr for tokens)

	address public paraswapTokenProxy; // token transfer proxy (need to approve this addr for tokens)

	ComptrollerInterface constant internal comptroller = ComptrollerInterface(0xfD36E2c2a6789Db23113685031d7F16329158384); // Unitroller proxy for comptroller

	PriceOracle constant internal oracle = PriceOracle(0xd8B6dA2bfEC71D684D3E2a2FC9492dDad5C3787F);

	Config public config;

	EnumerableSet.AddressSet private enabledVTokens;

	bool public initiated = false;

	modifier onlyEnabledVToken(address vToken) {
		require(isEnabledVToken(vToken), 'VToken not enabled for the contract.');
		_;
	}

	constructor(address _config, address _tokenTransferProxy) {
		config = Config(_config);
		paraswapTokenProxy = _tokenTransferProxy;

		// Manaully approve USDC in particular here
		USDC.approve(address(vUSDC), type(uint).max); // For minting vToken
		USDC.approve(address(paraswapTokenProxy), type(uint).max); // For swapping vToken
	}

	function initiate() public onlyOwner {
		// require(!initiated, 'Already initiated');
		initiated = true;

		address[] memory vTokens = new address[](3);
		// vTokens[0] = address(0xA07c5b74C9B40447a954e1466938b865b6BBea36); // vBNB
		// vTokens[1] = address(0x882C173bC7Ff3b7786CA16dfeD3DFFfb9Ee7847B); // vBTC
		vTokens[0] = address(0xf508fCD89b8bd15579dc79A6827cB4686A3592c8); // vETH
		vTokens[1] = address(0xecA88125a5ADbe82614ffC12D0DB554E2e2867C8); // vUSDC
		// vTokens[4] = address(0x5c9476FcD6a4F9a3654139721c949c2233bBbBc8); // vMATIC
		vTokens[2] = address(0x650b940a1033B8A1b1873f78730FcFC73ec11f1f); // vLINK
		// vTokens[0] = address(0x9A0AF7FDb2065Ce470D72664DE73cAE409dA28Ec); // vADA
		// vTokens[4] = address(0xfD5840Cd36d94D7229439859C0112a4185BC0255); // vUSDT
		// vTokens[7] = address(0x26DA28954763B92139ED49283625ceCAf52C6f94); // vAAVE
		// vTokens[8] = address(0x334b3eCB4DCa3593BCCC3c7EBD1A1C1d1780FBF1); // vDAI
		// vTokens[9] = address(0x1610bc33319e9398de5f57B33a5b184c806aD217); // vDOT
		// vTokens[10] = address(0x86aC3974e2BD0d60825230fa6F355fF11409df5c); // vCAKE
		// vTokens[12] = address(0x95c78222B3D6e262426483D42CfA53685A67Ab9D); // vBUSD
		// vTokens[13] = address(0x5F0388EBc2B94FA8E123F404b79cCF5f40b29176); // vBCH
		// vTokens[14] = address(0xec3422Ef92B2fb59e84c8B02Ba73F1fE84Ed8D71); // vDOGE
		// vTokens[15] = address(0xB248a295732e0225acd3337607cc01068e3b9c10); // vXRP
		// vTokens[16] = address(0xf91d58b5aE142DAcC749f58A49FCBac340Cb0343); // vFIL
		// vTokens[17] = address(0x57A5297F2cB2c0AaC9D554660acd6D385Ab50c6B); // vLTC

		enableVTokens(vTokens);
	}

	function setConfig(address _config) public onlyOwner {
		config = Config(_config);
	}

	function setParaSwap(address _augustus) public onlyOwner {
		paraswap = IParaSwapAugustus(_augustus);
		paraswapTokenProxy = paraswap.getTokenTransferProxy();
	}

	/// @dev Deposit USDC directly as the collateral
	function deposit(uint256 amount) public {
		// require(USDC.allowance(msg.sender, address(this)) >= amount, "Insufficient USDC allowance");
		// require(USDC.balanceOf(msg.sender) >= amount, "Insufficient USDC to transfer");
		USDC.transferFrom(msg.sender, address(this), amount);
		require(vUSDC.mint(amount) == 0, 'Mint failed'); // @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
	}

	/// @dev Just deposit USDC
	function depositOnlyUSDC(uint256 amount) public {
		USDC.transferFrom(msg.sender, address(this), amount);
	}

	function canHedge(
		address vToken,
		uint256 amount, // amount to short (borrow & swap)
		// add buffer to `amountUSDC` (ie. add a bit more collateral than needed, in case the executing block has slippage)
		// 0.01% => 1 // 0.1% => 10 // 1% => 100
		uint256 buffer
	)
		public
		view
		returns (bool possible, uint256 availableCollateral, uint256 shortfall)
	{
		// BUFFER: 0.1% (1001/1000)
		uint amountUSDC = amount * oracle.getUnderlyingPrice(VTokenInterface(vToken)) / (10 ** 18) * (10000 + buffer) / 10000;
		// Multiplication -- 10^4: LTV; 10^18: division precision holder ==> 10^22
		// Division -- 10^4: Rounding buffer; division precision holder ==> 10^22
		uint requiredCollateral = amountUSDC * 1e22 / config.LTV() / 1e18;
		// Multiplication -- 10^18: division precision holder ==> 10^18
		// Division -- 10^4: Rounding buffer; division precision holder ==> 10^22
		uint bufferedRequired = requiredCollateral * 1e18 * config.roundingBuffer() / 1e22;
		(,availableCollateral,) = getAccountLiquidity();
		// console.log('Hedge amount USDC: ', amountUSDC);
		// console.log('Available Collateral: ', availableCollateral);
		// console.log('Required Collateral: ', requiredCollateral);
		// console.log('Buffered required Collateral: ', bufferedRequired);

		// VTokenInterface[] memory tokens = comptroller.getAssetsIn(address(this));
		// for (uint i = 0; i < tokens.length; i++) {
		// 	VTokenInterface token = tokens[i];
		// 	(, uint vTokenBalance, uint borrowBalance,) = token.getAccountSnapshot(address(this));
		// 	console.log("vToken: ", address(token));
		// 	console.log("vTokenBalance: ", vTokenBalance);
		// 	console.log("borrowBalance: ", borrowBalance);
		// }

		// Not enough collateral, need to deposit collateral
		if (bufferedRequired > availableCollateral) {
			// possible = false;
			shortfall = requiredCollateral - availableCollateral;
		} else {
			possible = true;
		}
	}

	/// @dev Check if contract has enough USDC to pay back the hedge (swap USDC to vToken and repay)
	function canPayback(
    uint256 maxAmountToSwap // slippage dependent
	)
		public
		view
		returns (bool possible, uint256 shortfall)
	{
		uint beforeUSDC = USDC.balanceOf(address(this));
		// uint beforeVTokenInUSDC = vUSDC.exchangeRateStored() * vUSDC.balanceOf(address(this)) / 1e18;

		if (beforeUSDC < maxAmountToSwap) {
			// not enough baalnce to cover maxAmounToSwap for USDC
			// possible = false;
			shortfall = maxAmountToSwap - beforeUSDC;
			// if (beforeVTokenInUSDC > shortfall) {
			// 	redeem = true;
			// }
		} else {
			possible = true;
			// redeem = false;
		}
	}

	/// @dev Redeem vUSDC for USDC or deposit USDC if target is not met
	function redeemOrDeposit(uint256 target, uint256 buffer) public onlyOwner {
		// VBep20Interface vuToken = VBep20Interface(VBep20Interface(vToken).underlying()); // token underlying vToken
		uint beforeVTokenInUSDC = vUSDC.exchangeRateStored() * vUSDC.balanceOf(address(this)) / 1e18;

		if (beforeVTokenInUSDC > target) {
			uint err = vUSDC.redeemUnderlying(_amountMoreSlippage(target, buffer * 100));
			require(err == 0, string.concat('vUSDC redeem underlying failed with ', Strings.toString(err)));
		} else {
			require(USDC.balanceOf(msg.sender) > target, 'Not enough USDC allowance in caller to transfer');
			require(USDC.allowance(msg.sender, address(this)) > target, 'Not enough USDC allowance in caller to transfer');
			require(USDC.transferFrom(msg.sender, address(this), target),  'Failed USDC transfer to cover shortfall');
		}
		// uint err1 = vUSDC.redeemUnderlying(
		// 	_amountMoreSlippage(maxAmountToSwap - USDC.balanceOf(address(this)), 1000) // 0.1% extra buffer
		// );
		// require(err1 == 0, string.concat('vUSDC redeem underlying failed with ', Strings.toString(err1)));

		// uint256 balanceBeforeAssetFrom = assetToSwapFrom.balanceOf(address(this));
		// uint256 balanceBeforeAssetTo = assetToSwapTo.balanceOf(address(this));
		// if (balanceBeforeAssetFrom < maxAmountToSwap) {
		// 	// balance short fall for USDC
		// 	uint shortfall = maxAmountToSwap - balanceBeforeAssetFrom;

		// 	// Not enough USDC in wallet, so redeem just enough vUSDC (to USDC) to cover the difference
		// 	uint err1 = vUSDC.redeemUnderlying(
		// 		_amountMoreSlippage(maxAmountToSwap - USDC.balanceOf(address(this)), 1000) // 0.1% extra buffer
		// 	);
		// 	require(err1 == 0, string.concat('vUSDC redeem underlying failed with ', Strings.toString(err1)));

		// 	if (err1 != 0) {
		// 		// vUSDC redeem underlying failed, try transferring from wallet
		// 		require(assetToSwapFrom.balanceOf(msg.sender) > shortfall, 'Not enough USDC allowance in caller to transfer');
		// 		require(assetToSwapFrom.allowance(msg.sender, address(this)) > shortfall, 'Not enough USDC allowance in caller to transfer');
		// 		require(assetToSwapFrom.transferFrom(msg.sender, address(this), shortfall), 'Failed USDC transfer to cover shortfall');
		// 	}

		// 	balanceBeforeAssetFrom += assetToSwapFrom.balanceOf(address(this));
		// }
	}

	/// @dev Hedge and gives negative delta
	/// @dev Slippage is multiplied by 10^4, e.g. 0.01% => 100 // 0.05% => 500
	/// @dev From: https://github.com/aave/aave-v3-periphery/blob/master/contracts/adapters/paraswap/BaseParaSwapSellAdapter.sol#L42
	/// @dev ref: https://github.com/aave/aave-v3-periphery/blob/master/contracts/adapters/paraswap/BaseParaSwapBuyAdapter.sol#L40
	function hedge(
		address vToken,
		bytes memory swapCalldata,
		IParaSwapAugustus augustus,
    IERC20Detailed assetToSwapFrom, // example: ETH
    IERC20Detailed assetToSwapTo, // NOTE: Always should be USDC (collateral)
    uint256 amountToSwap, // always constant
    uint256 minAmountToReceive, // slippage dependent
		uint256 availableCollateral // (err, availableCollateral, shortfall) = getAccountLiquidity() // call outside to save gas
	)
		public
		// onlyEnabledVToken(vToken)
		onlyOwner
		returns (uint256 amountReceived)
	{
		// Collateral check, param: USDC price of vToken (e.g. vETH) // Oracle deicmals: 18
		uint amountInUSDC = amountToSwap * oracle.getUnderlyingPrice(VTokenInterface(vToken)) / (10 ** (18));
		// console.log('amountInUSDC', amountInUSDC);
		// console.log('availableCol', availableCollateral);
		require(availableCollateral >= amountInUSDC, 'Insufficient collateral');

		// Borrow succeed => returns 0
		// console.log("This vToken bal b: ", VBep20Interface(VBep20Interface(vToken).underlying()).balanceOf(address(this)));
		uint err = VBep20Interface(vToken).borrow(amountToSwap);
		require(err == 0, string.concat('Borrow failed with ', Strings.toString(err)));
		// console.log("This vToken bal a: ", VBep20Interface(VBep20Interface(vToken).underlying()).balanceOf(address(this)));

		//
		// ParaSwap
		//
		uint balanceBeforeAssetFrom = assetToSwapFrom.balanceOf(address(this));
    uint balanceBeforeAssetTo = assetToSwapTo.balanceOf(address(this));

		// Swap via ParaSwap
		(bool success, ) = address(augustus).call(swapCalldata);
    if (!success) {
      // Copy revert reason from call
			// console.log('unsuccessful swap');
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

		// After Swap checks
		// console.log('balanceBeforeAssetFrom:', balanceBeforeAssetFrom);
		// console.log('balanceBeforeAssetTo:', balanceBeforeAssetTo);
		// console.log('amountToSwap:', amountToSwap);
		// console.log('minAmountToReceive:', minAmountToReceive);
		// console.log('amountFrom after swap:', assetToSwapFrom.balanceOf(address(this)));
		// console.log('amountTo after swap:', assetToSwapTo.balanceOf(address(this)));
		require(
      assetToSwapFrom.balanceOf(address(this)) == balanceBeforeAssetFrom - amountToSwap,
      'WRONG_BALANCE_AFTER_SWAP'
    );

		bool receivedWell = false;
		if (assetToSwapTo.balanceOf(address(this)) >= balanceBeforeAssetTo) {
			receivedWell = assetToSwapTo.balanceOf(address(this)) - balanceBeforeAssetTo >= minAmountToReceive;
		}
		require(receivedWell, 'INSUFFICIENT_AMOUNT_RECEIVED');

		amountReceived = assetToSwapTo.balanceOf(address(this)) - balanceBeforeAssetTo; // USDC received from shorting the borrowed token (hedged)

		// console.log(IERC20Detailed(VBep20Interface(vToken).underlying()).allowance(address(this), address(router)));
		// console.log(USDC.allowance(address(this), address(router)));
		// console.log(IERC20Detailed(VBep20Interface(vToken).underlying()).name());
		// console.log(amount);
		// console.log(amountInUSDC, EasyMath.amountLessSlippage(amountInUSDC, slippage));
		// console.log("This vToken bal a2: ", VBep20Interface(VBep20Interface(vToken).underlying()).balanceOf(address(this)));
	}

	/// @dev Unhedge by swapping USDC to borrowed token and repaying
	function payback(
		address vToken,
		bytes memory swapCalldata,
		IParaSwapAugustus augustus,
    IERC20Detailed assetToSwapFrom, // NOTE: Always should be USDC (collateral)
    IERC20Detailed assetToSwapTo, // example: ETH
    uint256 maxAmountToSwap, // slippage dependent
    uint256 amountToReceive // always constant
	)
		public
		onlyOwner
		// onlyEnabledVToken(vToken)
		returns (uint256 amountSold)
	{
		VBep20Interface vuToken = VBep20Interface(VBep20Interface(vToken).underlying()); // token underlying vToken

		if (address(vuToken) != address(USDC)) {
			uint balanceBeforeAssetFrom = assetToSwapFrom.balanceOf(address(this));
			// console.log('balanceBeforeAssetFrom', balanceBeforeAssetFrom);
			require(balanceBeforeAssetFrom >= maxAmountToSwap, 'INSUFFICIENT_BALANCE_BEFORE_SWAP');

			if (vuToken.balanceOf(address(this)) < amountToReceive) {
				uint balanceBeforeAssetTo = assetToSwapTo.balanceOf(address(this));
				// console.log('balanceBeforeAssetTo', balanceBeforeAssetTo);

				//
				// ParaSwap
				//
				// (bytes memory buyCalldata, IParaSwapAugustus augustus) = abi.decode(
				// 	paraswapData,
				// 	(bytes, IParaSwapAugustus)
				// );

				// address tokenTransferProxy = augustus.getTokenTransferProxy();

				// if (assetToSwapFrom.allowance(address(this), tokenTransferProxy) < maxAmountToSwap) {
				// 	assetToSwapFrom.approve(tokenTransferProxy, type(uint).max); // give max
				// }

				(bool success, ) = address(augustus).call(swapCalldata);
				if (!success) {
					// Copy revert reason from call
					// console.log('unsuccessful swap');
					assembly {
						returndatacopy(0, 0, returndatasize())
						revert(0, returndatasize())
					}
				}

				bool receivedWell = false;
				if (assetToSwapTo.balanceOf(address(this)) >= balanceBeforeAssetTo) {
					receivedWell = assetToSwapTo.balanceOf(address(this)) - balanceBeforeAssetTo >= amountToReceive;
				}
				require(receivedWell, 'INSUFFICIENT_AMOUNT_RECEIVED');

				// After Swap checks
				uint balanceAfterAssetFrom = assetToSwapFrom.balanceOf(address(this));
				amountSold = balanceBeforeAssetFrom - balanceAfterAssetFrom;
				require(amountSold <= maxAmountToSwap, 'WRONG_BALANCE_AFTER_SWAP');
			}
		}

		// VBep20Interface vuToken = VBep20Interface(VBep20Interface(vToken).underlying());
		// require(
		// 	vuToken.balanceOf(address(this)) >= amountToReceive,
		// 	'Insufficient vToken amount for repayment'
		// );
		// Payback
		uint err2 = VBep20Interface(vToken).repayBorrow(amountToReceive);
		require(err2 == 0, string.concat('Repay borrow failed with ', Strings.toString(err2)));
	}

	/// @dev Close all hedges of all tokens and exit immediately
	// function exitAll() public onlyOwner {
	// 	VTokenInterface[] memory vtokens = comptroller.getAssetsIn(address(this));
	// 	for (uint i = 0; i < vtokens.length;) {
	// 		VTokenInterface vtoken = vtokens[i];
	// 		(,, uint borrowBalance,) = vtoken.getAccountSnapshot(address(this));
	// 		// console.log("vToken: ", address(vtoken));
	// 		// console.log("vTokenBalance: ", vTokenBalance);
	// 		// console.log("borrowBalance: ", borrowBalance);
	// 		if (borrowBalance > 0) {
	// 			swapAndPayback(address(vtoken), borrowBalance, config.defaultSlippage(), false);
	// 			VBep20Interface(address(vtoken)).redeemUnderlying(borrowBalance);
	// 			(,uint vTokenBalance,,) = vtoken.getAccountSnapshot(address(this)); // update vTken balance
	// 		}

	// 		if (vTokenBalance > 0) {
	// 			VBep20Interface(address(vtoken)).redeem(vTokenBalance);
	// 			(,vTokenBalance,,) = vtoken.getAccountSnapshot(address(this)); // update vTken balance
	// 			if (vTokenBalance > 0) VBep20Interface(address(vtoken)).redeemUnderlying(vTokenBalance);
	// 			withdrawERC(VBep20Interface(address(vtoken)).underlying());
	// 		}

	// 		unchecked { i++; }
	// 	}
	// }

	//
	// vToken management
	//

	function enableVTokens(address[] memory vTokens) public onlyOwner {
		for (uint i = 0; i < vTokens.length;) {
			enabledVTokens.add(vTokens[i]);

			IERC20Detailed vuToken = IERC20Detailed(
				vTokens[i] != address(0xA07c5b74C9B40447a954e1466938b865b6BBea36)
					? address(VBep20Interface(vTokens[i]).underlying()) // NOT vBNB, use underlying token
					: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c // is vBNB, use wrapped BNB
			);

			vuToken.approve(address(vTokens[i]), type(uint).max); // For minting vToken
			// vuToken.approve(address(paraswap), type(uint).max); // For swapping vToken
			vuToken.approve(address(paraswapTokenProxy), type(uint).max); // For swapping vToken
			
			unchecked { i++; }
		}
		comptroller.enterMarkets(vTokens);
	}

	function disableVTokens(address[] memory vTokens) public onlyOwner {
		for (uint i = 0; i < vTokens.length;) {
			enabledVTokens.remove(vTokens[i]);
			uint err = comptroller.exitMarket(vTokens[i]);
			require(err == 0, string.concat('Disable vToken failed with ', Strings.toString(err)));
			unchecked { i++; }
		}
	}

	function getEnabledVTokens() public view returns (address[] memory) {
		return enabledVTokens.values();
	}

	function isEnabledVToken(address token) public view returns (bool) {
		return enabledVTokens.contains(token);
	}

	/// @dev Converts the input VToken amount to USDC value 
	function getVTokenValue(VTokenInterface token, uint256 amount) public view returns (uint256) {
		return token.exchangeRateStored() * amount / 1e18;
	}

	function getAccountLiquidity() public view returns (uint256 err, uint256 collateral, uint256 shortfall) {
		(err, collateral, shortfall) = comptroller.getAccountLiquidity(address(this));
		// NOTE: collateral is returned as 0.8 of total deposit, but we do our own calculation
		collateral = collateral * 1e18 * 125 / 100 / 1e18;
	}

	/// @dev Amount - amount * slippage
  /// @param a Amount of token
  /// @param s Desired slippage in 10^4 (e.g. 0.01% => 0.01e4 => 100)
	// function amountLessSlippage(uint256 a, uint256 s) internal pure returns (uint256) {
  //   return (a * (10 ** 6 - s)) / 10 ** 6;
  // }

  /// @dev Amount + amount * slippage
  /// @param a Amount of token
  /// @param s Desired slippage in 10^4 (e.g. 0.01% => 0.01e4 => 100)
  function _amountMoreSlippage(uint256 a, uint256 s) internal pure returns (uint256) {
    // slippage: 0.5e4 (0.5%)
    return (a * (10 ** 6 + s)) / 10 ** 6;
  }

	function withdrawERC(address token) public onlyOwner {
		IERC20Detailed(token).transferFrom(address(this), msg.sender, IERC20Detailed(token).balanceOf(address(this)));
	}

	function withdrawVToken(address vToken) public onlyOwner {
		VBep20Interface(vToken).transferFrom(address(this), msg.sender, VBep20Interface(vToken).balanceOf(address(this)));
	}

	function withdrawBSC() public onlyOwner {
		(bool sent, bytes memory data) = msg.sender.call{value: address(this).balance}('');
		require(sent, 'Fail to send');
	}
}
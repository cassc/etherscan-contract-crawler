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
import { EIP20NonStandardInterface } from './interfaces/Venus/EIP20NonStandardInterface.sol';
import { ComptrollerInterface } from './interfaces/Venus/ComptrollerInterface.sol';
// import { IPancakeRouter01 } from './interfaces/Venus/PancakeStuff.sol';
import { IERC20Detailed } from './interfaces/tokens/IERC20Detailed.sol';
import { IParaSwapAugustus } from './external/paraswap/IParaSwapAugustus.sol';
import { Config } from './components/Config.sol';

contract VenusHedger is Ownable {
	using EnumerableSet for EnumerableSet.AddressSet;

	VBep20Interface constant internal vUSDC = VBep20Interface(0xecA88125a5ADbe82614ffC12D0DB554E2e2867C8);
	EIP20NonStandardInterface immutable internal USDC = EIP20NonStandardInterface(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d); // underlying of vUSDC

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

	function setConfig(address _config) public onlyOwner {
		config = Config(_config);
	}

	function setParaSwap(address _augustus) public onlyOwner {
		paraswap = IParaSwapAugustus(_augustus);
		paraswapTokenProxy = paraswap.getTokenTransferProxy();
	}

	/// @dev Deposit USDC directly as the collateral
	function depositCollateral(uint256 amount) public onlyOwner {
		USDC.transferFrom(msg.sender, address(this), amount);
		vUSDC.mint(amount);
	}

	function initiate() public onlyOwner {
		require(!initiated, 'Already initiated');
		initiated = true;

		address[] memory vTokens = new address[](6);
		vTokens[0] = address(0xA07c5b74C9B40447a954e1466938b865b6BBea36); // vBNB
		vTokens[1] = address(0x882C173bC7Ff3b7786CA16dfeD3DFFfb9Ee7847B); // vBTC
		vTokens[2] = address(0xf508fCD89b8bd15579dc79A6827cB4686A3592c8); // vETH
		vTokens[3] = address(0xecA88125a5ADbe82614ffC12D0DB554E2e2867C8); // vUSDC
		vTokens[4] = address(0x5c9476FcD6a4F9a3654139721c949c2233bBbBc8); // vMATIC
		vTokens[5] = address(0x650b940a1033B8A1b1873f78730FcFC73ec11f1f); // vLINK
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
    uint256 amountToSwap,
    uint256 minAmountToReceive
	)
		public
		onlyEnabledVToken(vToken)
		onlyOwner
	{
		require(isEnabledVToken(vToken), 'VToken not supported, support it first.');

		// Collateral check, param: USDC price of vToken (e.g. vETH) // Oracle deicmals: 18
		uint amountInUSDC = amountToSwap * oracle.getUnderlyingPrice(VTokenInterface(vToken)) / (10 ** (18));
		_manageCollateral(amountInUSDC);

		// Borrow succeed => returns 0
		// console.log("This vToken bal b: ", VBep20Interface(VBep20Interface(vToken).underlying()).balanceOf(address(this)));
		uint err = VBep20Interface(vToken).borrow(amountToSwap);
		require(err == 0, string.concat('Borrow failed with ', Strings.toString(err)));
		// console.log("This vToken bal a: ", VBep20Interface(VBep20Interface(vToken).underlying()).balanceOf(address(this)));

		//
		// ParaSwap
		//
		uint256 balanceBeforeAssetFrom = assetToSwapFrom.balanceOf(address(this));
    uint256 balanceBeforeAssetTo = assetToSwapTo.balanceOf(address(this));
		// console.log('balanceBeforeAssetFrom:', balanceBeforeAssetFrom);
		// console.log('amountToSwap:', amountToSwap);
		// console.log('balanceBeforeAssetTo:', balanceBeforeAssetTo);
		// console.log('t:', IERC20Detailed(0x2170Ed0880ac9A755fd29B2688956BD959F933F8).balanceOf(address(this)));
		if (balanceBeforeAssetFrom < amountToSwap) {
			// balance short fall
			uint shortfall = amountToSwap - balanceBeforeAssetFrom;
			require(assetToSwapFrom.balanceOf(msg.sender) > shortfall, 'Not enough assetToSwapFrom allowance in caller to transfer');
			require(assetToSwapFrom.allowance(msg.sender, address(this)) > shortfall, 'Not enough assetToSwapFrom allowance in caller to transfer');
			require(assetToSwapFrom.transferFrom(msg.sender, address(this), shortfall), 'Failed assetToSwapFrom transfer to cover shortfall');
			balanceBeforeAssetFrom += shortfall;
    	// require(balanceBeforeAssetFrom >= amountToSwap, 'INSUFFICIENT_BALANCE_BEFORE_SWAP');
		}

		// address tokenTransferProxy = augustus.getTokenTransferProxy();

		// console.log('tokenTransferProxy assetToSwapFrom allowance: ', assetToSwapFrom.allowance(address(this), tokenTransferProxy));
		// console.log('tokenTransferProxy assetToSwapFrom balance: ', assetToSwapFrom.balanceOf(address(this)));
		// if (assetToSwapFrom.allowance(address(this), tokenTransferProxy) < amountToSwap) {
		// 	assetToSwapFrom.approve(tokenTransferProxy, type(uint).max); // give max
		// }

		// Swap via ParaSwap
		(bool success, ) = address(augustus).call(swapCalldata);
    if (!success) {
      // Copy revert reason from call
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

		// After Swap checks
		// require(
    //   assetToSwapFrom.balanceOf(address(this)) == balanceBeforeAssetFrom - amountToSwap,
    //   'WRONG_BALANCE_AFTER_SWAP'
    // );

		bool receivedWell = false;
		if (assetToSwapTo.balanceOf(address(this)) >= balanceBeforeAssetTo) {
			receivedWell = assetToSwapTo.balanceOf(address(this)) - balanceBeforeAssetTo >= minAmountToReceive;
		}
		require(receivedWell, 'INSUFFICIENT_AMOUNT_RECEIVED');


		// console.log(IERC20Detailed(VBep20Interface(vToken).underlying()).allowance(address(this), address(router)));
		// console.log(USDC.allowance(address(this), address(router)));
		// console.log(IERC20Detailed(VBep20Interface(vToken).underlying()).name());
		// console.log(amount);
		// console.log(amountInUSDC, EasyMath.amountLessSlippage(amountInUSDC, slippage));
		// console.log("This vToken bal a2: ", VBep20Interface(VBep20Interface(vToken).underlying()).balanceOf(address(this)));
	}

	/// @dev Pay back the hedge
	function payback(address vToken, uint256 amount)
		public
		onlyOwner
		onlyEnabledVToken(vToken)
	{
		// VBep20Interface vuToken = VBep20Interface(VBep20Interface(vToken).underlying());
		// require(
		// 	vuToken.balanceOf(address(this)) >= amount,
		// 	'Insufficient vToken amount for repayment'
		// );
		uint err = VBep20Interface(vToken).repayBorrow(amount);
		require(err == 0, string.concat('Repay borrow failed with ', Strings.toString(err)));
	}

	function swapAndPayback(
		address vToken,
		bytes memory paraswapData,
    IERC20Detailed assetToSwapFrom, // NOTE: Always should be USDC (collateral)
    IERC20Detailed assetToSwapTo,
    uint256 maxAmountToSwap,
    uint256 amountToReceive
	)
		public
		onlyOwner
		onlyEnabledVToken(vToken)
		returns (uint256 amountSold)
	{
		VBep20Interface vuToken = VBep20Interface(VBep20Interface(vToken).underlying()); // token underlying vToken

		if (address(vuToken) != address(USDC)) {
			// Swap USDC to vToken.underlying only if there's shortfall to repay `amount` of vToken.underlying
			if (maxAmountToSwap > vuToken.balanceOf(address(this))) {
				// uint price = oracle.getUnderlyingPrice(VTokenInterface(vToken));

				uint256 balanceBeforeAssetFrom = assetToSwapFrom.balanceOf(address(this));
				uint256 balanceBeforeAssetTo = assetToSwapTo.balanceOf(address(this));
				if (balanceBeforeAssetFrom < maxAmountToSwap) {
					// balance short fall for USDC
					uint shortfall = maxAmountToSwap - balanceBeforeAssetFrom;

					// Not enough USDC in wallet, so redeem just enough vUSDC (to USDC) to cover the difference
					uint err = vUSDC.redeemUnderlying(
						_amountMoreSlippage(maxAmountToSwap - USDC.balanceOf(address(this)), 1000) // 0.1% extra buffer
					);
					require(err == 0, string.concat('vUSDC redeem underlying failed with ', Strings.toString(err)));

					if (err != 0) {
						// vUSDC redeem underlying failed, try transferring from wallet
						require(assetToSwapFrom.balanceOf(msg.sender) > shortfall, 'Not enough USDC allowance in caller to transfer');
						require(assetToSwapFrom.allowance(msg.sender, address(this)) > shortfall, 'Not enough USDC allowance in caller to transfer');
						require(assetToSwapFrom.transferFrom(msg.sender, address(this), shortfall), 'Failed USDC transfer to cover shortfall');
					}

					balanceBeforeAssetFrom += assetToSwapFrom.balanceOf(address(this));
				}
				require(balanceBeforeAssetFrom >= maxAmountToSwap, 'INSUFFICIENT_BALANCE_BEFORE_SWAP');

				//
				// ParaSwap
				//
				(bytes memory buyCalldata, IParaSwapAugustus augustus) = abi.decode(
					paraswapData,
					(bytes, IParaSwapAugustus)
				);

				// address tokenTransferProxy = augustus.getTokenTransferProxy();

				// if (assetToSwapFrom.allowance(address(this), tokenTransferProxy) < maxAmountToSwap) {
				// 	assetToSwapFrom.approve(tokenTransferProxy, type(uint).max); // give max
				// }

				(bool success, ) = address(augustus).call(buyCalldata);
				if (!success) {
					// Copy revert reason from call
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
				uint256 balanceAfterAssetFrom = assetToSwapFrom.balanceOf(address(this));
				amountSold = balanceBeforeAssetFrom - balanceAfterAssetFrom;
				// require(amountSold <= maxAmountToSwap, 'WRONG_BALANCE_AFTER_SWAP');

				// receivedWell = false;
				// if (assetToSwapTo.balanceOf(address(this)) >= balanceBeforeAssetTo) {
				// 	receivedWell = assetToSwapTo.balanceOf(address(this)) - balanceBeforeAssetTo >= amountToReceive;
				// }
				// require(receivedWell, 'INSUFFICIENT_AMOUNT_RECEIVED');
			}
		}

		payback(vToken, amountToReceive);
	}

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

		// VTokenInterface[] memory tokens = comptroller.getAssetsIn(address(this));
		// for (uint i = 0; i < tokens.length; i++) {
		// 	VTokenInterface token = tokens[i];
		// 	(, uint vTokenBalance, uint borrowBalance,) = token.getAccountSnapshot(address(this));
		// 	console.log("vToken: ", address(token));
		// 	console.log("vTokenBalance: ", vTokenBalance);
		// 	console.log("borrowBalance: ", borrowBalance);
		// }

		// Not enough collateral, need to deposit collateral
		if (requiredCollateral > availableCollateral) {
			uint diff = requiredCollateral - availableCollateral;

			require(USDC.allowance(msg.sender, address(this)) >= diff, "Insufficient USDC allowance");
			require(USDC.balanceOf(msg.sender) >= diff, "Insufficient USDC to transfer");

			USDC.transferFrom(msg.sender, address(this), diff);
			require(vUSDC.mint(diff) == 0, 'Mint failed'); // @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
		}
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

			EIP20NonStandardInterface vuToken = EIP20NonStandardInterface(
				vTokens[i] != address(0xA07c5b74C9B40447a954e1466938b865b6BBea36)
					? address(VBep20Interface(vTokens[i]).underlying()) // NOT vBNB, use underlying token
					: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c // is vBNB, use wrapped BNB
			);

			vuToken.approve(address(vTokens[i]), type(uint).max); // For minting vToken
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
}
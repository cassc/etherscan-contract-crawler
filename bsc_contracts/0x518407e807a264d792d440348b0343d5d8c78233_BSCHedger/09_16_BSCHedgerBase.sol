// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import { Ownable } from 'openzeppelin-contracts/access/Ownable.sol';
import { EnumerableSet } from 'openzeppelin-contracts/utils/structs/EnumerableSet.sol';
// import { console } from 'forge-std/console.sol';

import { BaseHedger } from './BaseHedger.sol';
import { PriceOracle } from '../interfaces/Venus/PriceOracle.sol';
import { VBep20Interface, VTokenInterface } from '../interfaces/Venus/VTokenInterfaces.sol';
import { EIP20NonStandardInterface } from '../interfaces/Venus/EIP20NonStandardInterface.sol';
import { ComptrollerInterface } from "../interfaces/Venus/ComptrollerInterface.sol";
import { IPancakeRouter01 } from '../interfaces/Venus/PancakeStuff.sol';

contract BSCHedgerBase is BaseHedger, Ownable {
	using EnumerableSet for EnumerableSet.AddressSet;

  VBep20Interface constant internal vUSDC = VBep20Interface(0xecA88125a5ADbe82614ffC12D0DB554E2e2867C8);
	EIP20NonStandardInterface immutable internal USDC;

	/// @dev vBNB uses native BNB gas as underlying, so there's no `.underlying()`
	VBep20Interface constant internal vBNB = VBep20Interface(0xecA88125a5ADbe82614ffC12D0DB554E2e2867C8);

	/// @dev Native ETH on BSC
	EIP20NonStandardInterface immutable internal ETH;

	VBep20Interface constant internal vETH = VBep20Interface(0xf508fCD89b8bd15579dc79A6827cB4686A3592c8);

	IPancakeRouter01 constant internal router = IPancakeRouter01(0x10ED43C718714eb63d5aA57B78B54704E256024E);

	address constant internal comptrollerAddress = 0xfD36E2c2a6789Db23113685031d7F16329158384;
	ComptrollerInterface constant internal comptroller = ComptrollerInterface(comptrollerAddress); // Unitroller proxy

	// /// @dev GET PROXY ADDRESS OF THE PRICE ORACLE
	// /// @dev https://github.com/VenusProtocol/venus-protocol/blob/develop/contracts/PriceOracleProxy.sol
	PriceOracle constant internal oracle = PriceOracle(0xd8B6dA2bfEC71D684D3E2a2FC9492dDad5C3787F);

	EnumerableSet.AddressSet internal supportedVTokens;

	uint256 public defaultSlippage = 5000; // 0.5%

	modifier validVToken(address vToken) {
		require(supportedVTokens.contains(vToken), 'Unsupported vToken. Support the token first on the contract');
		_;
	}

  constructor(address _whitelist) BaseHedger(_whitelist) {
		// initialize token
		USDC = EIP20NonStandardInterface(address(vUSDC.underlying()));
		ETH = EIP20NonStandardInterface(address(vETH.underlying()));

		// support vtokens
		address[] memory vTokens = new address[](2);
		vTokens[0] = address(vETH);
		vTokens[1] = address(vUSDC);
		supportVTokens(vTokens);
	}

	function supportVToken(address vToken) public onlyOwner {
		supportedVTokens.add(vToken);
		if (vToken != address(vBNB)) {
			// underlying token of vToken
			EIP20NonStandardInterface vuToken = EIP20NonStandardInterface(address(VBep20Interface(vToken).underlying()));
			// console.log(address(vuToken));
			vuToken.approve(address(vToken), type(uint).max); // For minting vToken
			vuToken.approve(address(router), type(uint).max); // For swapping vToken
			// console.log(vuToken.allowance(address(this), address(vToken)));
			// console.log(vuToken.allowance(address(this), address(router)));
		}

		address[] memory vTokens = new address[](1);
		vTokens[0] = vToken;
		comptroller.enterMarkets(vTokens);
	}

	function supportVTokens(address[] memory vTokens) public onlyOwner {
		for (uint i = 0; i < vTokens.length; i++) {
			supportedVTokens.add(vTokens[i]);
			if (vTokens[i] == address(vBNB)) continue; // no approval needed for vBNB
			EIP20NonStandardInterface vuToken = EIP20NonStandardInterface(address(VBep20Interface(vTokens[i]).underlying()));
			vuToken.approve(address(vTokens[i]), type(uint).max); // For minting vToken
			vuToken.approve(address(router), type(uint).max); // For swapping vToken
		}
		comptroller.enterMarkets(vTokens);
	}

	function unsupportVToken(address vToken) public onlyOwner {
		supportedVTokens.remove(address(vToken));
		// underlying token of vToken
		EIP20NonStandardInterface vuToken = EIP20NonStandardInterface(address(VBep20Interface(vToken).underlying()));
		// For minting vToken
		vuToken.approve(address(vToken), 0);
		// For swapping vToken
		vuToken.approve(address(router), 0);
	}

	function getSupportedVTokens() public view onlyOwner returns (address[] memory) {
		return supportedVTokens.values();
	}

	function isSupportedVToken(address token) public view onlyOwner returns (bool) {
		return supportedVTokens.contains(token);
	}

	/// @dev Converts the input VToken amount to USDC value 
	function getVTokenValue(VTokenInterface token, uint256 amount) public view returns (uint256) {
		return token.exchangeRateStored() * amount / 1e18;
	}

	function newDefaultSlippage(uint256 s) public onlyOwner {
		defaultSlippage = s;
	}
}
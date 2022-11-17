// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import { Ownable } from 'openzeppelin-contracts/access/Ownable.sol';
import { EnumerableSet } from 'openzeppelin-contracts/utils/structs/EnumerableSet.sol';
import { ERC20 } from 'openzeppelin-contracts/token/ERC20/ERC20.sol';
// import { console } from 'forge-std/console.sol';

import { PriceOracle } from '../interfaces/Venus/PriceOracle.sol';
import { VBep20Interface, VTokenInterface } from '../interfaces/Venus/VTokenInterfaces.sol';
import { EIP20NonStandardInterface } from '../interfaces/Venus/EIP20NonStandardInterface.sol';
import { ComptrollerInterface } from "../interfaces/Venus/ComptrollerInterface.sol";
import { IPancakeRouter01 } from '../interfaces/Venus/PancakeStuff.sol';
import { Config } from '../components/Config.sol';

contract BSCHedgerBase is Ownable {
	using EnumerableSet for EnumerableSet.AddressSet;

  VBep20Interface constant internal vUSDC = VBep20Interface(0xecA88125a5ADbe82614ffC12D0DB554E2e2867C8);
	EIP20NonStandardInterface immutable internal USDC;

	IPancakeRouter01 constant internal router = IPancakeRouter01(0x10ED43C718714eb63d5aA57B78B54704E256024E);

	address constant internal comptrollerAddress = 0xfD36E2c2a6789Db23113685031d7F16329158384;
	ComptrollerInterface constant internal comptroller = ComptrollerInterface(comptrollerAddress); // Unitroller proxy

	// /// @dev GET PROXY ADDRESS OF THE PRICE ORACLE
	// /// @dev https://github.com/VenusProtocol/venus-protocol/blob/develop/contracts/PriceOracleProxy.sol
	PriceOracle constant internal oracle = PriceOracle(0xd8B6dA2bfEC71D684D3E2a2FC9492dDad5C3787F);

	Config public config;

	bool public initiated = false;

  constructor(address _config) {
		setConfig(_config);
		// initialize collateral token
		USDC = EIP20NonStandardInterface(address(vUSDC.underlying()));

		// Manaully approve USDC in particular here
		USDC.approve(address(vUSDC), type(uint).max); // For minting vToken
		USDC.approve(address(router), type(uint).max); // For swapping vToken
	}

	function initiate() public onlyOwner {
		require(!initiated, 'Already initiated');
		initiated = true;

    // Whitelist PancakeRouter
    config.whitelist().add(address(router));
		// support vTokens
		address[] memory vTokens = new address[](18);
		vTokens[0] = address(0x9A0AF7FDb2065Ce470D72664DE73cAE409dA28Ec); // vADA
		vTokens[1] = address(0xA07c5b74C9B40447a954e1466938b865b6BBea36); // vBNB
		vTokens[2] = address(0x882C173bC7Ff3b7786CA16dfeD3DFFfb9Ee7847B); // vBTC
		vTokens[3] = address(0xf508fCD89b8bd15579dc79A6827cB4686A3592c8); // vETH
		vTokens[4] = address(0xfD5840Cd36d94D7229439859C0112a4185BC0255); // vUSDT
		vTokens[5] = address(0xecA88125a5ADbe82614ffC12D0DB554E2e2867C8); // vUSDC
		vTokens[6] = address(0x5c9476FcD6a4F9a3654139721c949c2233bBbBc8); // vMATIC
		vTokens[7] = address(0x26DA28954763B92139ED49283625ceCAf52C6f94); // vAAVE
		vTokens[8] = address(0x334b3eCB4DCa3593BCCC3c7EBD1A1C1d1780FBF1); // vDAI
		vTokens[9] = address(0x1610bc33319e9398de5f57B33a5b184c806aD217); // vDOT
		vTokens[10] = address(0x86aC3974e2BD0d60825230fa6F355fF11409df5c); // vCAKE
		vTokens[11] = address(0x650b940a1033B8A1b1873f78730FcFC73ec11f1f); // vLINK
		vTokens[12] = address(0x95c78222B3D6e262426483D42CfA53685A67Ab9D); // vBUSD
		vTokens[13] = address(0x5F0388EBc2B94FA8E123F404b79cCF5f40b29176); // vBCH
		vTokens[14] = address(0xec3422Ef92B2fb59e84c8B02Ba73F1fE84Ed8D71); // vDOGE
		vTokens[15] = address(0xB248a295732e0225acd3337607cc01068e3b9c10); // vXRP
		vTokens[16] = address(0xf91d58b5aE142DAcC749f58A49FCBac340Cb0343); // vFIL
		vTokens[17] = address(0x57A5297F2cB2c0AaC9D554660acd6D385Ab50c6B); // vLTC
		config.whitelist().supportVTokens(vTokens);

		comptroller.enterMarkets(vTokens);

		// approval needs to be done here to set msg.sender = address(hedger) [can't delegate call approval]
		for (uint i = 0; i < vTokens.length; i++) {
			EIP20NonStandardInterface vuToken;
			if (vTokens[i] != address(0xA07c5b74C9B40447a954e1466938b865b6BBea36)) { // non vBNB
				vuToken = EIP20NonStandardInterface(address(VBep20Interface(vTokens[i]).underlying()));
			} else { // vBNB (underlying is just wrapped BNB)
				vuToken = EIP20NonStandardInterface(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
			}
			vuToken.approve(address(vTokens[i]), type(uint).max); // For minting vToken
			vuToken.approve(address(router), type(uint).max); // For swapping vToken
		}
	}

	function setConfig(address _config) public onlyOwner {
		config = Config(_config);
	}

	function withdrawERC(address token) public onlyOwner {
		// console.log('withdrawing erc to', msg.sender);
		// console.log('amount', ERC20(token).balanceOf(address(this)));
		ERC20(token).transfer(msg.sender, ERC20(token).balanceOf(address(this)));
	}

	function withdrawVToken(address vtoken) public onlyOwner {
		require(VTokenInterface(vtoken).isVToken(), 'Invalid vToken');
		VBep20Interface(vtoken).transfer(msg.sender, ERC20(vtoken).balanceOf(address(this)));
	}

	function withdrawUnderlying(address vtoken, uint amount) public onlyOwner {
		require(VTokenInterface(vtoken).isVToken(), 'Invalid vToken');
		VBep20Interface(vtoken).redeemUnderlying(amount);
		ERC20(VBep20Interface(vtoken).underlying()).transfer(msg.sender, amount);
	}

	function withdrawUnderlyingAll(address vtoken) public onlyOwner {
		require(VTokenInterface(vtoken).isVToken(), 'Invalid vToken');
		withdrawUnderlying(vtoken, ERC20(VBep20Interface(vtoken).underlying()).balanceOf(address(this)));
	}

	fallback() external payable {}
	receive() external payable {}
}
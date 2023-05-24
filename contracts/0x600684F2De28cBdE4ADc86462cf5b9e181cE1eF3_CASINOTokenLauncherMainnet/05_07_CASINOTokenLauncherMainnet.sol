// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { FixedSupplyToken } from "./FixedSupplyToken.sol";
import { IUniswapV2Router } from "./IUniswapV2Router.sol";

contract CASINOTokenLauncherMainnet
{
	struct Recipient {
		address to;
		uint256 value;
		uint256 amount;
	}

	address constant OWNER = 0x2F80922CF7350e06F4924766Cb7EEEC783c1C8ce;

	address constant RECEIVER = 0xB0632a01ee778E09625BcE2a257e221b49E79696;

	address constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // UniswapV2

	address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH

	address constant FURNACE = 0x000000000000000000000000000000000000dEaD;

	string constant NAME = "CASINO";

	uint256 constant SUPPLY = 10_000_000_000e18; // 10B tokens

	uint256 constant DEDUCTION = SUPPLY * 4.5e16 / 100e16; // 4.5% of supply

	uint256 constant LIQUIDITY = 2.5e18; // 2.5 ETH

	uint256 constant PURCHASE = 1.5e18; // 1.5 ETH

	address public token;

	Recipient[] public airdrop;

	constructor()
	{
		airdrop.push(Recipient({ to: 0x985C56eB1e8951329aa862570AEB584B074bEB10, value:   0.5e18, amount: 0 }));
		airdrop.push(Recipient({ to: 0x80F2dCC36D9548F97A14a3bF73D992FB614e45f4, value:   0.5e18, amount: 0 }));
		airdrop.push(Recipient({ to: 0x2165fa4a32B9c228cD55713f77d2e977297D03e8, value:   0.5e18, amount: 0 }));
		airdrop.push(Recipient({ to: 0xc1a17F2fd7DB9adf67De8a8F331d682923090Feb, value:   0.6e18, amount: 0 }));
		airdrop.push(Recipient({ to: 0x6A645f11716Fe2F0b308515FFbE383b490a4bFCE, value:     1e18, amount: 0 }));
		airdrop.push(Recipient({ to: 0xEE79a26aE73e26224B49eC6fE3A62B52424B9D0b, value:     1e18, amount: 0 }));
		airdrop.push(Recipient({ to: 0xA367B1895deE09AEE1E1FdbD1027e283c1198046, value:   0.5e18, amount: 0 }));
		airdrop.push(Recipient({ to: 0x99335137cB4621498ef0719bc8b871003e7bdc44, value:  0.14e18, amount: 0 }));
		airdrop.push(Recipient({ to: 0x94F8499D9F0aa65b41Cf2f8ED09A2260530ED269, value:     1e18, amount: 0 }));
		airdrop.push(Recipient({ to: 0x906B2402b7b569e68A04B11fb7d5A576BC11d51D, value:   0.7e18, amount: 0 }));
		airdrop.push(Recipient({ to: 0xcD8dDeE99C0c4Be4cD699661AE9c00C69D1Eb4A8, value:   0.5e18, amount: 0 }));
		airdrop.push(Recipient({ to: 0x1D102Cc151C2CD40C9ceDa6394b7649cDDD260B4, value: 0.017e18, amount: 0 }));
		airdrop.push(Recipient({ to: 0x93e5cEda644Da2b97c6b8B014756E1cA0927aDa7, value:   0.3e18, amount: 0 }));
		airdrop.push(Recipient({ to: 0xBe7E848Db82C1bE21fDD6AaCdFC51c900B2682d6, value:   0.4e18, amount: 0 }));
		airdrop.push(Recipient({ to: 0x76B5cbdB978122e147F5105cF2801F99C87c0F89, value:     1e18, amount: 0 }));
		uint256 _value = 0;
		for (uint256 _i = 0; _i < airdrop.length; _i++) {
			Recipient storage _recipient = airdrop[_i];
			_value += _recipient.value;
		}
		/*
		airdrop0 = 7.657
		reserve0 = 2.5
		amount0 = 1.5
		reserve0' = reserve0 + amount0

		reserve1 = 9.55B - airdrop1
		amount1 = (amount0 * 997 * reserve1) / (reserve0 * 1000 + amount0 * 997)
		reserve1' = reserve1 - amount1

		airdrop1 = airdrop0 * reserve1' / reserve0'

		Deduction:

		reserve1' = reserve1 - amount1
		reserve1' = reserve1 - (amount0 * 997 * reserve1) / (reserve0 * 1000 + amount0 * 997)
		reserve1' = ((reserve0 * 1000 + amount0 * 997) * reserve1 - (amount0 * 997 * reserve1)) / (reserve0 * 1000 + amount0 * 997)
		reserve1' = ((reserve0 * 1000 * reserve1 + amount0 * 997 * reserve1) - (amount0 * 997 * reserve1)) / (reserve0 * 1000 + amount0 * 997)
		reserve1' = (reserve0 * 1000 * reserve1) / (reserve0 * 1000 + amount0 * 997)
		reserve1' = (reserve0 * 1000 * (9.55B - airdrop1)) / (reserve0 * 1000 + amount0 * 997)
		reserve1' = (reserve0 * 1000 * 9.55B - reserve0 * 1000 * airdrop1) / (reserve0 * 1000 + amount0 * 997)
		(reserve0 * 1000 + amount0 * 997) * reserve1' = reserve0 * 1000 * 9.55B - reserve0 * 1000 * airdrop1
		(reserve0 * 1000 + amount0 * 997) * reserve1' = reserve0 * 1000 * 9.55B - reserve0 * 1000 * (airdrop0 * reserve1' / reserve0')
		(reserve0 * 1000 + amount0 * 997) * reserve1' * reserve0' = reserve0 * 1000 * 9.55B * reserve0' - reserve0 * 1000 * airdrop0 * reserve1'
		(reserve0 * 1000 + amount0 * 997) * reserve1' * reserve0' + reserve0 * 1000 * airdrop0 * reserve1' = reserve0 * 1000 * 9.55B * reserve0'
		(((reserve0 * 1000 + amount0 * 997) * reserve0') + (reserve0 * 1000 * airdrop0)) * reserve1' = reserve0 * 1000 * 9.55B * reserve0'
		((reserve0 * 1000 * reserve0' + amount0 * 997 * reserve0') + (reserve0 * 1000 * airdrop0)) * reserve1' = reserve0 * 1000 * 9.55B * reserve0'
		(reserve0 * 1000 * reserve0' + amount0 * 997 * reserve0' + reserve0 * 1000 * airdrop0) * reserve1' = reserve0 * 1000 * 9.55B * reserve0'
		reserve1' = (reserve0 * 1000 * 9.55B * reserve0') / (reserve0 * 1000 * reserve0' + amount0 * 997 * reserve0' + reserve0 * 1000 * airdrop0)
		reserve1' = (reserve0 * 1000 * 9.55B * reserve0') / (amount0 * 997 * reserve0' + reserve0 * 1000 * (reserve0' + airdrop0))
		reserve1' = (2.5 * 1000 * 9.55B * 4) / (1.5 * 997 * 4 + 2.5 * 1000 * (4 + airdrop0))
		*/
		uint256 _reserveValue = LIQUIDITY + PURCHASE;
		uint256 _reserveAmount = (LIQUIDITY * 1000 * (SUPPLY - DEDUCTION) * _reserveValue) / (PURCHASE * 997 * _reserveValue + LIQUIDITY * 1000 * (_reserveValue + _value));
		for (uint256 _i = 0; _i < airdrop.length; _i++) {
			Recipient storage _recipient = airdrop[_i];
			_recipient.amount = (_recipient.value * _reserveAmount * 90) / (_reserveValue * 100);
		}
	}

	function launch() external payable returns (address _token)
	{
		require(token == address(0), "already launched");
		require(msg.sender == OWNER || msg.sender == RECEIVER, "access denied");
		require(msg.value == LIQUIDITY + PURCHASE, "invalid value");
		token = address(new FixedSupplyToken(NAME, NAME, SUPPLY));
		IERC20(token).transfer(RECEIVER, DEDUCTION);
		uint256 _liquidity = SUPPLY - DEDUCTION;
		for (uint256 _i = 0; _i < airdrop.length; _i++) {
			Recipient storage _recipient = airdrop[_i];
			IERC20(token).transfer(_recipient.to, _recipient.amount);
			_liquidity -= _recipient.amount;
		}
		IERC20(token).approve(ROUTER, _liquidity);
		IUniswapV2Router(ROUTER).addLiquidityETH{value: LIQUIDITY}(token, _liquidity, _liquidity, LIQUIDITY, RECEIVER, block.timestamp);
		address[] memory _path = new address[](2);
		_path[0] = WETH;
		_path[1] = token;
		IUniswapV2Router(ROUTER).swapExactETHForTokens{value: PURCHASE}(0, _path, FURNACE, block.timestamp);
		return token;
	}
}
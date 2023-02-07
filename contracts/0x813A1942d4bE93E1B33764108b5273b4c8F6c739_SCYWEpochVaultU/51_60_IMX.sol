// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IMXCore, IBase, IERC20 } from "./IMXCore.sol";
import { IMXFarm } from "./IMXFarm.sol";
import { IMXConfig } from "../../interfaces/Structs.sol";
import { Auth, AuthConfig } from "../../common/Auth.sol";

// import "hardhat/console.sol";

contract IMX is IMXCore, IMXFarm {
	constructor(AuthConfig memory authConfig, IMXConfig memory config)
		Auth(authConfig)
		IMXFarm(
			config.underlying,
			config.uniPair,
			config.poolToken,
			config.farmRouter,
			config.farmToken
		)
		IMXCore(config.vault, config.underlying, config.short)
	{
		isInitialized = true;
	}

	function tarotBorrow(
		address a,
		address b,
		uint256 c,
		bytes calldata data
	) external {
		impermaxBorrow(a, b, c, data);
	}

	function tarotRedeem(
		address a,
		uint256 redeemAmount,
		bytes calldata data
	) external {
		impermaxRedeem(a, redeemAmount, data);
	}

	function underlying() public view override(IBase, IMXCore) returns (IERC20) {
		return super.underlying();
	}
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {BaseWormholeBridgedNft} from "./BaseWormholeBridgedNft.sol";
import {IWormhole} from "wormhole-solidity/IWormhole.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeGods is BaseWormholeBridgedNft {
	constructor(
		IWormhole wormhole,
		IERC20 dustToken,
		bytes32 emitterAddress,
		bytes memory baseUri
	) BaseWormholeBridgedNft(wormhole, dustToken, emitterAddress, baseUri) {}
}
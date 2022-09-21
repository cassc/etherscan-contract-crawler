// SPDX-License-Identifier: CAL
pragma solidity 0.8.10;

import {Factory} from "@beehiveinnovation/rain-protocol/contracts/factory/Factory.sol";
import "./Vapour721A.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract Vapour721AFactory is Factory {
	address private immutable implementation;

	constructor() {
		address implementation_ = address(new Vapour721A());
		emit Implementation(msg.sender, implementation_);
		implementation = implementation_;
	}

	function _createChild(bytes calldata data_)
		internal
		virtual
		override
		returns (address)
	{
		InitializeConfig memory config_ = abi.decode(data_, (InitializeConfig));
		address clone_ = Clones.clone(implementation);
		Vapour721A(clone_).initialize(config_); 
		return clone_;
	}

	/// Typed wrapper around IFactory.createChild.
	function createChildTyped(InitializeConfig calldata initializeConfig_)
		external
		returns (Vapour721A)
	{
		return Vapour721A(this.createChild(abi.encode(initializeConfig_)));
	}
}
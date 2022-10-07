// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract BaseUpgradable is
	Initializable,
	OwnableUpgradeable,
	UUPSUpgradeable,
    ERC721Upgradeable
{
	using AddressUpgradeable for address;

	uint public version;

	/// @custom:oz-upgrades-unsafe-allow constructor
	function initialize(string memory name, string memory symbol) public initializer {
		__Ownable_init();
		__UUPSUpgradeable_init();
        __ERC721_init(name, symbol);
		version = 1;
		console.log("v", version);
	}

	function _authorizeUpgrade(address newImplementation)
		internal
		onlyOwner
		override
	{}
}
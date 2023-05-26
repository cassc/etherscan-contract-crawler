// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import "@solidstate/contracts/introspection/ERC165Storage.sol";
import "@solidstate/contracts/proxy/diamond/SolidStateDiamond.sol";
import "@solidstate/contracts/token/ERC1155/IERC1155.sol";
import "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";
import "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol";

import "../vendor/ERC2981/IERC2981Royalties.sol";
import "../vendor/ERC2981/ERC2981Storage.sol";
import "../vendor/OpenSea/OpenSeaCompatible.sol";
import "../vendor/OpenSea/OpenSeaProxyStorage.sol";

import "./LandStorage.sol";
import "./LandTypes.sol";

contract LandProxy is SolidStateDiamond {
	using ERC165Storage for ERC165Storage.Layout;

	constructor() {
		ERC165Storage.layout().setSupportedInterface(type(IERC1155).interfaceId, true);
		ERC165Storage.layout().setSupportedInterface(type(IERC1155Metadata).interfaceId, true);
		ERC165Storage.layout().setSupportedInterface(type(IERC2981Royalties).interfaceId, true);
	}
}

contract LandProxyInitializer {
	function init(
		LandInitArgs memory landInit,
		RoyaltyInfo memory royaltyInit,
		OpenSeaProxyInitArgs memory osInit,
		string memory contractURI,
		string memory baseURI
	) external {
		// Init ERC1155Metadata
		ERC1155MetadataStorage.layout().baseURI = baseURI;
		OpenSeaCompatibleStorage.layout().contractURI = contractURI;

		// Init Land
		LandStorage.layout().mintState = uint8(MintState.CLOSED);
		LandStorage.layout().price = 0.2 ether;

		LandStorage.layout().signer = landInit.signer;
		LandStorage.layout().avatars = landInit.avatars;

		LandStorage.layout().avatarClaim = landInit.avatarClaim;

		// loop thru the zones for sale
		for (uint8 i = 0; i < landInit.zones.length; i++) {
			LandStorage._addZone(landInit.zones[i]);
		}

		// Init Royalties
		ERC2981Storage.layout().royalties = royaltyInit;

		// Init Opensea Proxy
		OpenSeaProxyStorage._setProxies(osInit);
	}
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC721 } from '@solidstate/contracts/token/ERC721/IERC721.sol';
import { IERC721Metadata } from '@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol';
import { IERC721Enumerable } from '@solidstate/contracts/token/ERC721/enumerable/IERC721Enumerable.sol';
import { ERC721MetadataStorage } from '@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol';
import { ERC165Storage } from '@solidstate/contracts/introspection/ERC165Storage.sol';
import { SolidStateDiamond } from '@solidstate/contracts/proxy/diamond/SolidStateDiamond.sol';

contract STDDiamond is SolidStateDiamond {
	constructor()
		SolidStateDiamond() payable
	{
		// Update metadata
		ERC721MetadataStorage.layout().name = 'Spin the Dart';
		ERC721MetadataStorage.layout().symbol = 'STD';

		ERC165Storage.Layout storage erc165 = ERC165Storage.layout();

		// Add ERC165 data
		erc165.supportedInterfaces[type(IERC721).interfaceId] = true;
		erc165.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
		erc165.supportedInterfaces[type(IERC721Enumerable).interfaceId] = true;
	}
}
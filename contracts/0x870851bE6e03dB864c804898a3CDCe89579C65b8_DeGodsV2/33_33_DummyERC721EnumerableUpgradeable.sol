// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// This a dummy implementation to the true ERC721EnumerableUpgradeable that maintains the identical storage layout but
// removes all the ERC721Enumerable methods from the ABI.
//
// IMPORTANT: please make sure the storage layout is identical to ERC721EnumerableUpgradeable!!!!!
abstract contract DummyERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable {
	mapping(address => mapping(uint256 => uint256)) internal _ownedTokens;
	mapping(uint256 => uint256) internal _ownedTokensIndex;
	uint256[] internal _allTokens;
	mapping(uint256 => uint256) internal _allTokensIndex;
	uint256[46] private __gap;
}
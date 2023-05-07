// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {DeGods} from "./DeGods.sol";
import {BaseWormholeBridgedNft} from "./BaseWormholeBridgedNft.sol";
import {ERC5058Upgradeable} from "ERC5058/ERC5058Upgradeable.sol";
import {IERC5192} from "ERC5192/IERC5192.sol";
import {IWormhole} from "wormhole-solidity/IWormhole.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeGodsV2 is DeGods, ERC5058Upgradeable, IERC5192 {
	uint256 private constant MAX_EXPIRE_TIME =
		0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

	constructor(
		IWormhole wormhole,
		IERC20 dustToken,
		bytes32 emitterAddress,
		bytes memory baseUri
	) DeGods(wormhole, dustToken, emitterAddress, baseUri) {}

	function locked(uint256 tokenId) external view override returns (bool) {
		return isLocked(tokenId);
	}

	function _baseURI()
		internal
		view
		virtual
		override(BaseWormholeBridgedNft, ERC721Upgradeable)
		returns (string memory)
	{
		return BaseWormholeBridgedNft._baseURI();
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId,
		uint256 batchSize
	) internal virtual override(ERC721Upgradeable, ERC5058Upgradeable) {
		ERC5058Upgradeable._beforeTokenTransfer(from, to, tokenId, batchSize);
	}

	function _afterTokenTransfer(
		address from,
		address to,
		uint256 tokenId,
		uint256 batchSize
	) internal virtual override(ERC721Upgradeable, ERC5058Upgradeable) {
		ERC5058Upgradeable._afterTokenTransfer(from, to, tokenId, batchSize);
	}

	function _beforeTokenLock(
		address operator,
		address owner,
		uint256 tokenId,
		uint256 expired
	) internal virtual override {
		super._beforeTokenLock(operator, owner, tokenId, expired);
		require(expired == 0 || expired == MAX_EXPIRE_TIME, "Auto expiration is not supported.");

		// Emit events for ERC5192
		if (expired != 0) {
			emit Locked(tokenId);
		} else {
			emit Unlocked(tokenId);
		}
	}

	function _burn(
		uint256 tokenId
	) internal virtual override(ERC721Upgradeable, ERC5058Upgradeable) {
		ERC5058Upgradeable._burn(tokenId);
	}

	function supportsInterface(
		bytes4 interfaceId
	) public view virtual override(BaseWormholeBridgedNft, ERC5058Upgradeable) returns (bool) {
		return
			interfaceId == type(IERC5192).interfaceId ||
			ERC5058Upgradeable.supportsInterface(interfaceId) ||
			BaseWormholeBridgedNft.supportsInterface(interfaceId);
	}

	function tokenURI(
		uint256 tokenId
	)
		public
		view
		virtual
		override(ERC721Upgradeable, BaseWormholeBridgedNft)
		returns (string memory)
	{
		return BaseWormholeBridgedNft.tokenURI(tokenId);
	}
}
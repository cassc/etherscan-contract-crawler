// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {FxBaseRootTunnel} from "./tunnel/FxBaseRootTunnel.sol";
import {IERC721Receiver} from "./lib/IERC721Receiver.sol";

contract FxERC721RootTunnel is FxBaseRootTunnel, IERC721Receiver {
	bytes32 public constant DEPOSIT = keccak256("DEPOSIT");

	event FxDepositERC721(
		address indexed rootToken,
		address indexed depositor,
		address indexed toAddress,
		uint256[] ids
	);
	event FxWithdrawERC721(
		address indexed rootToken,
		address indexed childToken,
		address indexed toAddress,
		uint256[] ids
	);

	mapping(address => address) public rootToChildTokens;

	constructor(
		address checkpointManager,
		address fxRoot,
		address rootToken,
		address childToken
	) FxBaseRootTunnel(checkpointManager, fxRoot) {
		rootToChildTokens[rootToken] = childToken;
	}

	function onERC721Received(
		address, /* operator */
		address, /* from */
		uint256, /* tokenId */
		bytes calldata /* data */
	) external pure override returns (bytes4) {
		return this.onERC721Received.selector;
	}

	function deposit(
		address rootToken,
		uint256[] calldata tokenIds,
		bytes calldata data
	) external {
		_deposit(rootToken, msg.sender, tokenIds, data);
	}

	function depositTo(
		address rootToken,
		address to,
		uint256[] calldata tokenIds,
		bytes calldata data
	) external {
		_deposit(rootToken, to, tokenIds, data);
	}

	function _deposit(
		address rootToken,
		address to,
		uint256[] memory tokenIds,
		bytes memory data
	) internal {
		require(rootToChildTokens[rootToken] != address(0x0), "FxERC721RootTunnel: invalid rootToken");
		require(tokenIds.length > 0 && tokenIds.length <= 20, "FxERC721RootTunnel: must deposit 1-20 tokens");

		for (uint256 i; i < tokenIds.length; i++) {
			// transfer from depositor to this contract
			IERC721(rootToken).safeTransferFrom(
				msg.sender, // depositor
				address(this), // manager contract
				tokenIds[i],
				data
			);
		}

		// DEPOSIT, encode(rootToken, depositor, to, tokenId, extra data)
		bytes memory message = abi.encode(DEPOSIT, abi.encode(rootToken, msg.sender, to, tokenIds, data));
		_sendMessageToChild(message);
		emit FxDepositERC721(rootToken, msg.sender, to, tokenIds);
	}

	// exit processor
	function _processMessageFromChild(bytes memory data) internal override {
		(address rootToken, address childToken, address to, uint256[] memory tokenIds, bytes memory syncData) = abi.decode(
			data,
			(address, address, address, uint256[], bytes)
		);
		// validate mapping for root to child
		require(rootToChildTokens[rootToken] == childToken, "FxERC721RootTunnel: INVALID_MAPPING_ON_EXIT");

		for (uint256 i; i < tokenIds.length; i++) {
			// transfer from this contract to address
			IERC721(rootToken).safeTransferFrom(address(this), to, tokenIds[i], syncData);
		}
	
		emit FxWithdrawERC721(rootToken, childToken, to, tokenIds);
	}
}
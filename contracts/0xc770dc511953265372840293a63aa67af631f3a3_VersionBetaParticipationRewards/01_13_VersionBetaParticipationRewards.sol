//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {SSTORE2} from "./utils/SSTORE2/SSTORE2.sol";
import {ITPLRevealedParts} from "./interfaces/ITPLRevealedParts.sol";
import {ICyberbrokersAccolades} from "./interfaces/ICyberbrokersAccolades.sol";

contract VersionBetaParticipationRewards is Ownable {
	error InvalidParameter();
	error RewardsAlreadyClaimed();
	error InvalidSignature();

	error NoMoreBundles();

	struct ClaimData {
		address recipient;
		uint96 claimable;
	}

	struct Config {
		address bundles;
		uint96 size;
	}

	uint256 public constant BUNDLE_BYTES_LENGTH = 7;

	address public immutable WALLET;
	address public immutable REVEALED_PARTS;
	address public immutable AFTERGLOWS;
	address public immutable ACCOLADES;

	Config public config;

	address public signer;

	mapping(address => uint256) public claimed;

	mapping(uint256 => uint256) internal _bucket;

	constructor(
		address holder,
		address parts,
		address afterglowContract,
		address accolades,
		address initSigner,
		address initConfigHolder,
		uint96 initConfigSize
	) {
		if (
			holder == address(0) || parts == address(0) || afterglowContract == address(0) || initSigner == address(0)
		) {
			revert InvalidParameter();
		}

		WALLET = holder;
		REVEALED_PARTS = parts;
		AFTERGLOWS = afterglowContract;
		ACCOLADES = accolades;

		signer = initSigner;

		if (initConfigHolder != address(0)) {
			config = Config(initConfigHolder, initConfigSize);
		}
	}

	// =============================================================
	//                       	   Interactions
	// =============================================================
	function claim(ClaimData calldata claimData, bytes memory proof) public {
		// and we make sure there are still enough bundle to do that
		uint256 bucketSize = config.size;
		if (bucketSize == 0) {
			revert NoMoreBundles();
		}

		uint256 alreadyClaimed = claimed[claimData.recipient];

		// user already claimed their allocation
		if (alreadyClaimed >= claimData.claimable) {
			revert RewardsAlreadyClaimed();
		}

		bytes32 message = keccak256(abi.encode(claimData));

		// verifies the signature
		if (signer != ECDSA.recover(ECDSA.toEthSignedMessageHash(message), proof)) {
			revert InvalidSignature();
		}

		// we only claim what was not already claimed by the user
		uint256 claimNow = claimData.claimable - alreadyClaimed;

		// else we only claim as many bundles as we can
		if (bucketSize < claimNow) {
			claimNow = bucketSize;
		}

		// updating before _processPick to stop reEntrancy
		claimed[claimData.recipient] = alreadyClaimed + claimNow;
		config.size = uint96(bucketSize - claimNow);

		_processPick(claimData.recipient, claimNow, bucketSize);
	}

	// =============================================================
	//                       	   Owner
	// =============================================================

	function setConfig(bytes calldata data) external onlyOwner {
		config = Config(SSTORE2.write(data), uint96(data.length / BUNDLE_BYTES_LENGTH));
	}

	function setSigner(address newSigner) external onlyOwner {
		signer = newSigner;
	}

	// =============================================================
	//                       	   Internals
	// =============================================================

	function _processPick(address to, uint256 amount, uint256 bucketSize) internal {
		bytes memory ids;
		uint256[] memory partsIds = new uint256[](amount * 3);

		for (uint256 i; i < amount; i++) {
			ids = _pickAtIndex(_pickNextIndex(bucketSize - i));

			// first the parts ids, which are bytes [0:1] [2:3] [4:5]
			partsIds[i * 3] = (uint256(uint8(ids[0])) << 8) + uint256(uint8(ids[1]));
			partsIds[i * 3 + 1] = (uint256(uint8(ids[2])) << 8) + uint256(uint8(ids[3]));
			partsIds[i * 3 + 2] = (uint256(uint8(ids[4])) << 8) + uint256(uint8(ids[5]));

			IERC1155(AFTERGLOWS).safeTransferFrom(WALLET, to, uint256(uint8(ids[6])), 1, "");
		}

		ITPLRevealedParts(REVEALED_PARTS).batchTransferFrom(WALLET, to, partsIds);

		// mint accolade
		address[] memory mintTo = new address[](1);
		mintTo[0] = to;
		ICyberbrokersAccolades(ACCOLADES).mint(mintTo, 2, amount);
	}

	function _pickAtIndex(uint256 index) internal view returns (bytes memory) {
		// where we start to read data in dataHolder
		index = (index - 1) * BUNDLE_BYTES_LENGTH;

		return SSTORE2.read(config.bundles, index, index + BUNDLE_BYTES_LENGTH);
	}

	function _pickNextIndex(uint256 bucketSize) internal returns (uint256 selectedIndex) {
		uint256 seed = uint256(keccak256(abi.encodePacked(block.prevrandao, block.coinbase, bucketSize)));
		uint256 index = 1 + (seed % bucketSize);

		// select value at index
		selectedIndex = _bucket[index];
		if (selectedIndex == 0) {
			// if 0, it was never initialized, so value is index
			selectedIndex = index;
		}

		// if the index picked is not the last one
		if (index != bucketSize) {
			// move last value of the _bucket into the index that was just picked
			uint256 temp = _bucket[bucketSize];
			if (temp != 0) {
				_bucket[index] = temp;
				delete _bucket[bucketSize];
			} else {
				_bucket[index] = bucketSize;
			}
		} else if (index != selectedIndex) {
			// else if the index is the last one, but the value wasn't 0, delete
			delete _bucket[bucketSize];
		}
	}
}
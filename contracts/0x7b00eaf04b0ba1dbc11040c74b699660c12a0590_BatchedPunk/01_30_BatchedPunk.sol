// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TributeBrand.sol";

/// @title Tribute Brand BatchedPunk
/// @author Tribute Brand LLC
/// @notice This contract enables batched minting of Tribute Brand PUNK NFTs.

contract BatchedPunk is Ownable {
    TributeBrand public tributeFactory;
    uint256 public MAX_BATCH_SIZE = 100;

    constructor(TributeBrand _tributeFactory) Ownable() {
	tributeFactory = _tributeFactory;
    }

    function signedMintBatch(
	address to,
	bytes32[] calldata uuids,
	uint256 expiresAt,
	uint256 price,
	bytes[] calldata signatures
    ) external payable {
	require(uuids.length == signatures.length, "incorrect number of uuids/signatures");
	require(uuids.length <= MAX_BATCH_SIZE, "too many mints");
	require(uuids.length * price == msg.value, "incorrect price");

	for (uint256 i = 0; i < uuids.length; i++) {
	    tributeFactory.signedMint{value: price}(to, uuids[i], 0, expiresAt, price, signatures[i]);
	}
    }

    function setMaxBatchSize(uint256 size) external onlyOwner {
	MAX_BATCH_SIZE = size;
    }

    function setTributeFactory(TributeBrand _tributeFactory) external onlyOwner {
	tributeFactory = _tributeFactory;
    }
}
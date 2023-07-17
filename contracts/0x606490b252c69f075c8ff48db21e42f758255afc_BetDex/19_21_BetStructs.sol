// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum SignatureVersion { Single, Bulk }

struct InputBet {
	uint16 target;
	uint32 odds;
	uint256 amount;
	address bettor;
	uint256 matchId;
}

struct Input {
	InputBet[] bets;
	bytes32 roomId;
	uint8 v;
	bytes32 r;
	bytes32 s;
	bytes extraSignature;
	SignatureVersion signatureVersion;
	uint32 timestamp;
	uint256 nonce;
}
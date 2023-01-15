// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library KnowBoxInfo {
	struct MintInfo {
		address minter;
		uint256 counter;
		string cdkey;
		uint8 v;
		bytes32 r;
		bytes32 s;
	}

	struct OpenInfo {
		uint256 token;
		uint256 salt;
		uint8 v;
		bytes32 r;
		bytes32 s;
	}

	struct BoxInfo {
		bool open;
		uint256 dataIndex;
		uint256 openTime;
	}
}
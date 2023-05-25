// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

library DataType {
	enum TokenLocation {
		Operator,
		Other
	}

	enum LockStatus {
		UnLock,
		Lock
	}

	struct AfterParentTokenTransferParams {
		address from;
		address to;
		uint256 tokenId;
		uint256 totalAmountParentLinkSbtContracts;
	}

	struct CreateParentLinkSbtParams {
		string name;
		string symbol;
		string baseUri;
		address ownerAddress;
		address parentContractAddress;
	}
	struct ConnectParentLinkSbtParams {
		uint256 tokenId;
		address parentLinkSbtContract;
		uint256 parentLinkSbtTokenId;
	}

	struct AllStageParams {
		uint256 highSchooler;
		uint256 workingAdult;
		uint256 marriage;
		uint256 family;
		uint256 oldAge;
		uint256 tomb;
	}
}
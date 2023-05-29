// SPDX-License-Identifier: UNLICENSED
// Created by DegenLabs https://bondswap.org

pragma solidity ^0.8.15;

library BondInit {
	// BondContractConfig used as input in creating bonds contract proxy
	struct BondContractConfig {
		string uri;
		uint256 protocolFee; // 5 digit representation,  5000 = 50%, 700 = 7%, 50 = 0.5% etc
		address protocolFeeAddress; // protocol fee address
		address bondToken; // token that we buy bonds for
		uint8 bondTokenDecimals; // decimals for this token
		uint256 bondContractVersion; // implementation contract version
		address bondCreator; // address that created bonds/have permission to create new bond classes
		uint256 bondSymbolNumber; // used in ERC721 bond symbol
	}

	enum LpTokenType {
		NO_LP_TOKEN,
		UNISWAP_LP
	}

	// BondCreationSettings used as user input in BondsFactory
	struct BondCreationSettings {
		address bondToken; // token that we buy bonds for
		uint256 bondContractVersion; // implementation contract version
		address bondCreator; // address that created bonds/have permission to create new bond classes
	}
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
     .d8888b.   .d88888b.  888      .d8888b.  
    d88P  Y88b d88P" "Y88b 888     d88P  Y88b 
    Y88b.      888     888 888          .d88P 
     "Y888b.   888     888 888         8888"  
        "Y88b. 888     888 888          "Y8b. 
          "888 888     888 888     888    888 
    Y88b  d88P Y88b. .d88P 888     Y88b  d88P 
     "Y8888P"   "Y88888P"  88888888 "Y8888P"  
                                          
    Sol3Mates All Rights Reserved 2022
    Developed by DeployLabs.io ([email protected])
*/

import "./library/Neutron.sol";

error Sol3Mates__ZeroAddressProhibited();

error Sol3Mates__NotACrossmintWallet();
error Sol3Mates__CrossmintNotSupportedOnThatStage();

/**
 * @title Sol3Mates
 * @author DeployLabs.io
 *
 * @dev Sol3Mates is a contract for managing airdrops and sales of Sol3Mates NFTs.
 */
contract Sol3Mates is
	Neutron(
		"SOL3MATES OG NFT",
		"SOL3",
		0x67a95d40d901ae1a,
		0x3dD6175Fa612Ca0C95B810E487736108e4E53C1a
	)
{
	uint16 private s_publicSaleStageIndex;
	address private s_crossmintAddress;

	/**
	 * @dev Mint tokens to the specified address through crossmint.io.
	 *
	 * @param mintTo The address to mint the token to.
	 * @param quantity The quantity of tokens to mint.
	 */
	function crossmintMint(address mintTo, uint256 quantity) external payable {
		if (msg.sender != s_crossmintAddress) revert Sol3Mates__NotACrossmintWallet();

		uint16 currentStageIndex = getCurrentSaleStageIndex();
		if (currentStageIndex != s_publicSaleStageIndex)
			revert Sol3Mates__CrossmintNotSupportedOnThatStage();

		uint16 currentStageId = s_saleStageIds[currentStageIndex];
		SaleStageConfig memory config = getSaleStageConfig(currentStageIndex);

		if (msg.value != config.weiTokenPrice * quantity) revert Neutron__WrongEtherAmmount();

		bool exceedingMaxSupply = totalSupply() + quantity > config.supplyLimitByTheEndOfStage;
		bool exceedingLimitPerTransaction = quantity > config.maxTokensPerTransaction;
		bool exceedingLimitPerStage = s_numberMintedDuringStage[currentStageId][mintTo] + quantity >
			config.maxTokensPerWallet;

		if (exceedingMaxSupply) revert Neutron__ExceedingMaxSupply();
		if (exceedingLimitPerStage) revert Neutron__ExceedingTokensPerStageLimit();
		if (exceedingLimitPerTransaction) revert Neutron__ExceedingTokensPerTransactionLimit();

		s_numberMintedDuringStage[currentStageId][mintTo] += quantity;

		_safeMint(mintTo, quantity);
	}

	/**
	 * @dev Set the index of the public sale stage. Used for crossmint sales allowance.
	 *
	 * @param stageIndex The index of the public sale stage.
	 */
	function setPublicSaleStageIndex(uint16 stageIndex) external onlyOwner {
		if (stageIndex >= s_saleStageIds.length) revert Neutron__InvalidSaleStageIndex();

		s_publicSaleStageIndex = stageIndex;
	}

	/**
	 * @dev Set the address of the crossmint.io contract.
	 *
	 * @param crossmintAddress The address of the crossmint.io contract.
	 */
	function setCrossmintAddress(address crossmintAddress) external onlyOwner {
		if (crossmintAddress == address(0)) revert Sol3Mates__ZeroAddressProhibited();

		s_crossmintAddress = crossmintAddress;
	}
}
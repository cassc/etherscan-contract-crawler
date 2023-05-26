// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/*
      _____    _   _   _   _     
     |" ___|U |"|u| | | \ |"|    
    U| |_  u \| |\| |<|  \| |>   
    \|  _|/   | |_| |U| |\  |u   
     |_|     <<\___/  |_| \_|    
     )(\\,- (__) )(   ||   \\,-. 
    (__)(_/     (__)  (_")  (_/  

    Fananees All Rights Reserved 2022
    Developed by DeployLabs.io ([email protected])
*/

import "./library/Neutron.sol";
import "./library/erc721A/extentions/ERC721AQueryable.sol";

import "./staking/IStaking.sol";

error Fananees__ZeroAddressProhibited();
error Fananees__NotAuthorized();

error Fananees__CrossmintNotSupportedOnThatStage();

error Fananees__TokenIsLockedInStaking();

error Fananees__NothingToWithdraw();
error Fananees__WithdrawFailed();

/**
 * @title Fananees
 * @author DeployLabs.io
 *
 * @dev Fananees is a contract for managing airdrops and sales of Fananees NFTs.
 */
contract Fananees is
	Neutron("Fananees", "FUN", 0x01699bb5a7d67fb3, 0x45873Ec03F3B188668E55296f70Fcce656254D3F),
	ERC721AQueryable
{
	uint16 private s_publicSaleStageIndex;
	address private s_crossmintAddress;

	IStaking private s_stakingContract;

	/**
	 * @dev Mint tokens to the specified address through crossmint.io.
	 *
	 * @param mintTo The address to mint the token to.
	 * @param quantity The quantity of tokens to mint.
	 */
	function crossmintMint(address mintTo, uint256 quantity) external payable {
		if (msg.sender != s_crossmintAddress) revert Fananees__NotAuthorized();

		uint16 currentStageIndex = getCurrentSaleStageIndex();
		if (currentStageIndex != s_publicSaleStageIndex)
			revert Fananees__CrossmintNotSupportedOnThatStage();

		uint16 currentStageId = s_saleStageIds[currentStageIndex];
		SaleStageConfig memory config = getSaleStageConfig(currentStageIndex);

		if (msg.value != config.weiTokenPrice * quantity) revert Neutron__WrongEtherAmmount();
		if (totalSupply() + quantity > config.supplyLimitByTheEndOfStage)
			revert Neutron__ExceedingMaxSupply();
		if (
			s_numberMintedDuringStage[currentStageId][mintTo] + quantity > config.maxTokensPerWallet
		) revert Neutron__ExceedingTokensPerStageLimit();

		s_numberMintedDuringStage[currentStageId][mintTo] += quantity;

		_safeMint(mintTo, quantity);
	}

	/**
	 * @dev Set the index of the public sale stage. Used for crossmint sales allowance.
	 *
	 * @param stageIndex The index of the public sale stage.
	 */
	function setPublicSaleStageIndex(uint16 stageIndex) external onlyManager {
		if (stageIndex >= s_saleStageIds.length) revert Neutron__InvalidSaleStageIndex();

		s_publicSaleStageIndex = stageIndex;
	}

	/**
	 * @dev Set the address of the crossmint.io contract.
	 *
	 * @param crossmintAddress The address of the crossmint.io contract.
	 */
	function setCrossmintAddress(address crossmintAddress) external onlyManager {
		if (crossmintAddress == address(0)) revert Fananees__ZeroAddressProhibited();

		s_crossmintAddress = crossmintAddress;
	}

	/**
	 * @dev Set the staking contract.
	 *
	 * @param stakingContract The address of the staking contract.
	 */
	function setStakingContract(IStaking stakingContract) external onlyManager {
		if (address(stakingContract) == address(0)) revert Fananees__ZeroAddressProhibited();

		s_stakingContract = stakingContract;
	}

	/**
	 * @dev Withdraw money from the contract. Only a payout wallet can call this function.
	 *
	 * @param to The address to send the money to.
	 */
	function withdrawMoney(address payable to) external onlyOwner {
		(bool success, ) = to.call{ value: address(this).balance }("");
		if (!success) revert Fananees__WithdrawFailed();
	}

	// Override to prevent tokens from being moved when they are being staked.
	/// @inheritdoc ERC721A
	function _beforeTokenTransfers(
		address from,
		address to,
		uint256 startTokenId,
		uint256 quantity
	) internal override {
		super._beforeTokenTransfers(from, to, startTokenId, quantity);

		bool isStakingContractSet = address(s_stakingContract) != address(0x0);
		if (!isStakingContractSet) return;

		for (uint256 tokenId = startTokenId; tokenId < startTokenId + quantity; tokenId++) {
			if (s_stakingContract.isTokenStaked(tokenId)) revert Fananees__TokenIsLockedInStaking();
		}
	}

	/// @inheritdoc Neutron
	function _startTokenId() internal view virtual override(Neutron, ERC721A) returns (uint256) {
		return super._startTokenId();
	}

	/// @inheritdoc Neutron
	function _baseURI() internal view virtual override(Neutron, ERC721A) returns (string memory) {
		return super._baseURI();
	}
}
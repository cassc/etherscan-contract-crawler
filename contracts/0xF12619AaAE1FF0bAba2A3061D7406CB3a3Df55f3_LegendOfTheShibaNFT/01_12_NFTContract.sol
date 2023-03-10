// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


// $$\                                                    $$\ 
// $$ |                                                   $$ |
// $$ |      $$$$$$\   $$$$$$\   $$$$$$\  $$$$$$$\   $$$$$$$ |
// $$ |     $$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  __$$ |
// $$ |     $$$$$$$$ |$$ /  $$ |$$$$$$$$ |$$ |  $$ |$$ /  $$ |
// $$ |     $$   ____|$$ |  $$ |$$   ____|$$ |  $$ |$$ |  $$ |
// $$$$$$$$\\$$$$$$$\ \$$$$$$$ |\$$$$$$$\ $$ |  $$ |\$$$$$$$ |
// \________|\_______| \____$$ | \_______|\__|  \__| \_______|
//                    $$\   $$ |                              
//                    \$$$$$$  |                              
//                     \______/                               
//            $$$$$$\          $$\     $$\                    
//           $$  __$$\         $$ |    $$ |                   
//  $$$$$$\  $$ /  \__|      $$$$$$\   $$$$$$$\   $$$$$$\     
// $$  __$$\ $$$$\           \_$$  _|  $$  __$$\ $$  __$$\    
// $$ /  $$ |$$  _|            $$ |    $$ |  $$ |$$$$$$$$ |   
// $$ |  $$ |$$ |              $$ |$$\ $$ |  $$ |$$   ____|   
// \$$$$$$  |$$ |              \$$$$  |$$ |  $$ |\$$$$$$$\    
//  \______/ \__|               \____/ \__|  \__| \_______|   
//                                                           
//                                                           
//                                                           
//  $$$$$$\  $$\       $$\ $$\                                
// $$  __$$\ $$ |      \__|$$ |                               
// $$ /  \__|$$$$$$$\  $$\ $$$$$$$\   $$$$$$\                 
// \$$$$$$\  $$  __$$\ $$ |$$  __$$\  \____$$\                
//  \____$$\ $$ |  $$ |$$ |$$ |  $$ | $$$$$$$ |               
// $$\   $$ |$$ |  $$ |$$ |$$ |  $$ |$$  __$$ |               
// \$$$$$$  |$$ |  $$ |$$ |$$$$$$$  |\$$$$$$$ |               
//  \______/ \__|  \__|\__|\_______/  \_______|


// ___  ____       _            
// |  \/  (_)     | |           
// | .  . |_ _ __ | |_ ___ _ __ 
// | |\/| | | '_ \| __/ _ \ '__|
// | |  | | | | | | ||  __/ |   
// \_|  |_/_|_| |_|\__\___|_|


/**
 * @title Yin Yang Gang: Legend of the Shiba minter contract
 * @author @Xirynx
 * @notice NFT minter for season 1 of Dysto Inc. Missions
 */
contract LegendOfTheShibaNFT is ERC721A("Yin Yang Gang: Legend of the Shiba", "LotS"), Ownable, DefaultOperatorFilterer {

	//============================================//
	//                  Errors                    //   
	//============================================//

	error MaxSupplyExceeded();
	error AddressNotManager();

	//============================================//
	//              State Variables               //        
	//============================================//

	uint256 public MAX_SUPPLY = 2000;
	string internal baseURI;
	mapping(address => bool) public managers;

	//============================================//
	//                 Modifiers                  //        
	//============================================//

	/**
	 * @notice Verifies that the caller is currently a manager
	 * @dev Reverts if the caller is not a manager and not the contract owner
	 */
	modifier onlyManager() {
		if (!managers[msg.sender] && msg.sender != owner()) revert AddressNotManager();
		_;
	}

	//============================================//
	//              Admin Functions               //        
	//============================================//

    /** 
	 * @notice Flips manager status of `wallet` between true and false
	 * @dev Caller must be contract owner
     * @param wallet Address to set/unset as manager
	 */
	function toggleManager(address wallet) external onlyOwner {
		managers[wallet] = !managers[wallet];
	}

    /** 
	 * @notice Sets the base uri for token metadata
	 * @dev Caller must be contract owner
     * @param newURI New base uri for token metadata
	 */
	function setBaseURI(string memory newURI) external onlyOwner {
		baseURI = newURI;
	}

    /**
	 * @notice Withdraws entire ether balance in the contract to the wallet specified
	 * @dev Caller must be contract owner
	 * @param to Address to send ether balance to
	 */
	function withdrawFunds(address to) public onlyOwner {
        	uint256 balance = address(this).balance;
        	(bool callSuccess, ) = payable(to).call{value: balance}("");
        	require(callSuccess, "Call failed");
    }

	//============================================//
	//                Minting Logic               //        
	//============================================//

	/**
	 * @notice Mints `amount` tokens to `to` address
	 * @dev Caller must be part of `managers` mapping
	 *		Total supply must be less than or equal to `MAX_SUPPLY` after mint
	 * @param to Address to send NFTs to
	 * @param amount Amount of NFTs to mint
	 */
	function mint(address to, uint256 amount) external onlyManager returns (uint256[] memory) {
		if (amount + _totalMinted() > MAX_SUPPLY) revert MaxSupplyExceeded();
		uint256[] memory tokenIds = new uint256[](amount);
		uint256 firstMinted = _nextTokenId();
		for (uint256 i = 0; i < amount; i++) {
			tokenIds[i] = firstMinted + i;
		}
		_mint(to, amount);
		return tokenIds;
	}

	//============================================//
	//              ERC721 Overrides              //        
	//============================================//

	/**
	 * @notice Overridden to return variable `baseURI` rather than constant string. Allows for flexibility to alter metadata in the future.
	 * @return string the current value of `baseURI`
	 */
	function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

	//============================================//
	//         Opensea Registry Overrides         //        
	//============================================//
	
	function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
		super.setApprovalForAll(operator, approved);
	}

	function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
		super.approve(operator, tokenId);
	}

	function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
		super.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
		public
		payable
		override
		onlyAllowedOperator(from)
	{
		super.safeTransferFrom(from, to, tokenId, data);
	}
}
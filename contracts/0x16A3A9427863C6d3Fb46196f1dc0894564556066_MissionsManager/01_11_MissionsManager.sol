// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
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


// ___  ___                                  
// |  \/  |                                  
// | .  . | __ _ _ __   __ _  __ _  ___ _ __ 
// | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|
// | |  | | (_| | | | | (_| | (_| |  __/ |   
// \_|  |_/\__,_|_| |_|\__,_|\__, |\___|_|   
//                            __/ |          
//                           |___/

/**
 * @title Yin Yang Gang: Legend of the Shiba mission manager contract
 * @author @Xirynx
 * @notice Manager Contract for Missions Backend
 */
interface MinterContract {
	function mint(address to, uint256 amount) external returns (uint256[] memory tokenIds);
}

interface YinYangGang {
	function ownerOf(uint256 tokenId) external view returns (address);
	function burn(uint256 tokenId) external;
}

contract MissionsManager is Ownable {

	//============================================//
	//                Definitions                 //      
	//============================================//

	using ECDSA for bytes;

	//============================================//
	//                  Errors                    //   
	//============================================//

	error InvalidAmount();
	error InvalidBurnAmount();
	error InsufficientETH();
	error InsufficientETHSupply();
	error InsufficientSCSupply();
	error InsufficientBurnSupply();
	error UnauthorisedBurner();
	error UnauthorisedSignature();

	//============================================//
	//                  Events                    //   
	//============================================//

	event PassClaimed(address indexed owner, uint256 indexed season);
	event PackMint(uint256 indexed uniqueId, address indexed owner, uint256[] tokenIds, string method);

	//============================================//
	//              State Variables               //        
	//============================================//

	uint256 public constant ETH_PRICE = 0.0252 ether;
	uint256 public constant ETH_SUPPLY = 500;
	uint256 public constant SC_SUPPLY = 1000;
	uint256 public constant BURN_SUPPLY = 500;
	address public signer;
	YinYangGang yygContract;
	MinterContract minterContract;
	uint256 public totalSupplyETH;
	uint256 public totalSupplySC;
	uint256 public totalSupplyBurn;
	mapping(address => uint256) public nonces;

	//============================================//
	//              Admin Functions               //        
	//============================================//
	
	/**
	 * @notice Sets the new `signer` that will verify all mints and burns
	 * @dev Caller must be owner
	 * @param _newSigner New signer wallet address
	 */
	function setSigner(address _newSigner) public onlyOwner {
		signer = _newSigner;
	}

	/**
	 * @notice Sets the Yin Yang Gang contract address to carry out burning logic
	 * @dev Caller must be owner
	 * @param _contract Yin Yang Gang contract address
	 */
	function setYYG(address _contract) public onlyOwner {
		yygContract = YinYangGang(_contract);
	}

	/**
	 * @notice Sets the minter contract address which will handle minting NFTs
	 * @dev Caller must be owner
	 * @param _contract Minter contract address
	 */
	function setMinter(address _contract) public onlyOwner {
		minterContract = MinterContract(_contract);
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
	//               Access Control               //        
	//============================================//

	/**
	 * @notice Verifies that a message was signed by the current `signer` wallet
	 * @param _data Bytes encoded message data
	 * @param _signature Signed message data
	 * @return bool True if `_data` was signed by `signer`, false otherwise
	 */
	function verifySigner(bytes memory _data, bytes memory _signature) public view returns (bool) {
		bytes32 _hash = _data.toEthSignedMessageHash();
		if (ECDSA.recover(_hash, _signature) != signer) return false;
		return true;
	}

	//============================================//
	//                Minting Logic               //        
	//============================================//

	/**
	 * @notice Burns 4 Yin Yang Gang NFTs, claims a burn pass, and mints 1 pack to the burner's wallet
	 * @dev `_ids` length must be exactly 4
	 * `totalSupplyBurn` must be strictly less than `BURN_SUPPLY`
	 * Every token being burnt must be owned by the caller
	 * `_signature` must prove that the given parameters are valid
	 *
	 * Emits {PassClaimed}
	 * Emits {PackMint}
	 * @param _uniqueId Burner's unique ID
	 * @param _season Season for which burn takes place
	 * @param _ids Array of token IDs specifying which Yin Yang Gang NFTs to burn
	 * @param _signature Signed message data. Data consists of { address msg.sender, uint256 _uniqueId, uint256 userNonce, string 'BURN', uint256[] _ids } in that order.
	 */
	function claimBurnPass(uint256 _uniqueId, uint256 _season, uint256[] memory _ids, bytes memory _signature) external {
		if (_ids.length != 4) revert InvalidBurnAmount();
		if (totalSupplyBurn >= BURN_SUPPLY) revert InsufficientBurnSupply();
		uint256 userNonce = nonces[msg.sender];
		bytes memory signData = abi.encode(msg.sender, _uniqueId, userNonce, 'BURN', _ids);
		if (!verifySigner(signData, _signature)) revert UnauthorisedSignature();
		for (uint256 i = 0; i < _ids.length; i++) {
			if (yygContract.ownerOf(_ids[i]) != msg.sender) revert UnauthorisedBurner();
		}

		nonces[msg.sender]++;
		for (uint256 i = 0; i < _ids.length; i++) {
			yygContract.burn(_ids[i]);
		}
		uint256[] memory tokenIds = minterContract.mint(msg.sender, 1);

		emit PassClaimed(msg.sender, _season);
		emit PackMint(_uniqueId, msg.sender, tokenIds, 'BURN');
	}

	/**
	 * @notice Mints `_amount` packs to the caller's wallet
	 * @dev `_amount` cannot be 0
	 * `msg.value` must be greater than or equal to `amount * ETH_PRICE`
	 * `totalSupplyETH` must be strictly less than `ETH_SUPPLY`
	 * `_signature` must prove that the given parameters are valid
	 *
	 * Emits {PackMint}
	 * @param _uniqueId Minters's unique ID
	 * @param _amount Number of tokens to mint
	 * @param _signature Signed message data. Data consists of { address msg.sender, uint256 _uniqueId, uint256 userNonce, string 'ETH', uint256 _amount } in that order.
	 */
	function purchasePackETH(uint256 _uniqueId, uint256 _amount, bytes memory _signature) external payable {
		if (_amount == 0) revert InvalidAmount();
		if (msg.value <  _amount * ETH_PRICE) revert InsufficientETH();
		if (totalSupplyETH >= ETH_SUPPLY) revert InsufficientETHSupply();
		uint256 userNonce = nonces[msg.sender];
		bytes memory signData = abi.encode(msg.sender, _uniqueId, userNonce, 'ETH', _amount);
		if (!verifySigner(signData, _signature)) revert UnauthorisedSignature();

		nonces[msg.sender]++;
		totalSupplyETH++;
		uint256[] memory tokenIds = minterContract.mint(msg.sender, _amount);

		emit PackMint(_uniqueId, msg.sender, tokenIds, 'ETH');
	}

	/**
	 * @notice Mints `_amount` packs to the caller's wallet
	 * @dev `_amount` cannot be 0
	 * `totalSupplySC` must be strictly less than `SC_SUPPLY`
	 * `_signature` must prove that the given parameters are valid
	 *
	 * Emits {PackMint}
	 * @param _uniqueId Minters's unique ID
	 * @param _amount Number of tokens to mint
	 * @param _signature Signed message data. Data consists of { address msg.sender, uint256 _uniqueId, uint256 userNonce, string 'SC', uint256 _amount } in that order.
	 */
	function purchasePackSC(uint256 _uniqueId, uint256 _amount, bytes memory _signature) external {
		if (_amount == 0) revert InvalidAmount();
		if (totalSupplySC >= SC_SUPPLY) revert InsufficientSCSupply();
		uint256 userNonce = nonces[msg.sender];
		bytes memory signData = abi.encode(msg.sender, _uniqueId, userNonce, 'SC', _amount);
		if (!verifySigner(signData, _signature)) revert UnauthorisedSignature();

		nonces[msg.sender]++;
		totalSupplySC++;
		uint256[] memory tokenIds = minterContract.mint(msg.sender, _amount);

		emit PackMint(_uniqueId, msg.sender, tokenIds, 'SC');
	}
}
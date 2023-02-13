// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

 /*
 ______   ______     ______     __  __     __         ______     ______     ______    
/\  == \ /\  == \   /\  __ \   /\_\_\_\   /\ \       /\  __ \   /\  == \   /\  ___\   
\ \  _-/ \ \  __<   \ \ \/\ \  \/_/\_\/_  \ \ \____  \ \  __ \  \ \  __<   \ \___  \  
 \ \_\    \ \_\ \_\  \ \_____\   /\_\/\_\  \ \_____\  \ \_\ \_\  \ \_____\  \/\_____\ 
  \/_/     \/_/ /_/   \/_____/   \/_/\/_/   \/_____/   \/_/\/_/   \/_____/   \/_____/ 

*/

contract CollectingMetaUpgrade is IERC721Receiver, Ownable, ReentrancyGuard{

	ERC721 public cm;
	address private signer;
	address private prox;
	address private withdrawWallet;

 	uint256[] public goldTokens;
	uint256[] public royalTokens;
	uint256 public goldIndex = 0;
	uint256 public royalIndex = 0;
	uint256 public goldCost = 0.02 ether;
	uint256 public royalCost = 0.02 ether;
	bool public goldPaused = false;
	bool public royalPaused = false;

	constructor(address cm_address, uint256[] memory _goldTokens, uint256[] memory _royalTokens, address _signer, address _prox) IERC721Receiver(){
		cm = ERC721(cm_address);
		goldTokens = _goldTokens;
		royalTokens = _royalTokens;
		signer = _signer;
		prox = _prox;
		withdrawWallet = msg.sender;
	}

	function goldUpgrade(uint256[] calldata tokenIds, bytes calldata sig) external payable nonReentrant{
		require(goldPaused == false, "Gold upgrade paused");
		require(msg.value == goldCost, "Not enough eth");
		require(goldIndex < goldTokens.length, "Gold upgrade currently unavailable");
		require(tokenIds.length == 3, 'Invalid number of tokens');
		validateSig(tokenIds, sig);
		tokenOwnerCheck(tokenIds);
		require(cm.isApprovedForAll(msg.sender, address(this)) == true, 'Contract not approved for transfer');
		transferNFT(tokenIds);
		cm.transferFrom(address(this), msg.sender, goldTokens[goldIndex]);
		goldIndex += 1;
	}

	function royalUpgrade(uint256[] calldata tokenIds, bytes calldata sig) external payable nonReentrant{
		require(royalPaused == false, "Royal upgrade paused");
		require(msg.value == royalCost, "Not enough eth");
		require(royalIndex < royalTokens.length, "Royal upgrade currently unavailable");
		require(tokenIds.length == 10, 'Invalid number of tokens');
		validateSig(tokenIds, sig);
		tokenOwnerCheck(tokenIds);
		require(cm.isApprovedForAll(msg.sender, address(this)) == true, 'Contract not approved for transfer');
		transferNFT(tokenIds);
		cm.transferFrom(address(this), msg.sender, royalTokens[royalIndex]);
		royalIndex += 1;
	}

	function tokenOwnerCheck(uint256[] calldata tokenIds) private view{
		for(uint i = 0; i < tokenIds.length; i++){
			require(cm.ownerOf(tokenIds[i]) == msg.sender, 'Sender is not owner of all tokens');
		}
	}

	function transferNFT(uint256[] calldata tokenIds) private{
		for(uint i = 0; i < tokenIds.length; i++){
			cm.transferFrom(msg.sender, address(this), tokenIds[i]);
		}
	}

	function validateSig(uint256[] calldata tokenIds, bytes calldata sig) private view{
		bytes32 hash =  ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(tokenIds)));
		address txSigner = ECDSA.recover(hash, sig);
		require(txSigner == signer, "Invalid signature");
	}

	function changeSigner(address _signer) external{
		require(msg.sender == signer, "Sender not signer");
		signer = _signer;
	}

	function updateGoldCost(uint256 cost) external onlyOwner{
		goldCost = cost;
	}

	function updateRoyalCost(uint256 cost) external onlyOwner{
		royalCost = cost;
	}

	function setGoldPause(bool paused) external onlyOwner{
		goldPaused = paused;
	}

	function setRoyalPause(bool paused) external onlyOwner{
		royalPaused = paused;
	}

	function setWithdawWallet(address wallet) external onlyOwner{
		withdrawWallet = wallet;
	}

	function addGoldTokens(uint256[] memory tokens) external onlyOwner{
		for(uint i = 0; i < tokens.length; i++){
			goldTokens.push(tokens[i]);
		}
	}

	function addRoyalTokens(uint256[] memory tokens) external onlyOwner{
		for(uint i = 0; i < tokens.length; i++){
			royalTokens.push(tokens[i]);
		}
	}

	function withdraw() external onlyOwner{
		uint256 balance = address(this).balance;
		payable(withdrawWallet).transfer((balance * 85) / 100);
		payable(prox).transfer((balance * 15) / 100);
	}

	function onERC721Received(address operator, address, uint, bytes calldata) external view override returns (bytes4) {
		if (operator == address(this)) {
			return this.onERC721Received.selector;
		}
		else {
			return 0x00000000;
		}
	}
}
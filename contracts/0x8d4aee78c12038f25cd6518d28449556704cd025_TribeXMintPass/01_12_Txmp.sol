// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

/*
  _______   _ _         __   __           
 |__   __| (_) |        \ \ / /           
    | |_ __ _| |__   ___ \ V /            
    | | '__| | '_ \ / _ \ > <             
    | | |  | | |_) |  __// . \            
  __|_|_|_ |_|_.__/ \___/_/_\_\           
 |  \/  (_)     | |   |  __ \             
 | \  / |_ _ __ | |_  | |__) |_ _ ___ ___ 
 | |\/| | | '_ \| __| |  ___/ _` / __/ __|
 | |  | | | | | | |_  | |  | (_| \__ \__ \
 |_|  |_|_|_| |_|\__| |_|   \__,_|___/___/                           
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TribeXMintPass is ERC721, Ownable, ReentrancyGuard {
	address public CROSSMINT_ADDRESS = 0xdAb1a1854214684acE522439684a145E62505233;
	address public TRIBEX_COLD_ADDRESS = 0xaBffc43Bafd9c811a351e7051feD9d8be2ad082f;

	string public wholeURI;

	uint256 public costPublicSale = 0.15 ether;
	uint256 public costCrossmint = 0.15 ether;

	uint16 public totalSupply = 0;
	uint16 public maxSupply = 5000;
	uint16 public maxMintAmount = 12;

	bool public paused = false;

	constructor(
		string memory _name,
		string memory _symbol,
		string memory _initWholeURI
	) ERC721(_name, _symbol) {
		setWholeURI(_initWholeURI);
	}

	//MINTING for PublicSale
	function mintPublicSale(uint8 _mintAmount) external payable {
		require(_mintAmount <= maxMintAmount, "Max allowed mint amount exceeded for PublicSale");
		require(msg.value >= costPublicSale * _mintAmount, "Insufficient ETH amount");

		_mintInternal(msg.sender, _mintAmount);
	}

	//MINTING for Crossmint
	function mintCrossmint(address _mintToAddress, uint8 _mintAmount) external payable {
		require(msg.sender == CROSSMINT_ADDRESS, "This function is for Crossmint only.");
		require(msg.value >= costCrossmint * _mintAmount, "Insufficient ETH amount");

		_mintInternal(_mintToAddress, _mintAmount);
	}

	//MINTING for onlyOwner
	function mintOnlyOwner(address _mintToAddress, uint8 _mintAmount) external payable onlyOwner {
		_mintInternal(_mintToAddress, _mintAmount);
	}

	//INTERNAL mint
	function _mintInternal(address _mintToAddress, uint8 _mintAmount) internal {
		require(!paused, "Please wait until unpaused");
		require(_mintAmount > 0, "Need to mint more than 0");
		require(totalSupply + _mintAmount <= maxSupply, "Not enough NFTs left to mint that many!");
		for (uint8 i = 1; i <= _mintAmount; i++) {
			incrementTotalSupply();
			_safeMint(_mintToAddress, totalSupply);
		}
	}

	function incrementTotalSupply() internal {
		totalSupply += 1;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "tokenId does not exist");
		return wholeURI;
	}

	//--------ONLY OWNER--------//

	//SETTERS FOR ADDRESSES
	function setCrossmintAddress(address _newCrossmintAddress) public onlyOwner {
		CROSSMINT_ADDRESS = _newCrossmintAddress;
	}

	function setTribexColdAddress(address newTribexColdAddress) public onlyOwner {
		TRIBEX_COLD_ADDRESS = newTribexColdAddress;
	}

	//SETTERS FOR STRINGS
	function setWholeURI(string memory _newWholeURI) public onlyOwner {
		wholeURI = _newWholeURI;
	}

	//SETTERS FOR COSTS
	function setCostPublicSale(uint256 _newCostPublicSale) public onlyOwner {
		costPublicSale = _newCostPublicSale;
	}

	function setCostCrossMint(uint256 _costCrossmint) public onlyOwner {
		costCrossmint = _costCrossmint;
	}

	//SETTERS FOR MAXSUPPLY
	function setMaxSupply(uint16 _newMaxSupply) public onlyOwner {
		maxSupply = _newMaxSupply;
	}

	//SETTERS FOR MAXMINTAMOUNT
	function setMaxMintAmount(uint16 _newMaxMintAmount) public onlyOwner {
		maxMintAmount = _newMaxMintAmount;
	}

	//SETTERS FOR PAUSED
	function pause() public onlyOwner {
		paused = true;
	}

	function unpause() public onlyOwner {
		paused = false;
	}

	//WITHDRAWALS
	function withdraw() public payable onlyOwner nonReentrant {
		// ================This will pay 100%=========================
		(bool coldsuccess, ) = payable(TRIBEX_COLD_ADDRESS).call{value: address(this).balance}("");
		require(coldsuccess);
		// ====================================================================

		// This will payout the OWNER the remainder of the contract balance if any left.
		(bool os, ) = payable(owner()).call{value: address(this).balance}("");
		require(os);
		// =====================================================================
	}
}
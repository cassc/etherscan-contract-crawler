// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
// 1. Import
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

// error NftMain_SentEthLessThanZeroPointZeroOne();
// error NftMain_ContractAlreadyInitialized();
error NftMain_TokenGreaterOrEqualMaxCounter();

contract NftMain is ERC721URIStorage {
	// 1. Type Declarations
	// using Strings for uint256;

	// 2. State variables
	uint256 public constant TOKEN_MAX_COUNTER = 20;
	// uint256 public constant MIN_NFT_MINT_FEE = 0.001 * 1e18;

	uint256 public tokenCounter;
	address private _owner;
	string[] private tokenUriList;
	// bool private initialized;

	// 3. Events
	event NftMinted(uint256 indexed tokenId, address minter);

	// 4. Modifiers
	// 5. Functions
	// 5.1 constructor
	constructor(string[] memory _originUriList) ERC721("AvatarAlpha", "AALP") {
		tokenCounter = 0;
        _owner = _msgSender();
		tokenUriList = _originUriList;
		// _initializeContract(_originUriList);
	}

	// 5.2 receive
	// receive() external payable {
	// 	mintNft();
	// }

	// 5.3 fallback
	// fallback() external payable {
	// 	mintNft();
	// }

	// 5.4 external
	// 5.5 public
	function mintNft() public payable returns (uint256) {
		// if (msg.value < MIN_NFT_MINT_FEE) {
		// 	revert NftMain_SentEthLessThanZeroPointZeroOne();
		// }
		if (tokenCounter >= TOKEN_MAX_COUNTER) {
			revert NftMain_TokenGreaterOrEqualMaxCounter();
		}
		_safeMint(msg.sender, tokenCounter);
		_setTokenURI(tokenCounter, tokenUriList[tokenCounter]);
		emit NftMinted(tokenCounter, msg.sender);
		tokenCounter += 1;
		return tokenCounter;
	}

	function withdraw() public {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");

		uint256 amount = address(this).balance;
		(bool success, ) = payable(msg.sender).call{value: amount}("");
		require(success, "Transfer Failed");
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}

	function getTokenCounter() public view returns (uint256) {
		return tokenCounter;
	}

	// 5.6 internal
	// 5.7 private
	// function _initializeContract(string[] memory _originUriList) private {
	// 	if (initialized) {
	// 		revert NftMain_ContractAlreadyInitialized();
	// 	}
	// 	_owner = _msgSender();
	// 	tokenUriList = _originUriList;
	// 	initialized = true;
	// }
}
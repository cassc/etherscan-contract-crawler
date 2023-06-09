// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721AQueryable.sol";

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣰⣾⣿⣿⣿⣦⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣧⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠈⠻⢿⣿⣿⣿⣿⣿⣿⠿⠟⠋⠁⠀⠀⠀⠀⠀⢀⣀⣤⣤⣀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠀⣤⣤⣶⣾⣷⡀⠀⠀⢀⣴⣾⣿⣿⣿⣿⣿⣧⠀⠀
// ⠀⠀⣴⣿⣷⣦⣄⠀⠀⠀⠀⣿⣿⣿⣿⣿⣷⠀⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⣇⠀
// ⠀⣸⣿⣿⣿⣿⡿⠆⠀⠀⠀⢿⣿⣿⣿⣿⣿⠀⠀⠀⠈⠛⠿⣿⣿⣿⣿⣿⡿⠀
// ⠀⢻⡿⠟⢉⣀⠀⠀⠀⠀⠀⠀⠉⠛⠛⠋⠁⠀⠀⠀⠀⢰⣦⣄⣈⣉⠉⠉⠀⠀
// ⠀⠀⠀⠀⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⣿⡟⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀
contract Funga is ERC721AQueryable, Ownable, ReentrancyGuard {
	using Address for address;
	using Strings for uint256;
	using MerkleProof for bytes32[];

	bytes32 public root = 0x7c692400d56fcdbe35a9ab6933326ccdf822412b680833be042823276f31ed97;
	bytes32 public root2 = 0x36f1900eacdb519374318bda0cec0eaeeda00af629e66d8dd58c5965e0bc0996;

	string public _contractBaseURI = "https://funga-backend.funga.io/contract_uri";
	string public _contractURI = "https://funga-backend.funga.io/metadata/";

	uint256 public maxSupply = 3333;
	uint256 public preSaleSupply = 1500;

	uint256 public presale1StartTime = 1659196800;
	uint256 public presale2StartTime = 1659198600;
	uint256 public publicStartTime = 1659200400;

	mapping(address => uint256) public usedAddresses;

	modifier notContract() {
		require(!_isContract(msg.sender), "not allowed");
		require(msg.sender == tx.origin, "proxy not allowed");
		_;
	}

	constructor() ERC721A("Funga", "FUNGA") {}

	/**
	 @dev only whitelisted can get one
	 @param proof - merkle proof
	  */
	function presale1Get(bytes32[] calldata proof) external nonReentrant notContract {
		require(usedAddresses[msg.sender] + 1 <= 1, "wallet limit reached");
		require(block.timestamp >= presale1StartTime, "not live");
		require(totalSupply() + 1 <= preSaleSupply, "out of stock");
		require(isProofValid(msg.sender, 1, proof), "invalid proof");

		usedAddresses[msg.sender] += 1;
		_mint(msg.sender, 1);
	}

	/**
	 @dev only whitelisted (part 2) can get one
	 @param proof - merkle proof
	  */
	function presale2Get(bytes32[] calldata proof) external nonReentrant notContract {
		require(usedAddresses[msg.sender] + 1 <= 1, "wallet limit reached");
		require(block.timestamp >= presale2StartTime, "not live");
		require(totalSupply() + 1 <= maxSupply, "out of stock");
		require(isProofValid2(msg.sender, 1, proof), "invalid proof");

		usedAddresses[msg.sender] += 1;
		_mint(msg.sender, 1);
	}

	/**
	 @dev everyone can get one even if you're not whitelisted
	  */
	function publicGet() external nonReentrant notContract {
		require(block.timestamp >= publicStartTime, "not live");
		require(totalSupply() + 1 <= maxSupply, "out of stock");
		require(usedAddresses[msg.sender] + 1 <= 1, "wallet limit reached");

		usedAddresses[msg.sender] += 1;
		_mint(msg.sender, 1);
	}

	/**
	 @dev admin mint
	 @param to - destination
	 @param qty - quantity
	  */
	function adminMint(address to, uint16 qty) external onlyOwner {
		require(qty < 21, "max 20 at once");
		_mint(to, qty);
	}

	/**
	 * READ FUNCTIONS
	 */
	function exists(uint256 _tokenId) external view returns (bool) {
		return _exists(_tokenId);
	}

	// function tokenURI(uint256 _tokenId) public view override returns (string memory) {
	// 	require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

	// }

	function tokenURI(uint256 _tokenId)
		public
		view
		override(ERC721A, IERC721A)
		returns (string memory)
	{
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_contractBaseURI, _tokenId.toString(), ".json"));
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	//merkle root check
	function isProofValid(
		address to,
		uint256 limit,
		bytes32[] memory proof
	) public view returns (bool) {
		bytes32 leaf = keccak256(abi.encodePacked(to, limit));
		return proof.verify(root, leaf);
	}

	//merkle root check
	function isProofValid2(
		address to,
		uint256 limit,
		bytes32[] memory proof
	) public view returns (bool) {
		bytes32 leaf = keccak256(abi.encodePacked(to, limit));
		return proof.verify(root2, leaf);
	}

	/**
	 * ADMIN FUNCTIONS
	 */
	function setImportantURIs(
		string memory newBaseURI,
		string memory newContractURI,
		string memory newUnrevealed
	) external onlyOwner {
		_contractBaseURI = newBaseURI;
		_contractURI = newContractURI;
	}

	//recover lost erc20. getting them back chance: very low
	function reclaimERC20Token(address erc20Token) external onlyOwner {
		IERC20(erc20Token).transfer(msg.sender, IERC20(erc20Token).balanceOf(address(this)));
	}

	//recover lost nfts. getting them back chance: very low
	function reclaimERC721(address erc721Token, uint256 id) external onlyOwner {
		IERC721(erc721Token).safeTransferFrom(address(this), msg.sender, id);
	}

	//contract doesn't accept eth, so this is not used
	function withdrawETH() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	//change the presale start time
	function setStartTimes(
		uint256 presale1,
		uint256 presale2,
		uint256 publicSale
	) external onlyOwner {
		presale1StartTime = presale1;
		presale2StartTime = presale2;
		publicStartTime = publicSale;
	}

	//999 = sold out, 0 = not started, 1 = whitelist 1, 2 = whitelist 2, 3 = public
	function getStage() public view returns (uint256) {
		if (totalSupply() >= maxSupply) {
			return 999;
		}
		if (block.timestamp >= publicStartTime) {
			return 3;
		}
		if (block.timestamp >= presale2StartTime) {
			return 2;
		}
		if (block.timestamp >= presale1StartTime) {
			return 1;
		}
		return 0;
	}

	//only decrease it, no funky stuff
	function decreaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
		require(newMaxSupply < maxSupply, "decrease only");
		maxSupply = newMaxSupply;
	}

	//call this to reveal the jpegs
	function setBaseURI(string memory newBaseURI) external onlyOwner {
		_contractBaseURI = newBaseURI;
	}

	function setMerkleRoot(bytes32 _root, bytes32 _root2) external onlyOwner {
		root = _root;
		root2 = _root2;
	}

	//anti-bot
	function _isContract(address _addr) private view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(_addr)
		}
		return size > 0;
	}

	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	function buildNumber4() internal view {}
}
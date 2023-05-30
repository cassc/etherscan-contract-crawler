// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract RarePanthers is ERC721Enumerable, Ownable, PaymentSplitter {
	using Address for address;
	using Strings for uint256;
	using MerkleProof for bytes32[];
	using Counters for Counters.Counter;

	/**
	 * @notice Input data root, Merkle tree root for an array of (address, tokenId) pairs,
	 *      available for minting
	 */
	bytes32 public root;

	string public _contractBaseURI = "https://api.xxxxx.com/metadata/";
	string public _contractURI = "https://to.wtf/contract_uri/bandyland/contract_uri.json";
	address private devWallet;
	uint256 public tokenPrice = 0.05 ether;
	mapping(address => uint256) public usedAddresses; //max 3 per address for whitelist
	bool public locked; //metadata lock
	uint256 public maxSupply = 10000;
	uint256 public maxSupplyPresale = 6000;

	uint256 public presaleStartTime = 1640545200; //dec 26
	uint256 public saleStartTime = 1640890800; //dec 30
	Counters.Counter private _tokenIds;

	address[] private addressList = [
		0x7285D1bb98B5DaA1f4b6DaAa66AE81E3A1383799,
		0x9FEeAa679dE920C3180C6B03646979EA7e2bc631,
		0x3dFF236850afF41158182bd032b07Df8ADB8C5f3,
		0xA8a971bc1FDD45F4B8e577810F329789C55Ec08b
	];
	uint256[] private shareList = [84, 4, 6, 6];

	modifier onlyDev() {
		require(msg.sender == devWallet, "only dev");
		_;
	}

	constructor() ERC721("Rare Panthers", "RPAN") PaymentSplitter(addressList, shareList) {
		devWallet = msg.sender;
	}

	//whitelistBuy can buy. max 3 tokens per whitelisted address
	function whitelistBuy(
		uint256 qty,
		uint256 tokenId,
		bytes32[] calldata proof
	) external payable {
		require(isTokenValid(msg.sender, tokenId, proof), "invalid proof");
		require(usedAddresses[msg.sender] + qty <= 3, "max 3 per wallet");
		require(tokenPrice * qty == msg.value, "exact amount needed");
		require(block.timestamp >= presaleStartTime, "not live");
		require(_tokenIds.current() + qty <= maxSupplyPresale, "public sale out of stock");

		usedAddresses[msg.sender] += qty;

		for (uint256 i = 0; i < qty; i++) {
			_tokenIds.increment();
			_safeMint(msg.sender, _tokenIds.current());
		}
	}

	//regular public sale
	function buy(uint256 qty) external payable {
		require(qty <= 10, "max 10 at once");
		require(tokenPrice * qty == msg.value, "exact amount needed");
		require(block.timestamp >= saleStartTime, "not live");
		require(_tokenIds.current() + qty <= maxSupply, "public sale out of stock");

		for (uint256 i = 0; i < qty; i++) {
			_tokenIds.increment();
			_safeMint(msg.sender, _tokenIds.current());
		}
	}

	function isTokenValid(
		address _to,
		uint256 _tokenId,
		bytes32[] memory _proof
	) public view returns (bool) {
		// construct Merkle tree leaf from the inputs supplied
		bytes32 leaf = keccak256(abi.encodePacked(_to, _tokenId));

		// verify the proof supplied, and return the verification result
		return _proof.verify(root, leaf);
	}

	function setMerkleRoot(bytes32 _root) external onlyDev {
		root = _root;
	}

	// admin can mint them for giveaways, airdrops etc
	function adminMint(uint256 qty, address to) external onlyOwner {
		require(qty <= 10, "no more than 10");
		require(_tokenIds.current() + qty <= maxSupply, "out of stock");
		for (uint256 i = 0; i < qty; i++) {
			_tokenIds.increment();
			_safeMint(to, _tokenIds.current());
		}
	}

	//----------------------------------
	//----------- other code -----------
	//----------------------------------
	function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) {
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = 0; index < tokenCount; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}

	function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
		return _isApprovedOrOwner(_spender, _tokenId);
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_contractBaseURI, _tokenId.toString(), ".json"));
	}

	function setBaseURI(string memory newBaseURI) external onlyDev {
		require(!locked, "locked functions");
		_contractBaseURI = newBaseURI;
	}

	function setContractURI(string memory newuri) external onlyDev {
		require(!locked, "locked functions");
		_contractURI = newuri;
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function reclaimERC20(IERC20 erc20Token) external onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

	function reclaimERC1155(
		IERC1155 erc1155Token,
		uint256 id,
		uint256 amount
	) external onlyOwner {
		erc1155Token.safeTransferFrom(address(this), msg.sender, id, amount, "");
	}

	function setPresaleStartTime(uint256 _presaleStartTime) external onlyDev {
		presaleStartTime = _presaleStartTime;
	}

	function setSaleStartTime(uint256 _saleStartTime) external onlyDev {
		saleStartTime = _saleStartTime;
	}

	function changePricePerToken(uint256 newPrice) external onlyOwner {
		tokenPrice = newPrice;
	}

	function decreaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
		require(newMaxSupply < maxSupply, "decrease only");
		maxSupply = newMaxSupply;
	}

	function decreaseMaxPresaleSupply(uint256 newMaxPresaleSupply) external onlyOwner {
		require(newMaxPresaleSupply < maxSupplyPresale, "decrease only");
		maxSupplyPresale = newMaxPresaleSupply;
	}

	// and for the eternity!
	function lockBaseURIandContractURI() external onlyDev {
		locked = true;
	}
}
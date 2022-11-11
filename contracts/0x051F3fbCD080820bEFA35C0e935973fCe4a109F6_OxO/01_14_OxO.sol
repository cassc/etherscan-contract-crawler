// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "./ERC721AQueryable.sol";

//   ___  _  _  ___
//  / _ \( \/ )/ _ \
// ( (_) ))  (( (_) )
//  \___/(_/\_)\___/
contract OxO is ERC721AQueryable, Ownable, ReentrancyGuard, PullPayment  {
	using Address for address;
	using Strings for uint256;
	using MerkleProof for bytes32[];

	bytes32 public root = 0x006d91eae4c28c5bd8a1c2cafa07772d2d6d1ef30779dfffa6f08f5f17b0074c;

	string public _contractBaseURI = "ipfs://to_be_updated_later/";
	string public _unrevealedURI = "https://highflyer-nft-test.s3.eu-central-1.amazonaws.com/1.json";
	string public _contractURI =
		"https://highflyer-nft-test.s3.eu-central-1.amazonaws.com/contract_uri.json";

	uint256 public maxSupply = 5000;
	uint256 public preSaleSupply = 1000;

	bool public isRevealed = false;

	uint256 public presalePrice = 0.3 ether;
	uint256 public publicPrice = 0.4 ether;

	uint256 public affiliateBonus = 0.15 ether; //in ether
	uint256 public affiliatePrice = 0.2 ether; //in ether

	uint256 public presaleStartTime = 1668168000;
	uint256 public publicStartTime = 1670587200;

	mapping(address => uint256) public usedAddresses; //merkle root check



	modifier notContract() {
		require(!_isContract(msg.sender), "contract not allowed");
		require(msg.sender == tx.origin, "proxy not allowed");
		_;
	}

	constructor() ERC721A("0x0", "0x0") {}

	/**
	 @dev only whitelisted can buy, maximum maxQty
	 @param qty - the quantity that a user wants to buy
	 @param limit - limit of the wallet
	 @param proof - merkle proof
	  */
	function presaleBuy(
		uint256 qty,
		uint256 limit,
		bytes32[] calldata proof
	) external payable nonReentrant notContract {
		require(usedAddresses[msg.sender] + qty <= limit, "wallet limit reached");
		require(block.timestamp >= presaleStartTime, "not live");
		require(presalePrice * qty == msg.value, "exact amount needed");
		require(totalSupply() + qty <= preSaleSupply, "out of stock");
		require(isProofValid(msg.sender, limit, proof), "invalid proof");

		usedAddresses[msg.sender] += qty;
		_mint(msg.sender, qty);
	}	

	/**
	 @dev everyone can buy
	  */
	function publicBuy(uint256 qty) external payable nonReentrant notContract {
		require(qty <= 10, "max 10 at once");
		require(block.timestamp >= publicStartTime, "not live");
		require(publicPrice * qty == msg.value, "exact amount needed");
		require(totalSupply() + qty <= maxSupply, "out of stock");

		_mint(msg.sender, qty);
	}

		/**
	 @dev used by affiliates
	  */
	function affiliateBuy(uint256 qty, uint256 affiliateNFTID) external payable nonReentrant notContract {
		require(qty <= 10, "max 10 at once");
		require(block.timestamp >= publicStartTime, "not live");
		require((affiliateBonus + affiliatePrice) * qty == msg.value, "exact amount needed");
		require(totalSupply() + qty <= maxSupply, "out of stock");
		
		_asyncTransfer(ownerOf(affiliateNFTID), affiliateBonus * qty);
		
		_mint(msg.sender, qty);
	}

	/**
	 @dev admin can mint 33
	 @param to - destination
	 @param qty - quantity
	  */
	function adminMint(address to, uint16 qty) external onlyOwner {
		require(qty < 11, "max 10 at once");
		require(totalSupply() <= 200, "no more than 200");
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
		if (isRevealed) {
			return string(abi.encodePacked(_contractBaseURI, _tokenId.toString(), ".json"));
		} else {
			return _unrevealedURI;
		}
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

	/**
	 * ADMIN FUNCTIONS
	 */
	function setImportantURIs(
		string memory newBaseURI,
		string memory newContractURI,
		string memory newUnrevealed,
		bool revealed
	) external onlyOwner {
		_contractBaseURI = newBaseURI;
		_contractURI = newContractURI;
		_unrevealedURI = newUnrevealed;
		isRevealed = revealed;
	}

	//recover lost erc20. getting them back chance: very low
	function reclaimERC20Token(address erc20Token) external onlyOwner {
		IERC20(erc20Token).transfer(msg.sender, IERC20(erc20Token).balanceOf(address(this)));
	}

	//recover lost nfts. getting them back chance: very low
	function reclaimERC721(address erc721Token, uint256 id) external onlyOwner {
		IERC721(erc721Token).safeTransferFrom(address(this), msg.sender, id);
	}

	//change the presale start time
	function setStartTimes(uint256 presale, uint256 publicSale) external onlyOwner {
		presaleStartTime = presale;
		publicStartTime = publicSale;
	}

	//owner reserves the right to change the price
	function setPricePerToken(uint256 newPresalePrice, uint256 newPublicPrice) external onlyOwner {
		presalePrice = newPresalePrice;
		publicPrice = newPublicPrice;
	}

	//owner reserves the right to change the affiliate bonuses
	function setAffiliateBonuses(uint256 newAffiliateBonus, uint256 newAffiliatePrice) external onlyOwner {
		affiliateBonus = newAffiliateBonus;
		affiliatePrice = newAffiliatePrice;
	}

	//only decrease it, no funky stuff
	function decreaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
		require(newMaxSupply < maxSupply, "decrease only");
		maxSupply = newMaxSupply;
	}

	function setMerkleRoot(bytes32 _root) external onlyOwner {
		root = _root;
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
	
	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}
	function buildNumber1() internal view {}
}
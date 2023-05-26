// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Shopverse is ERC721Enumerable, Ownable, ReentrancyGuard {
	using Address for address;
	using Strings for uint256;
	using MerkleProof for bytes32[];

	/**
	 * @notice Input data root, Merkle tree root for an array of (address, tokenId) pairs,
	 *      available for minting
	 */
	bytes32 public root;

	string public _contractBaseURI = "https://nftapi.shopping.io/metadata/";
	string public _contractURI = "ipfs://QmXKSGxJdLucqDyCEH9psYnBWfRM2Zh3BAkJ4GEbiVcSBY";
	uint256 public tokenPrice = 0.149 ether;
	mapping(address => uint256) public usedAddresses; //max 3 per address for whitelist
	mapping(uint256 => bool) public usedJRNYTokens;
	bool public locked; //baseURI & contractURI lock
	uint256 public maxSupply = 7777;
	IERC721 public JRNYClub;

	uint256 public whitelistStartTime = 1638633600;
	uint256 public jrnyStartTime = 1638720000;
	uint256 public publicSaleStartTime = 1638806400;

	constructor() ERC721("Shopverse", "SHOP") {
		JRNYClub = IERC721(0x0b4B2bA334f476C8F41bFe52A428D6891755554d);
	}

	//whitelistBuy can buy. max 3 tokens per whitelisted address
	function whitelistBuy(
		uint256 qty,
		uint256 tokenId,
		bytes32[] calldata proof
	) external payable nonReentrant {
		require(tokenPrice * qty == msg.value, "exact amount needed");
		require(usedAddresses[msg.sender] + qty <= 3, "max 3 per wallet");
		require(totalSupply() + qty <= maxSupply, "out of stock");
		require(block.timestamp >= whitelistStartTime, "not live");

		require(isTokenValid(msg.sender, tokenId, proof), "invalid proof");

		usedAddresses[msg.sender] += qty;
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}

	//jrny holders can buy 1 (keeps track of whitelists counter)
	function jrnyBuy(uint256 jrnyTokenID) external payable {
		require(tokenPrice == msg.value, "exact amount needed");
		require(usedAddresses[msg.sender] + 1 <= 1, "max 1 per wallet");
		require(usedJRNYTokens[jrnyTokenID] == false, "jrny used token");
		require(totalSupply() + 1 <= maxSupply, "out of stock");
		require(block.timestamp >= jrnyStartTime, "not live");

		require(JRNYClub.ownerOf(jrnyTokenID) == msg.sender, "not the owner of the tokenID");

		usedAddresses[msg.sender] += 1;
		usedJRNYTokens[jrnyTokenID] = true;

		_safeMint(msg.sender, totalSupply() + 1);
	}

	//regular public sale
	function buy(uint256 qty) external payable {
		require(tokenPrice * qty == msg.value, "exact amount needed");
		require(qty <= 5, "max 5 at once");
		require(totalSupply() + qty <= maxSupply, "out of stock");
		require(block.timestamp >= publicSaleStartTime, "not live");

		for (uint256 i = 0; i < qty; i++) {
			_safeMint(msg.sender, totalSupply() + 1);
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

	function setMerkleRoot(bytes32 _root) external onlyOwner {
		root = _root;
	}

	// admin can mint them for giveaways, airdrops etc
	function adminMint(uint256 qty, address to) external onlyOwner {
		require(qty <= 25, "no more than 25");
		require(totalSupply() + qty <= maxSupply, "out of stock");
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(to, totalSupply() + 1);
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

	function burn(uint256 tokenId) public virtual {
		require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
		_burn(tokenId);
	}

	function exists(uint256 _tokenId) external view returns (bool) {
		return _exists(_tokenId);
	}

	function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
		return _isApprovedOrOwner(_spender, _tokenId);
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_contractBaseURI, _tokenId.toString(), ".json"));
	}

	function setBaseURI(string memory newBaseURI) external onlyOwner {
		require(!locked, "locked functions");
		_contractBaseURI = newBaseURI;
	}

	function setContractURI(string memory newuri) external onlyOwner {
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

	//for testing
	function setJRNYClubAddress(address _addr) external onlyOwner {
		JRNYClub = IERC721(_addr);
	}

	//in unix
	function setWhitelistStartTime(uint256 newTime) external onlyOwner {
		whitelistStartTime = newTime;
	}

	//in unix
	function setJrnyStartTime(uint256 newTime) external onlyOwner {
		jrnyStartTime = newTime;
	}

	//in unix
	function setPublicSaleStartTime(uint256 newTime) external onlyOwner {
		publicSaleStartTime = newTime;
	}

	function changePricePerToken(uint256 newPrice) external onlyOwner {
		tokenPrice = newPrice;
	}

	function decreaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
		require(newMaxSupply < maxSupply, "decrease only");
		maxSupply = newMaxSupply;
	}

	// and for the eternity!
	function lockBaseURIandContractURI() external onlyOwner {
		locked = true;
	}

	// earnings withdrawal
	function withdrawEarnings() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}
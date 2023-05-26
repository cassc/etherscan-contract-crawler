// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC2981, ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./erc721a/ERC721AQueryable.sol";
import { OperatorFilterer } from "./OperatorFilterer.sol";

contract MothValley is ERC721AQueryable, ERC2981, OperatorFilterer, Ownable, ReentrancyGuard {
	using Address for address;
	using Strings for uint256;
	using MerkleProof for bytes32[];

	bytes32 public root = 0x5fab1f9f64889ad322e4165b569228c9fffcd062fe8b2bc13981e02dd570fb02;

	string public _contractBaseURI = "https://ipfs.w3bmint.xyz/ipfs/xxx/";
	string public _contractURI =
		"https://bafkreiceblpdidptyzts6rtbk4cbhpp5if32gnzizacbldilpcfjhl3yae.ipfs.nftstorage.link";
	string public unrevealedBaseURI =
		"https://bafkreidqqnyi7bqx3prdtpvvvd4t52egdeaiaotj7vapbpqknicthktxya.ipfs.nftstorage.link";
	uint256 public maxSupply = 1111;
	uint256 public maxPublicMint = 1;
	bool public isRevealed = false;
	bool public operatorFilteringEnabled;

	uint256 public whitelistStartTime = 1682892000;
	uint256 public publicStartTime = 1782870400;

	mapping(address => uint256) public whitelistMintQuantity; //merkle root check
	mapping(address => uint256) public publicMintQuantity;

	modifier notContract() {
		require(!_isContract(msg.sender), "contract not allowed");
		require(msg.sender == tx.origin, "proxy not allowed");
		_;
	}

	constructor() ERC721A("Moth Valley Pass", "MOTHV") {
		_registerForOperatorFiltering();
		operatorFilteringEnabled = true;
		_setDefaultRoyalty(0x62C3c92B0154464C0c27BD8F7da06d0877229310, 900);
	}

	/**
	 @dev only whitelisted can buy, maximum maxQty
	 @param qty - the quantity that a user wants to buy
	 @param limit - limit of the wallet
	 @param proof - merkle proof
	  */
	function claim(
		uint256 qty,
		uint256 limit,
		bytes32[] calldata proof
	) external nonReentrant notContract {
		require(whitelistMintQuantity[msg.sender] + qty <= limit, "wallet limit reached");
		require(block.timestamp >= whitelistStartTime, "not live");
		require(totalSupply() + qty <= maxSupply, "out of stock");
		require(isProofValid(msg.sender, limit, proof), "invalid proof");

		whitelistMintQuantity[msg.sender] += qty;
		_mint(msg.sender, qty);
	}

	/**
	 @dev anyone can buy
	 @param qty - the quantity that a user wants to claim (price free)
	  */
	function publicClaim(uint256 qty) external nonReentrant notContract {
		require(publicMintQuantity[_msgSender()] <= maxPublicMint, "over max limit");
		require(qty <= 1, "max 1 at once");
		require(block.timestamp >= publicStartTime, "not live");
		require(totalSupply() + qty <= maxSupply, "out of stock");
		publicMintQuantity[_msgSender()] += qty;
		_mint(_msgSender(), qty);
	}

	/**
	@dev admin mint
	@param to - destination
	@param qty - quantity
	  */
	function adminMint(address to, uint256 qty) external onlyOwner {
		require(totalSupply() + qty <= maxSupply, "out of stock");
		_mint(to, qty);
	}

	/**
	 * READ FUNCTIONS
	 */

	/**
	@dev returns current "stage"
	*999 = sold out, 0 = not started, 1 = whitelist 1, 2 = public
	*/
	function getStage() public view returns (uint256) {
		if (totalSupply() >= maxSupply) {
			return 999;
		}
		if (block.timestamp >= publicStartTime) {
			return 2;
		}
		if (block.timestamp >= whitelistStartTime) {
			return 1;
		}
		return 0;
	}

	/**
	@dev returns true if an NFT is minted
	*/
	function exists(uint256 _tokenId) external view returns (bool) {
		return _exists(_tokenId);
	}

	/**
	@dev tokenURI from ERC721 standard
	*/
	function tokenURI(
		uint256 _tokenId
	) public view override(ERC721A, IERC721A) returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

		if (!isRevealed) {
			return string(unrevealedBaseURI);
		}

		return string(abi.encodePacked(_contractBaseURI, _tokenId.toString()));
	}

	/**
	@dev contractURI from ERC721 standard
	*/
	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	/**
	@dev merkle proof check
	*/
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
	// be careful setting this one
	function setImportantURIs(
		string memory newBaseURI,
		string memory newContractURI,
		string memory xunrevealedURI
	) external onlyOwner {
		_contractBaseURI = newBaseURI;
		_contractURI = newContractURI;
		unrevealedBaseURI = xunrevealedURI;
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
	function setStartTimes(uint256 whitelist, uint256 publicSale) external onlyOwner {
		whitelistStartTime = whitelist;
		publicStartTime = publicSale;
	}

	//only decrease it, no funky stuff
	function decreaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
		require(newMaxSupply < maxSupply, "decrease only");
		maxSupply = newMaxSupply;
	}

	//default 1
	function setMaxPublicMint(uint256 newLimit) external onlyOwner {
		maxPublicMint = newLimit;
	}

	//call this to reveal the jpegs
	function setBaseURIAndReveal(string memory newBaseURI) external onlyOwner {
		_contractBaseURI = newBaseURI;
	}

	//sets the merkle root for the whitelist
	function setMerkleRoot(bytes32 _root) external onlyOwner {
		root = _root;
	}

	//sets the reaveled. set this after updating the baseURIs
	function setIsRevealed(bool revealed) external onlyOwner {
		isRevealed = revealed;
	}

	//anti-bot
	function _isContract(address _addr) private view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(_addr)
		}
		return size > 0;
	}

	//makes the starting token id to be 1
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	function setApprovalForAll(
		address operator,
		bool approved
	) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
		super.setApprovalForAll(operator, approved);
	}

	function approve(
		address operator,
		uint256 tokenId
	) public payable override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
		super.approve(operator, tokenId);
	}

	/**
	 * @dev Both safeTransferFrom functions in ERC721A call this function
	 * so we don't need to override them.
	 */
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
		super.transferFrom(from, to, tokenId);
	}

	function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
		_setDefaultRoyalty(receiver, feeNumerator);
	}

	function setOperatorFilteringEnabled(bool value) public onlyOwner {
		operatorFilteringEnabled = value;
	}

	function _operatorFilteringEnabled() internal view override returns (bool) {
		return operatorFilteringEnabled;
	}

	function _isPriorityOperator(address operator) internal pure override returns (bool) {
		// OpenSea Seaport Conduit:
		// https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
		// https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
		return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
	}

	function supportsInterface(
		bytes4 interfaceId
	) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
		// Supports the following `interfaceId`s:
		// - IERC165: 0x01ffc9a7
		// - IERC721: 0x80ac58cd
		// - IERC721Metadata: 0x5b5e139f
		// - IERC2981: 0x2a55205a
		return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
	}
}
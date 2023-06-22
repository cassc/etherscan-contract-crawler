// SPDX-License-Identifier: MIT
/*
 * TheBodega.sol
 *
 * Created: February 4, 2022
 *
 * Price: 0.088 ETH
 *
 * - 535 total supply
 * - Pause/unpause minting
 * - Limited to 3 mints per wallet
 * - Whitelist restricted to Plug hodlers
 */

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./access/Pausable.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/LibPart.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract Plug {
	function balanceOf(address a) public virtual returns (uint);
}

//@title The Bodega
//@author Jack Kasbeer (git:@jcksber, tw:@satoshigoat, og:overprivilegd)
contract TheBodega is ERC721A, Pausable, ReentrancyGuard {
	using SafeMath for uint256;

	//@dev Plug instance: mainnet!
	Plug constant public thePlug = Plug(0x2Bb501A0374ff3Af41f2009509E9D6a36D56A6c0);

	//@dev Supply
	uint256 constant MAX_NUM_TOKENS = 545;//number of plug holders

	//@dev Properties
	string internal _contractURI;
	string internal _baseTokenURI;
	string internal _tokenHash;
	address public payoutAddress;
	uint256 public weiPrice;
	uint256 constant public royaltyFeeBps = 1500;//15%
	bool public openToPublic;

	// ---------
	// MODIFIERS
	// ---------

	modifier onlyValidTokenId(uint256 tid) {
		require(
			0 <= tid && tid < MAX_NUM_TOKENS, 
			"TheBodega: tid OOB"
		);
		_;
	}

	modifier enoughSupply(uint256 qty) {
		require(
			totalSupply() + qty < MAX_NUM_TOKENS, 
			"TheBodega: not enough left"
		);
		_;
	}

	modifier notEqual(string memory str1, string memory str2) {
		require(
			!_stringsEqual(str1, str2),
			"TheBodega: must be different"
		);
		_;
	}

	modifier purchaseArgsOK(address to, uint256 qty, uint256 amount) {
		require(
			numberMinted(to) + qty <= 3, 
			"TheBodega: max 3 per wallet"
		);
		require(
			amount >= weiPrice*qty, 
			"TheBodega: not enough ether"
		);
		require(
			!_isContract(to), 
			"TheBodega: silly rabbit :P"
		);
		_;
	}

	// ------------
	// CONSTRUCTION
	// ------------

	constructor() ERC721A("The Bodega", "") {
		_baseTokenURI = "ipfs://";
		_tokenHash = "QmbSH67UGGRWNycsNqMBqqnC8ikpriWYM7omqBnSvacm1F";//token metadata ipfs hash
		_contractURI = "ipfs://Qmc6XcpjBdU5ZAa1DDFsWG8NyUqW549ejR6WK5XDrwqPUU";
		weiPrice = 88000000000000000;//0.088 ETH
		payoutAddress = address(0x6b8C6E15818C74895c31A1C91390b3d42B336799);//logik
	}

	// ----------
	// MAIN LOGIC
	// ----------

	//@dev See {ERC721A16-_baseURI}
	function _baseURI() internal view virtual override returns (string memory)
	{
		return _baseTokenURI;
	}

	//@dev See {ERC721A16-tokenURI}.
	function tokenURI(uint256 tid) public view virtual override
		returns (string memory) 
	{
		require(_exists(tid), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_baseTokenURI, _tokenHash));
	}

	//@dev Controls the contract-level metadata to include things like royalties
	function contractURI() external view returns (string memory)
	{
		return _contractURI;
	}

	//@dev Allows owners to mint for free whenever
	function mint(address to, uint256 qty) 
		external isSquad enoughSupply(qty)
	{
		_safeMint(to, qty);
	}

	//@dev Allows public addresses (non-owners) to purchase
	function plugPurchase(address payable to, uint256 qty) 
		external payable saleActive enoughSupply(qty) purchaseArgsOK(to, qty, msg.value)
	{
		require(
			thePlug.balanceOf(to) > 0,
			"TheBodega: plug hodlers only"
		);
		_safeMint(to, qty);
	}

	//@dev Allows public addresses (non-owners) to purchase
	function publicPurchase(address payable to, uint256 qty) 
		external payable saleActive enoughSupply(qty) purchaseArgsOK(to, qty, msg.value)
	{
		require(
			openToPublic, 
			"TheBodega: sale is not public"
		);
		_safeMint(to, qty);
	}

	//@dev Allows us to withdraw funds collected
	function withdraw(address payable wallet, uint256 amount) 
		external isSquad nonReentrant
	{
		require(
			amount <= address(this).balance,
			"TheBodega: insufficient funds to withdraw"
		);
		wallet.transfer(amount);
	}

	//@dev Destroy contract and reclaim leftover funds
	function kill() external onlyOwner 
	{
		selfdestruct(payable(_msgSender()));
	}

	//@dev See `kill`; protects against being unable to delete a collection on OpenSea
	function safe_kill() external onlyOwner
	{
		require(
			balanceOf(_msgSender()) == totalSupply(),
			"TheBodega: potential error - not all tokens owned"
		);
		selfdestruct(payable(_msgSender()));
	}

	/// -------
	/// SETTERS
	// --------

	//@dev Ability to change the base token URI
	function setBaseTokenURI(string calldata newBaseURI) 
		external isSquad notEqual(_baseTokenURI, newBaseURI) { _baseTokenURI = newBaseURI; }

	//@dev Ability to update the token metadata
	function setTokenHash(string calldata newHash) 
		external isSquad notEqual(_tokenHash, newHash) { _tokenHash = newHash; }

	//@dev Ability to change the contract URI
	function setContractURI(string calldata newContractURI) 
		external isSquad notEqual(_contractURI, newContractURI) { _contractURI = newContractURI; }

	//@dev Change the price
	function setPrice(uint256 newWeiPrice) external isSquad
	{
		require(
			weiPrice != newWeiPrice, 
			"TheBodega: newWeiPrice must be different"
		);
		weiPrice = newWeiPrice;
	}

	//@dev Toggle the lock on public purchasing
	function toggleOpenToPublic() external isSquad
	{
		openToPublic = openToPublic ? false : true;
	}

	// -------
	// HELPERS
	// -------

	//@dev Gives us access to the otw internal function `_numberMinted`
	function numberMinted(address owner) public view returns (uint256) 
	{
		return _numberMinted(owner);
	}

	//@dev Determine if two strings are equal using the length + hash method
	function _stringsEqual(string memory a, string memory b) 
		internal pure returns (bool)
	{
		bytes memory A = bytes(a);
		bytes memory B = bytes(b);

		if (A.length != B.length) {
			return false;
		} else {
			return keccak256(A) == keccak256(B);
		}
	}

	//@dev Determine if an address is a smart contract 
	function _isContract(address a) internal view returns (bool)
	{
		uint32 size;
		assembly {
			size := extcodesize(a)
		}
		return size > 0;
	}

	// ---------
	// ROYALTIES
	// ---------

	//@dev Rarible Royalties V2
	function getRaribleV2Royalties(uint256 tid) 
		external view onlyValidTokenId(tid) 
		returns (LibPart.Part[] memory) 
	{
		LibPart.Part[] memory royalties = new LibPart.Part[](1);
		royalties[0] = LibPart.Part({
			account: payable(payoutAddress),
			value: uint96(royaltyFeeBps)
		});
		return royalties;
	}

	// @dev See {EIP-2981}
	function royaltyInfo(uint256 tid, uint256 salePrice) 
		external view onlyValidTokenId(tid) 
		returns (address, uint256) 
	{
		uint256 ourCut = SafeMath.div(SafeMath.mul(salePrice, royaltyFeeBps), 10000);
		return (payoutAddress, ourCut);
	}
}
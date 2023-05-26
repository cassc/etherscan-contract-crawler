// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721Namable.sol";
import "./NineMilkToken.sol";

/* 
Error message:
e1: Presale has not started
e2: Public sale has not started
e3: !eligible
e4: All tokens have been minted
e5: > PRESALE_MAX_MINT
e6: Minting would exceed max supply
e7: Purchase exceeds max allowed
e8: Must mint at least one 9Cat
e9: != ETH
e10: > MAX_PER_MINT
e11: must > 0
e12: Invalid Hash
*/

contract NineCat is ERC721Namable, Ownable {
	using Strings for uint256;

	uint256 public constant MAX_9CAT = 9999;
	uint256 public constant PUBLIC_SALE_PRICE = 0.07 ether;
	uint256 public constant PRESALE_PRICE = 0.06 ether;
	uint256 public constant MAX_PER_MINT = 9;
	uint256 public constant PRESALE_MAX_MINT = 3;
	uint256 public constant MAX_9CAT_MINT = 9;

	uint256 public nameChangePrice = 297 ether;
	uint256 public bioChangePrice = 99 ether;

	string public baseTokenURI;

	bool public publicSaleStarted;
	bool public presaleStarted;

	address private signer;

	mapping(address => uint256) private _totalClaimed;

	event BaseURIChanged(string baseURI);
	event PresaleMint(address minter, uint256 amountOf9Cat);
	event PublicSaleMint(address minter, uint256 amountOf9Cat);
	event GiveawayMint(address receiver, uint256 amountOf9Cat);

	modifier whenPresaleStarted() {
		require(presaleStarted, "e1");
		_;
	}

	modifier whenPublicSaleStarted() {
		require(publicSaleStarted, "e2");
		_;
	}

	constructor(address _signer, string memory baseURI) ERC721Namable("9Cat", "9CAT") {
		baseTokenURI = baseURI;
		signer = _signer;
	}

	function giveaway(address receiver, uint256 amountOf9Cat) external onlyOwner {
		uint256 _nextTokenId = totalSupply() + 1;
		for (uint256 i = 0; i < amountOf9Cat; i++) {
			_safeMint(receiver, _nextTokenId);
			_nextTokenId++;
		}
		yieldToken.updateRewardOnMint(receiver, amountOf9Cat);
		emit GiveawayMint(receiver, amountOf9Cat);
	}

	function checkPresaleEligibility(bytes32 hash, bytes memory signature)
		public
		view
		returns (bool)
	{
		require(ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender))) == hash, "e12");
		return ECDSA.recover(hash, signature) == signer;
	}

	function amountClaimedBy(address owner) external view returns (uint256) {
		require(owner != address(0));
		return _totalClaimed[owner];
	}

	function mintPresale(
		uint256 amountOf9Cat,
		bytes32 hash,
		bytes memory signature
	) external payable whenPresaleStarted {
		require(checkPresaleEligibility(hash, signature), "e3");
		require(totalSupply() < MAX_9CAT, "e4");
		require(amountOf9Cat <= PRESALE_MAX_MINT, "e5");
		require(totalSupply() + amountOf9Cat <= MAX_9CAT, "e6");
		require(_totalClaimed[msg.sender] + amountOf9Cat <= PRESALE_MAX_MINT, "e7");
		require(amountOf9Cat > 0, "e8");
		require(PRESALE_PRICE * amountOf9Cat == msg.value, "e9");
		uint256 _nextTokenId = totalSupply() + 1;
		for (uint256 i = 0; i < amountOf9Cat; i++) {
			_safeMint(msg.sender, _nextTokenId);
			_nextTokenId++;
		}
		_totalClaimed[msg.sender] += amountOf9Cat;
		yieldToken.updateRewardOnMint(msg.sender, amountOf9Cat);
		emit PresaleMint(msg.sender, amountOf9Cat);
	}

	function mint(uint256 amountOf9Cat) external payable whenPublicSaleStarted {
		require(totalSupply() < MAX_9CAT, "e4");
		require(amountOf9Cat <= MAX_PER_MINT, "e10");
		require(totalSupply() + amountOf9Cat <= MAX_9CAT, "e6");
		require(_totalClaimed[msg.sender] + amountOf9Cat <= MAX_9CAT_MINT, "e7");
		require(amountOf9Cat > 0, "e11");
		require(PUBLIC_SALE_PRICE * amountOf9Cat == msg.value, "e9");
		uint256 _nextTokenId = totalSupply() + 1;
		for (uint256 i = 0; i < amountOf9Cat; i++) {
			_safeMint(msg.sender, _nextTokenId);
			_nextTokenId++;
		}
		_totalClaimed[msg.sender] += amountOf9Cat;
		yieldToken.updateRewardOnMint(msg.sender, amountOf9Cat);
		emit PublicSaleMint(msg.sender, amountOf9Cat);
	}

	function setSigner(address addr) external onlyOwner {
		signer = addr;
	}

	function togglePresaleStarted() external onlyOwner {
		presaleStarted = !presaleStarted;
	}

	function togglePublicSaleStarted() external onlyOwner {
		publicSaleStarted = !publicSaleStarted;
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return baseTokenURI;
	}

	function setBaseURI(string memory baseURI) public onlyOwner {
		baseTokenURI = baseURI;
		emit BaseURIChanged(baseURI);
	}

	function withdrawAll() public onlyOwner {
		_widthdraw(0x7BcBa9cE8e52f999f5c8B175269abD4d70209407, address(this).balance);
	}

	function _widthdraw(address _address, uint256 _amount) private {
		(bool success, ) = _address.call{value: _amount}("");
		require(success);
	}

	NineMilkToken public yieldToken;

	function setYieldToken(address _yield) external onlyOwner {
		yieldToken = NineMilkToken(_yield);
	}

	function changeNamePrice(uint256 _price) external onlyOwner {
		nameChangePrice = _price;
	}

	function changeBioPrice(uint256 _price) external onlyOwner {
		bioChangePrice = _price;
	}

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public override {
		yieldToken.updateReward(from, to, 1);
		super.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) public override {
		yieldToken.updateReward(from, to, 1);
		super.safeTransferFrom(from, to, tokenId, _data);
	}

	function changeName(uint256 tokenId, string memory newName) public override {
		yieldToken.consume(msg.sender, nameChangePrice);
		super.changeName(tokenId, newName);
	}

	function changeBio(uint256 tokenId, string memory _bio) public override {
		yieldToken.consume(msg.sender, bioChangePrice);
		super.changeBio(tokenId, _bio);
	}
}
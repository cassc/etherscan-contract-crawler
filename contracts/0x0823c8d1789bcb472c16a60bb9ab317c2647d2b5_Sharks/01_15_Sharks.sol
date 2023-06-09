// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Sharks is ERC721Enumerable, Ownable {
	using Strings for uint256;
	using ECDSA for bytes32;

	string private _baseTokenURI = "https://api.thesharkmob.com/metadata/";
	string private _contractURI = "ipfs://QmP1iGbcHef34cv3RGH7Z26zAyyzBc5w8iDsEUjP2HuWAt";

	uint256 public maxSupply = 7777;
	uint256 public maxPresale = 2500;
	uint256 public maxFlashSale = 300;

	uint256 public pricePerTokenFlashSale = 70000000000000000; //0.07 ETH
	uint256 public pricePerTokenPresale = 70000000000000000; //0.07 ETH
	uint256 public pricePerToken = 80000000000000000; //0.08 ETH

	bool public saleLive = false;
	bool public presaleLive = false;
	bool public flashLive = false;
	bool public locked; //metadata lock
	address private devWallet;
	string private ipfsProof;

	constructor() ERC721("The Shark Mob", "TSM") {
		devWallet = msg.sender;
	}

	function flashBuy(uint256 qty) external payable {
		require(flashLive, "not live - flash");
		require(qty <= 3, "no more than 3");
		require(totalSupply() + qty <= maxFlashSale, "flash out of stock");
		require(pricePerTokenFlashSale * qty == msg.value, "exact amount needed");
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}

	function presaleBuy(uint256 qty) external payable {
		require(presaleLive, "not live - presale");
		require(qty <= 4, "no more than 4");
		require(totalSupply() + qty <= maxPresale, "presale out of stock");
		require(pricePerTokenPresale * qty == msg.value, "exact amount needed");
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}

	function publicBuy(uint256 qty) external payable {
		require(saleLive, "not live");
		require(qty <= 20, "no more than 20");
		require(totalSupply() + qty <= maxSupply, "public sale out of stock");
		require(pricePerToken * qty == msg.value, "exact amount needed");
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(msg.sender, totalSupply() + 1);
		}
	}

	// admin can mint them for giveaways, airdrops etc
	function adminMint(uint256 qty, address to) public onlyOwner {
		require(qty > 0, "minimum 1 token");
		require(qty <= 20, "no more than 20");
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
		return string(abi.encodePacked(_baseTokenURI, _tokenId.toString(), ".json"));
	}

	function setBaseURI(string memory newBaseURI) public onlyOwner {
		require(!locked, "locked functions");
		_baseTokenURI = newBaseURI;
	}

	function setContractURI(string memory newuri) public onlyOwner {
		require(!locked, "locked functions");
		_contractURI = newuri;
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	// earnings withdrawal
	function withdraw() public onlyOwner {
		uint256 totalBalance = address(this).balance;
		uint256 devFee = _calcPercentage(totalBalance, 500); //5%
		payable(msg.sender).transfer(totalBalance - devFee);
		payable(devWallet).transfer(devFee);
	}

	function reclaimERC20(IERC20 erc20Token) public onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function toggleFlashStatus() external onlyOwner {
		flashLive = !flashLive;
	}

	function togglePresaleStatus() external onlyOwner {
		presaleLive = !presaleLive;
	}

	function togglePublicSaleStatus() external onlyOwner {
		saleLive = !saleLive;
	}

	function changePriceFlash(uint256 newPrice) external onlyOwner {
		pricePerTokenFlashSale = newPrice;
	}

	function changePricePresale(uint256 newPrice) external onlyOwner {
		pricePerTokenPresale = newPrice;
	}

	function changePricePublicSale(uint256 newPrice) external onlyOwner {
		pricePerToken = newPrice;
	}

	function changeMaxPresale(uint256 _newMaxPresale) external onlyOwner {
		maxPresale = _newMaxPresale;
	}

	function setIPFSProvenance(string memory _ipfsProvenance) external onlyOwner {
		bytes memory tempEmptyStringTest = bytes(ipfsProof);
		require(tempEmptyStringTest.length == 0, "ipfsProof already set");
		ipfsProof = _ipfsProvenance;
	}

	function decreaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
		require(newMaxSupply < maxSupply, "you can only decrease it");
		maxSupply = newMaxSupply;
	}

	// and for the eternity!
	function lockMetadata() external onlyOwner {
		locked = true;
	}

	//300 = 3%, 1 = 0.01%
	function _calcPercentage(uint256 amount, uint256 basisPoints) internal pure returns (uint256) {
		require(basisPoints >= 0);
		return (amount * basisPoints) / 10000;
	}
}
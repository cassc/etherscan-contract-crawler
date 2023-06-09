// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract GutterSpecies is ERC721Enumerable, Ownable, ReentrancyGuard {
	using Strings for uint256;

	IERC1155 public gutterCatNFTAddress;
	IERC1155 public gutterRatNFTAddress;

	uint256 public maxPairSale = 1500;
	uint256 public maxPrivateSale = 1500;
	uint256 public maxPublicSale = 3000;

	bool public pairSaleActive = false;
	bool public privateSaleActive = false;
	bool public publicSaleActive = false;

	uint256 public privateSalePrice = 750000000000000000; //0.75 ETH
	uint256 public publicSalePrice = 1500000000000000000; //1.5 ETH

	uint256 public tokenIndexPass3 = 0; //index of the nft
	uint256 public tokenIndexPass4 = 3000; //index of the nft

	//maximum passes to be minted for each pass
	uint256 public maxFreePassesType3 = 750;
	uint256 public maxFreePassesType4 = 750;
	uint256 public maxPrivatePassesType3 = 750;
	uint256 public maxPrivatePassesType4 = 750;
	uint256 public maxPublicPassesType3 = 1500;
	uint256 public maxPublicPassesType4 = 1500;

	//keeps track of how many passes were minted
	uint256 public counterFreePassesTypes3 = 0;
	uint256 public counterFreePassesTypes4 = 0;
	uint256 public counterPrivatePassesType3 = 0;
	uint256 public counterPrivatePassesType4 = 0;
	uint256 public counterPublicPassesType3 = 0;
	uint256 public counterPublicPassesType4 = 0;

	//free sale limiting
	mapping(uint256 => bool) public pairCatClaimed;
	mapping(uint256 => bool) public pairRatClaimed;

	string private _baseTokenURI = "ipfs://QmZgbUNBwm9qnpCozrZGQtwnmCCxUBcFWSx1RdWikrEH2U/";
	string private _contractURI = "ipfs://QmNr59k9BFyNxvbWusvsSEyfvn4yxLbLauqVBbkrFPFV5d";

	event CustomAction(uint256 nftID, uint256 value, uint256 actionID, string payload);

	constructor(address _catsNFTAddress, address _ratsNFTAddress) ERC721("Gutter Passes", "GPASS") {
		gutterCatNFTAddress = IERC1155(_catsNFTAddress);
		gutterRatNFTAddress = IERC1155(_ratsNFTAddress);
	}

	//gives you a free pass if you own a cat AND a rat
	function getPassForPair(
		uint256 catID,
		uint256 ratID,
		uint256 passType
	) public nonReentrant {
		require(pairSaleActive == true, "pair sale not active");
		require(
			gutterCatNFTAddress.balanceOf(msg.sender, catID) > 0,
			"you have to own this cat with this id"
		);
		require(
			gutterRatNFTAddress.balanceOf(msg.sender, ratID) > 0,
			"you have to own this rat with this id"
		);

		require(pairCatClaimed[catID] == false, "cat is used");
		require(pairRatClaimed[ratID] == false, "rat is used");
		pairCatClaimed[catID] = true;
		pairRatClaimed[ratID] = true;

		if (passType == 3) {
			counterFreePassesTypes3++;
			require(counterFreePassesTypes3 < maxFreePassesType3, "no more passes available (3)");
			_mintToken(_msgSender(), 3);
		}

		if (passType == 4) {
			counterFreePassesTypes4++;
			require(counterFreePassesTypes4 < maxFreePassesType4, "no more passes available (4)");
			_mintToken(_msgSender(), 4);
		}
	}

	//gets you a pass if you own a cat OR a rat for the price of privateSalePrice
	function getPassPrivateSale(uint256 catOrRatID, uint256 passType) public payable nonReentrant {
		require(privateSaleActive == true, "private sale not active");
		require(
			(gutterCatNFTAddress.balanceOf(msg.sender, catOrRatID) > 0) ||
				(gutterRatNFTAddress.balanceOf(msg.sender, catOrRatID) > 0),
			"you have to own a cat or a rat with this id"
		);

		require(msg.value == privateSalePrice, "send exact ETH value");

		if (passType == 3) {
			counterPrivatePassesType3++;
			require(counterPrivatePassesType3 < maxPrivatePassesType3, "no more passes available (3)");
			_mintToken(_msgSender(), 3);
		}

		if (passType == 4) {
			counterPrivatePassesType4++;
			require(counterPrivatePassesType4 < maxPrivatePassesType4, "no more passes available (4)");
			_mintToken(_msgSender(), 4);
		}
	}

	//gets you a pass for the price of publicSalePrice
	function getPassPublicSale(uint256 passType) public payable nonReentrant {
		require(publicSaleActive == true, "public sale not active");

		require(msg.value == publicSalePrice, "send exact ETH value");

		if (passType == 3) {
			counterPublicPassesType3++;
			require(counterPublicPassesType3 < maxPublicPassesType3, "no more passes available (3)");
			_mintToken(_msgSender(), 3);
		}

		if (passType == 4) {
			counterPublicPassesType4++;
			require(counterPublicPassesType4 < maxPublicPassesType4, "no more passes available (4)");
			_mintToken(_msgSender(), 4);
		}
	}

	//gets you a pass for the admin for giveaways
	//attention: doesn't check if the limits for max passes!
	function getPassAdminMint(uint256 passType) external onlyOwner {
		if (passType == 3) {
			_mintToken(_msgSender(), 3);
		}

		if (passType == 4) {
			_mintToken(_msgSender(), 4);
		}
	}

	//minting tokens
	function _mintToken(address destinationAddress, uint256 tokenType) private {
		if (tokenType == 3) {
			tokenIndexPass3++;
			require(!_exists(tokenIndexPass3), "Token already exist.");
			_safeMint(destinationAddress, tokenIndexPass3);
		}
		if (tokenType == 4) {
			tokenIndexPass4++;
			require(!_exists(tokenIndexPass4), "Token already exist.");
			_safeMint(destinationAddress, tokenIndexPass4);
		}
	}

	function customAction(
		uint256 nftID,
		uint256 id,
		string memory what
	) external payable {
		require(ownerOf(nftID) == msg.sender, "NFT ownership required");
		emit CustomAction(nftID, msg.value, id, what);
	}

	function tokensOfOwner(
		address owner,
		uint256 start,
		uint256 limit
	) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(owner);
		if (tokenCount == 0) {
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = start; index < limit; index++) {
				result[index] = tokenOfOwnerByIndex(owner, index);
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

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function togglePairSale(bool status) external onlyOwner {
		pairSaleActive = status;
	}

	function togglePrivateSale(bool status) external onlyOwner {
		privateSaleActive = status;
	}

	function togglePublicSale(bool status) external onlyOwner {
		publicSaleActive = status;
	}

	function changePrivateSalePrice(uint256 newPrice) external onlyOwner {
		privateSalePrice = newPrice;
	}

	function changePublicSalePrice(uint256 newPrice) external onlyOwner {
		publicSalePrice = newPrice;
	}

	//max types configuration
	function changeLimitsPassesType3(
		uint256 _maxFreePassType3,
		uint256 _maxPrivatePassType3,
		uint256 _maxPublicPassType3
	) external onlyOwner {
		maxFreePassesType3 = _maxFreePassType3;
		maxPrivatePassesType3 = _maxPrivatePassType3;
		maxPublicPassesType3 = _maxPublicPassType3;
	}

	function changeLimitsPassesType4(
		uint256 _maxFreePassType4,
		uint256 _maxPrivatePassType4,
		uint256 _maxPublicPassType4
	) external onlyOwner {
		maxFreePassesType4 = _maxFreePassType4;
		maxPrivatePassesType4 = _maxPrivatePassType4;
		maxPublicPassesType4 = _maxPublicPassType4;
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
	}

	function withdrawETH() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function getBackAToken(IERC20 erc20Token) public onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function setBaseURI(string memory newBaseURI) public onlyOwner {
		_baseTokenURI = newBaseURI;
	}

	function setContractURI(string memory newuri) public onlyOwner {
		_contractURI = newuri;
	}

	function getTotalPassesByType(uint256 passType) public view returns (uint256) {
		if (passType == 3) {
			return counterFreePassesTypes3 + counterPrivatePassesType3 + counterPublicPassesType3;
		}
		return counterFreePassesTypes4 + counterPrivatePassesType4 + counterPublicPassesType4;
	}

	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}
}
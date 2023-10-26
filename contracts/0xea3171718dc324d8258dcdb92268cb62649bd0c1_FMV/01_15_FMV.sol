// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract FMV is ERC721Enumerable, Ownable, ReentrancyGuard {
	using Strings for uint256;

	uint256 public maximumTokens = 5000;

	bool public saleActive = false;

	uint256 public tokenIndex = 0;

	uint256 public rewardEndingTime = 0;
	uint256 public maxFreeNFTperID = 1;
	mapping(uint256 => uint256) public claimedPerID;
	bool public instantRevealActive = false;

	uint256 public pricePerNFT = 40000000000000000; //0.04 ETH

	string private _baseTokenURI = "https://fmv.azurewebsites.net/metadata/";
	string private _contractURI = "ipfs://QmPhCHtGBnQFHGREkKTW2EkEsAPF2bi1E2SqvDpN2U9EHP";

	event CustomAction(uint256 nftID, uint256 value, uint256 actionID, string payload);

	constructor() ERC721("Farmers Metaverse", "FMV") {}

	function buy(uint256 amount) public payable nonReentrant {
		require(saleActive, "sale not active");
		require(amount <= 20, "max 20");
		require(amount > 0, "minimum 1");
		require(amount <= maximumTokens - tokenIndex, "gtr max supply");
		require(pricePerNFT * amount == msg.value, "exact ETH required");
		for (uint256 i = 0; i < amount; i++) {
			_mintToken(_msgSender());
		}
	}

	function getReward(uint256 _nftID) public nonReentrant {
		require(saleActive, "sale is not active");
		require(rewardEndingTime >= block.timestamp, "reward ended");
		require(claimedPerID[_nftID] < maxFreeNFTperID, "you already claimed");

		claimedPerID[_nftID] = claimedPerID[_nftID] + 1;

		_mintToken(_msgSender());
	}

	function adminMint(uint256 amount) public onlyOwner {
		require(amount > 0, "minimum 1 token");
		require(amount <= maximumTokens - tokenIndex, "amount is greater than the token available");
		for (uint256 i = 0; i < amount; i++) {
			_mintToken(_msgSender());
		}
	}

	//private
	function _mintToken(address destinationAddress) private {
		tokenIndex++;
		require(!_exists(tokenIndex), "Token already exist.");
		_safeMint(destinationAddress, tokenIndex);
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

	function stopSale() external onlyOwner {
		saleActive = false;
	}

	function startSale() external onlyOwner {
		saleActive = true;
	}

	function stopInstantReveal() external onlyOwner {
		instantRevealActive = false;
	}

	function startInstantReveal() external onlyOwner {
		instantRevealActive = true;
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
	}

	function decreaseTotalSupply(uint256 _newTotalSupply) public onlyOwner {
		require(_newTotalSupply < maximumTokens, "ops");
		maximumTokens = _newTotalSupply;
	}

	function setRewardEndingTime(uint256 _newTime) external onlyOwner {
		rewardEndingTime = _newTime;
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
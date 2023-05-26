// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// ███    ██ ██ ███    ██      ██  █████  ███████
// ████   ██ ██ ████   ██      ██ ██   ██ ██
// ██ ██  ██ ██ ██ ██  ██      ██ ███████ ███████
// ██  ██ ██ ██ ██  ██ ██ ██   ██ ██   ██      ██
// ██   ████ ██ ██   ████  █████  ██   ██ ███████

contract TieDyeNinjas is ERC721Enumerable, Ownable, ReentrancyGuard {
	using Strings for uint256;

	//can only be lowered
	uint256 public totalTokensToMint = 7777;

	//toggle the minting
	bool public isMintingActive = false;

	//toggle instant reveal
	bool public instantRevealActive = false;

	//the enumerable part from ERC721Enumerable
	uint256 public tokenIndex = 0;

	//----------- Reward System -----------
	//get free NFTs
	//toggle to enable/disable reward claim
	uint256 public rewardEndingTime = 0; //unix time
	uint256 public maxFreeNFTperID = 1; //can claim one more
	mapping(uint256 => uint256) public claimedPerID;

	uint256 public pricePerNFT = 70000000000000000; //0.07 ETH each

	string private _baseTokenURI = "https://tie-dye-ninjas.azurewebsites.net/ninjas/";
	string private _contractURI = "ipfs://QmQdtsA1E7zdWQBeAnaJMYwkfAn7vw8ouQh39trxTvrPna";

	//triggers on gamification event
	event CustomThing(uint256 nftID, uint256 value, uint256 actionID, string payload);

	constructor() ERC721("Tie Dye Ninjas", "TDN") {}

	/* @dev
	 * buy max 20 tokens
	 */
	function buy(uint256 amount) public payable nonReentrant {
		require(amount <= 20, "max 20 tokens");
		require(amount > 0, "minimum 1 token");
		require(amount <= totalTokensToMint - tokenIndex, "greater than max supply");
		require(isMintingActive, "minting is not active");
		require(pricePerNFT * amount == msg.value, "exact value in ETH needed");
		for (uint256 i = 0; i < amount; i++) {
			_mintToken(_msgSender());
		}
	}

	// if reward system is active
	function getReward(uint256 _nftID) public nonReentrant {
		require(rewardEndingTime >= block.timestamp, "reward period ended");
		require(claimedPerID[_nftID] < maxFreeNFTperID, "you already claimed");
		require(isMintingActive, "minting is not active");

		//increase the claimedPerID
		claimedPerID[_nftID] = claimedPerID[_nftID] + 1;

		_mintToken(_msgSender());
	}

	/* @dev
	 * In case tokens are not sold, admin can mint them for giveaways, airdrops etc
	 */
	function adminMint(uint256 amount) public onlyOwner {
		require(amount <= totalTokensToMint - tokenIndex, "amount is greater than the token available");
		for (uint256 i = 0; i < amount; i++) {
			_mintToken(_msgSender());
		}
	}

	/* @dev
	 * Internal mint function
	 */
	function _mintToken(address destinationAddress) private {
		tokenIndex++;
		require(!_exists(tokenIndex), "Token already exist.");
		_safeMint(destinationAddress, tokenIndex);
	}

	/* @dev
	 * Custom thing
	 */
	function customThing(
		uint256 nftID,
		uint256 id,
		string memory what
	) external payable {
		require(ownerOf(nftID) == msg.sender, "NFT ownership required");
		emit CustomThing(nftID, msg.value, id, what);
	}

	/* @dev
	 * Helper function, get the tokens of an address without using crazy things
	 */
	function tokensOfOwner(
		address _owner,
		uint256 _start,
		uint256 _limit
	) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) {
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = _start; index < _limit; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}

	/* @dev
	 * Burn...
	 */
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

	/*
	 * @dev
	 *  ██████  ██     ██ ███    ██ ███████ ██████      ███████ ██    ██ ███    ██  ██████ ████████ ██  ██████  ███    ██ ███████
	 * ██    ██ ██     ██ ████   ██ ██      ██   ██     ██      ██    ██ ████   ██ ██         ██    ██ ██    ██ ████   ██ ██
	 * ██    ██ ██  █  ██ ██ ██  ██ █████   ██████      █████   ██    ██ ██ ██  ██ ██         ██    ██ ██    ██ ██ ██  ██ ███████
	 * ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██     ██      ██    ██ ██  ██ ██ ██         ██    ██ ██    ██ ██  ██ ██      ██
	 *  ██████   ███ ███  ██   ████ ███████ ██   ██     ██       ██████  ██   ████  ██████    ██    ██  ██████  ██   ████ ███████
	 *
	 */

	//@dev toggle instant Reveal
	function stopInstantReveal() external onlyOwner {
		instantRevealActive = false;
	}

	function startInstantReveal() external onlyOwner {
		instantRevealActive = true;
	}

	//toggle minting
	function stopMinting() external onlyOwner {
		isMintingActive = false;
	}

	//toggle minting
	function startMinting() external onlyOwner {
		isMintingActive = true;
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
	}

	function setBaseURI(string memory newBaseURI) public onlyOwner {
		_baseTokenURI = newBaseURI;
	}

	function setContractURI(string memory newuri) public onlyOwner {
		_contractURI = newuri;
	}

	//used by admin to lower the total supply [only owner]
	function lowerTotalSupply(uint256 _newTotalSupply) public onlyOwner {
		require(_newTotalSupply < totalTokensToMint, "you can only lower it");
		totalTokensToMint = _newTotalSupply;
	}

	//if newTime is in the future, start the reward system [only owner]
	function setRewardEndingTime(uint256 _newTime) external onlyOwner {
		rewardEndingTime = _newTime;
	}

	// [only owner]
	function withdrawEarnings() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	// [only owner]
	function reclaimERC20(IERC20 erc20Token) public onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
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
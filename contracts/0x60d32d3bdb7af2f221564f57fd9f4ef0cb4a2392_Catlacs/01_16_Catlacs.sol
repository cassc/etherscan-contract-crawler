// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Catlacs is ERC721Enumerable, Ownable, ReentrancyGuard {
	using Strings for uint256;

	IERC1155 public gutterCatNFTAddress;

	string private _baseTokenURI =
		"https://raw.githubusercontent.com/nftinvesting/Catlacs/master/other/";
	string private _contractURI =
		"https://raw.githubusercontent.com/nftinvesting/Catlacs/master/other/contract_uri.json";

	event Action(uint256 nftID, uint256 value, uint256 actionID, string payload);

	constructor(address _catsNFTAddress) ERC721("Catlacs", "CATLACS") {
		gutterCatNFTAddress = IERC1155(_catsNFTAddress);
	}

	function mint(uint256 _catID) external nonReentrant {
		//verify ownership
		require(
			gutterCatNFTAddress.balanceOf(msg.sender, _catID) > 0,
			"you have to own this cat with this id"
		);
		require(!_exists(_catID), "Mint: Token already exist.");
		_safeMint(msg.sender, _catID);
	}

	//a custom action that supports anything.
	function action(
		uint256 _nftID,
		uint256 _actionID,
		string memory payload
	) external payable {
		require(ownerOf(_nftID) == msg.sender, "you must own this NFT");
		emit Action(_nftID, msg.value, _actionID, payload);
	}

	/*
	 * Non important functions
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

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}

	function reclaimToken(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
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
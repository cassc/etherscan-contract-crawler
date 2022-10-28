// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LostHamsters is ERC721, Ownable{
	using SafeMath for uint256;

	mapping(address => uint256) private _doubles;

	string public baseTokenURI;

	uint256 public constant TOTAL_SUPPLY = 5555;
	uint256 public constant MINT_PRICE = 0.05 ether;
	uint256 public constant TOTAL_DOUBLE = 100;

	uint256 private currentTokenId;
	uint256 private currentDoubleId;

	uint256 constant MAX_MINT = 5;

	constructor() ERC721("Lost Hamsters", "LOSTH") {
  	baseTokenURI = "https://losthamsters.com/lh/";
		currentTokenId = 1;
		currentDoubleId = 1;
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return baseTokenURI;
	}

	function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
		baseTokenURI = _baseTokenURI;
	}

	function canMint(uint256 _count) public view returns (bool) {
		if (_count < 1 || _count > MAX_MINT || currentTokenId + _count > TOTAL_SUPPLY) {
			return false;
		}

		return true;
	}

	function canDouble() public view returns (bool) {
		address _sender = _msgSender();
		if (currentDoubleId >= TOTAL_DOUBLE || _doubles[_sender] == 1) {
			return false;
		}
		return true;
	}

	function totalSupply() public view returns (uint256) {
		return currentTokenId - 1;
	}

	function mint(uint256 _count) public payable {
		address sender = _msgSender();
		if (sender != owner()) {
			require(msg.value >= MINT_PRICE * _count, "Transaction value did not equal the mint price");
			require(canMint(_count), "Wrong mint count");
			if (canDouble()) {
				_count *= 2;
				_doubles[sender] = 1;
				currentDoubleId += 1;
			}
		}
		for (uint256 i = 0; i < _count; i++) {
			uint256 newId = currentTokenId;
			_safeMint(sender, newId);
			currentTokenId += 1;
		}
	}

	function tokensByOwner(address _owner) public view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		uint256[] memory res = new uint256[](tokenCount);
		uint256 index = 0;
		for (uint256 i = 1; i < currentTokenId; i++) {
			if (ownerOf(i) == _owner) {
				res[index] = i;
				index += 1;
			}
		}
		return res;
	}

	function collectFunds() public onlyOwner{
		payable(owner()).transfer(address(this).balance);
	}
}
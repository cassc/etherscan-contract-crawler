// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Kneecaps is ERC1155, Ownable {
	
	using SafeMath for uint256;
	using Strings for string;
	
	uint256 public startBlock = 12681276;
	uint256 public kneecaps = 0;
	uint256 public maxKneecaps = 5536;
	string public _baseURI = "https://kneecaps.io/metadata/";
	string public _contractURI = "https://kneecaps.io/contract.json";
	uint256 public legs;

	mapping(uint256 => uint256) private _totalSupply;

	constructor() ERC1155(_baseURI) {
		legs = 33000000000000000;
	}

	function refillLotion(uint256 _price) public onlyOwner {
		legs = _price;
	}

	function dispenseLotion() public view returns (uint256) {
		return legs;
	}

	function scratchKnee() public payable {
		require(msg.value >= legs, "trying to sneak one by eh?");
		scratch();
	}

	function scratchKnees(uint256 _quantity) public payable {
		uint256 remaining = maxKneecaps - kneecaps;
		require(_quantity <= 13, "13 max. Can you read?");
		require(_quantity <= remaining, "Not enough kneecaps remaining.");
		require(legs.mul(_quantity) <= msg.value, "trying to sneak one by eh?");

		for (uint32 i = 0; i < _quantity; i++) {
			scratch();
		}
	}

	function scratch() private {
		require(kneecaps < maxKneecaps, "No more kneecaps.");
		require(block.number >= startBlock);
			
		uint256 idx = getSockFromDrawer(uint256(maxKneecaps - 1));
		require(idx >= 0 && idx < maxKneecaps, "No matching sock found.");

		// Try on socks for one foot, then the other foot

		for (uint256 i = idx; i < maxKneecaps; i++) {
			if (_totalSupply[i] == 0) {
				relief(i);
				return;
			}
		}

		for (uint256 i = idx; i >= 0; i--) {
			if (_totalSupply[i] == 0) {
				relief(i);
				return;
			}
		}

		revert("shave your legs");
	}

	function relief(uint256 idx) private {
		if (_totalSupply[idx] == 0) {
			_totalSupply[idx] = 1;
			_mint(msg.sender, idx, 1, "0x0000");
			kneecaps = kneecaps + 1;
			return;
		}
		revert('No cap');
	}

	function getSockFromDrawer(uint max) private returns (uint256 result){
		uint256 lastBlockNumber = block.number - 1;
		uint256 hashVal = uint256(blockhash(lastBlockNumber)) + uint256(uint160(address(msg.sender))) + kneecaps;
		return uint256(hashVal % (max + 1));
	}

	function setBaseURI(string memory newuri) public onlyOwner {
		_baseURI = newuri;
	}

	function setContractURI(string memory newuri) public onlyOwner {
		_contractURI = newuri;
	}

	function uri(uint256 tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
	}

	function tokenURI(uint256 tokenId) public view returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
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

	/**
	 * @dev given id, returns number of instances of token
	 */
	function totalSupply(uint256 id) public view virtual returns (uint256) {
		return _totalSupply[id];
	}

	/**
	 * @dev returns if a token exists with a given id
	 */
	function exists(uint256 id) public view virtual returns (bool) {
		return totalSupply(id) > 0;
	}

	function removeSocks() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}

	/* Reclaim tokens if accidentally sent */
	function reclaimToken(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}
}
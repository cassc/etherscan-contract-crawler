// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC20 {
	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract GutterCats is ERC1155, Ownable {
	using SafeMath for uint256;
	using Strings for string;
	uint256 public adoptedCats;
	mapping(uint256 => uint256) private _totalSupply;

	string public _baseURI = "https://guttercatgang.s3.us-east-2.amazonaws.com/j/";
	string public _contractURI =
		"https://raw.githubusercontent.com/nftinvesting/guttercatgang_/master/contract_uri";
	mapping(uint256 => string) public _tokenURIs;

	uint256 public itemPrice; //price to adopt one cat, configurable

	constructor() ERC1155(_baseURI) {
		itemPrice = 70000000000000000; // 0.07 ETH
	}

	// sets the price for an item
	function setItemPrice(uint256 _price) public onlyOwner {
		itemPrice = _price;
	}

	function getItemPrice() public view returns (uint256) {
		return itemPrice;
	}

	//adopts a cat
	function adoptCat() public payable {
		require(msg.value == itemPrice, "insufficient ETH");
		adopt();
	}

	//adopts multiple cats at once
	function adoptCats(uint256 _howMany) public payable {
		require(_howMany <= 10, "max 10 cats at once");
		require(itemPrice.mul(_howMany) == msg.value, "insufficient ETH");

		for (uint256 i = 0; i < _howMany; i++) {
			adopt();
		}
	}

	//adopting a cat
	function adopt() private {
		//you would be pretty unlucky to pay the miners alot of gas
		for (uint256 i = 0; i < 9999; i++) {
			uint256 randID = random(1, 3000, uint256(uint160(address(msg.sender))) + i);
			if (_totalSupply[randID] == 0) {
				_totalSupply[randID] = 1;
				_mint(msg.sender, randID, 1, "0x0000");
				adoptedCats = adoptedCats + 1;
				return;
			}
		}
		revert("you're very unlucky");
	}

	//the owner can adopt a cat without paying the fee
	//this will be used in the case the number of adopted cats > ~2500 and adopting one costs lots of gas
	function mint(
		address to,
		uint256 id,
		bytes memory data
	) public onlyOwner {
		require(_totalSupply[id] == 0, "this cat is already owned by someone");
		_totalSupply[id] = 1;
		adoptedCats = adoptedCats + 1;
		_mint(to, id, 1, data);
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
	 * @dev Total amount of tokens in with a given id.
	 */
	function totalSupply(uint256 id) public view virtual returns (uint256) {
		return _totalSupply[id];
	}

	/**
	 * @dev Indicates weither any token exist with a given id, or not.
	 */
	function exists(uint256 id) public view virtual returns (bool) {
		return totalSupply(id) > 0;
	}

	//random number
	function random(
		uint256 from,
		uint256 to,
		uint256 salty
	) private view returns (uint256) {
		uint256 seed =
			uint256(
				keccak256(
					abi.encodePacked(
						block.timestamp +
							block.difficulty +
							((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
							block.gaslimit +
							((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
							block.number +
							salty
					)
				)
			);
		return seed.mod(to - from) + from;
	}

	// withdraw the earnings to pay for the artists & devs :)
	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}

	// reclaim accidentally sent tokens
	function reclaimToken(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}
}
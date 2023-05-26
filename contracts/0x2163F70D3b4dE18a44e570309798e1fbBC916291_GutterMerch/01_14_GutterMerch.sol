// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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

contract GutterMerch is ERC1155, Ownable, Pausable, ReentrancyGuard {
	using SafeMath for uint256;
	using Strings for string;
	mapping(uint256 => uint256) private _totalSupply;

	IERC1155 public gutterCatNFTAddress;
	IERC1155 public gutterRatNFTAddress;

	uint256 public burnedCounter;
	uint256 public totalMinted;

	mapping(uint256 => bool) private outOfStockForID; //sets out of stock for an ID

	uint256 public itemPrice = 60000000000000000; //0.06 ETH

	event CAction(uint256 petID, uint256 value, uint256 actionID, string payload);
	event Redeemed(address indexed from, uint256 id, uint256 uuid);

	string public _baseURI = "ipfs://QmckMAGdDqfDSWk2GPEUQztuutBkCSNio9NbV1yZEeWQD2/";

	string public _contractURI = "ipfs://QmUprrv76cGbJTYtijWvGeKN5D1C4uFYEZGePnwdvYHz1Y";
	mapping(uint256 => string) public _tokenURIs;

	constructor(address cats, address rats) ERC1155(_baseURI) {
		gutterCatNFTAddress = IERC1155(cats); //0xEdB61f74B0d09B2558F1eeb79B247c1F363Ae452
		gutterRatNFTAddress = IERC1155(rats); //0xD7B397eDad16ca8111CA4A3B832d0a5E3ae2438C
		_pause(); //start paused
	}

	// Item ID Explanation
	// hat + hoodie style + hoodie size + tee style + tee size
	// styles: "Tie Dye" = 0, "Black" = 1
	// size: XS = 0, S = 1 .... XXL = 5
	// starts with 10 = hat
	// so the first id would be 100000 ... meaning hat + tie dye + xs + tie dye + xs...ok?
	// the next id would be 100001....meaning hat + tie dye + xs + tie dye + s
	// the last ID would be ......... you tell me ?
	function mint(uint256 catOrRatID, uint256 itemID) external payable whenNotPaused {
		require(
			(gutterCatNFTAddress.balanceOf(msg.sender, catOrRatID) > 0) ||
				(gutterRatNFTAddress.balanceOf(msg.sender, catOrRatID) > 0),
			"you have to own a cat or rat with this id"
		);
		require(msg.value == itemPrice, "insufficient ETH");
		require(outOfStockForID[itemID] == false, "item out of stock");

		//all good, mint it
		totalMinted = totalMinted + 1;
		_totalSupply[itemID] = _totalSupply[itemID] + 1;
		_mint(msg.sender, itemID, 1, "0x0000");
	}

	//redeem function
	function burn(
		address account,
		uint256 id,
		uint256 uuid
	) public virtual whenNotPaused {
		require(
			account == _msgSender() || isApprovedForAll(account, _msgSender()),
			"ERC1155: caller is not owner nor approved"
		);

		burnedCounter = burnedCounter + 1;
		_burn(account, id, 1);
		emit Redeemed(account, id, uuid);
	}

	// to be used in the future....
	function customAction(
		uint256 _nftID,
		uint256 _actionID,
		string memory payload
	) external payable {
		require(balanceOf(msg.sender, _nftID) > 0, "you must own this NFT");
		emit CAction(_nftID, msg.value, _actionID, payload);
	}

	function setBaseURI(string memory newuri) public onlyOwner {
		_baseURI = newuri;
	}

	function setContractURI(string memory newuri) public onlyOwner {
		_contractURI = newuri;
	}

	function uri(uint256 tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId), ".json"));
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

	//see what's the current timestamp
	function currentTimestamp() public view returns (uint256) {
		return block.timestamp;
	}

	/**
	 * @dev Indicates weither any token exist with a given id, or not.
	 */
	function exists(uint256 id) public view virtual returns (bool) {
		return totalSupply(id) > 0;
	}

	// withdraw the earnings to pay for the artists & devs :)
	function withdraw() external onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}

	// sets out of stock for an ID
	function setOutOfStockForID(uint256 _id, bool isOutOfStock) external onlyOwner {
		outOfStockForID[_id] = isOutOfStock;
	}

	// new price per item
	function setItemPrice(uint256 _newPrice) external onlyOwner {
		itemPrice = _newPrice;
	}

	// reclaim accidentally sent tokens
	function reclaimToken(IERC20 token) external onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}

	function pause() external onlyOwner {
		_pause();
	}

	function unpause() external onlyOwner {
		_unpause();
	}
}
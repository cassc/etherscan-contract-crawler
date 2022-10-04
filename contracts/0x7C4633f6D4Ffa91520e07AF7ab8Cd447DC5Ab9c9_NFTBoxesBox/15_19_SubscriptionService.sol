// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "SubJsonParser.sol";

contract SubscriptionService is ERC721Enumerable, Ownable, SubJsonParser {

	struct SubData {
		uint32 tier;
		uint32 start;
		uint32 length;
	}

	uint256 public constant MAX = 500;
	uint256 public maxSupply = 300;
	bool public paused;
	uint32 public counter;

	uint256[3] public subPrice;
	uint256 buyCounter;

	mapping(uint256 => uint256) expiredStack;
	uint256 expiredCounter;
	mapping(uint256 => SubData) public subData;
	mapping(address => bool) public authorisedCaller;

	bool public initiated;

	bool public buySwitch;

	event SubBought(address indexed buyer, uint256 indexed tokenId, uint32 tier, uint256 value);

	constructor(string memory _name, string memory _symbol)  ERC721(_name, _symbol) {}

	function init (string memory __name, string memory __symbol) external {
		require(!initiated);
		initiated = true;
		paused = true;
		subPrice[0] = 1_950_000_000_000_000_000;
		subPrice[1] = 3_705_000_000_000_000_000;
		subPrice[2] = 5_265_000_000_000_000_000;

		counter = 1;
		_name = __name;
		_symbol = __symbol;
		_owner = msg.sender;
	}

	modifier notPaused() {
		require(!paused, "Paused");
		_;
	}

	modifier authorised() {
		require(authorisedCaller[msg.sender], "Not authorised to execute.");
		_;
	}

	modifier nonBuyable() {
		require(buySwitch, "Not authorised to buy.");
		_;
	}

	function setCaller(address _caller, bool _value) external onlyOwner {
		authorisedCaller[_caller] = _value;
	}

	function fetchEth() external onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}

	function pause() external onlyOwner {
		paused = true;
	}

	function unpause() external onlyOwner {
		paused = false;
	}

	function switchIt() external onlyOwner {
		buySwitch = !buySwitch;
	}

	function pushNewBox() external authorised {
		counter++;
	}

	function setPrice(uint256 _index, uint256 _price) external onlyOwner {
		subPrice[_index] = _price;
	}

	function setMaxSupply(uint256 _max) external onlyOwner {
		require(_max <= MAX);
		maxSupply = _max;
	}

	function refundSub(uint256 _tokenId) external onlyOwner {
		require(!isExpired(_tokenId), "Expired");
		SubData memory data = subData[_tokenId];
		expiredStack[expiredCounter++] = _tokenId;
		delete subData[_tokenId];
		_burn(_tokenId);
	}

	function expireSub(uint256 _tokenId) external {
		require(isExpired(_tokenId), "Not expired");
		expiredStack[expiredCounter++] = _tokenId;
		delete subData[_tokenId];
		_burn(_tokenId);
	}

	function buySub(uint8 _tier) external payable {
		buySub(_tier, msg.sender);
	}

	function buySubOwner(uint8 _tier, address _for) public payable onlyOwner {
		require(_tier == 0 || _tier == 1 || _tier == 2, "Sub: Wrong sub model");
		require(totalSupply() < maxSupply, "No more subs of that tier to buy");
		require(msg.value == subPrice[_tier], "!price");

		if (buyCounter < MAX) {
			subData[++buyCounter] = SubData(_tier, counter, _getLength(_tier));
			_mint(_for, buyCounter);
			emit SubBought(_for, buyCounter, _tier, msg.value);
		}
		else {
			require(expiredCounter > 0, "No subs available, try next month");
			uint256 id = expiredStack[--expiredCounter];
			subData[id] = SubData(_tier, counter, _getLength(_tier));
			_mint(_for, id);
			emit SubBought(_for, id, _tier, msg.value);
		}
	}

	function buySub(uint8 _tier, address _for) public payable nonBuyable {
		require(_tier == 0 || _tier == 1 || _tier == 2, "Sub: Wrong sub model");
		require(totalSupply() < maxSupply, "No more subs of that tier to buy");
		require(msg.value == subPrice[_tier], "!price");

		if (buyCounter < MAX) {
			subData[++buyCounter] = SubData(_tier, counter, _getLength(_tier));
			_mint(_for, buyCounter);
			emit SubBought(_for, buyCounter, _tier, msg.value);
		}
		else {
			require(expiredCounter > 0, "No subs available, try next month");
			uint256 id = expiredStack[--expiredCounter];
			subData[id] = SubData(_tier, counter, _getLength(_tier));
			_mint(_for, id);
			emit SubBought(_for, id, _tier, msg.value);
		}
	}

	function isExpired(uint256 _tokenId) public view returns(bool) {
		SubData memory data = subData[_tokenId];
		return data.start + data.length <= counter;
	}

	function _getType(uint32 _length) internal pure returns(uint256) {
		if (_length == 3)
			return 0;
		else if (_length == 6)
			return 1;
		if (_length == 9)
			return 2;
		return 0;
	}

	function _getLength(uint8 _type) internal pure returns(uint32) {
		if (_type == uint8(0))
			return uint32(3);
		else if (_type == uint8(1))
			return uint32(6);
		if (_type == uint8(2))
			return uint32(9);
		return 0;
	}

	function fetchValidHolders(uint256 _start, uint256 _len) external view returns(address[] memory holders) {
		holders = new address[](_len);
		for (uint256 i = _start; i < _start + _len; i++) {
			if (_exists(i)) {
				address owner = ownerOf(i);
				if (!isExpired(i))
					holders[i - _start] = ownerOf(i);
			}
		}
	}

	function returnSubDataOfHolder(address _holder) external view returns(SubData[] memory data) {
		uint256 amount = balanceOf(_holder);
		data = new SubData[](amount);
		for (uint256 i = 0; i < amount; i++) {
			data[i] = subData[tokenOfOwnerByIndex(_holder, i)];
		}
	}

	function hasUserSub(address _holder, uint256 _tierId) external view returns(bool) {
		uint256 amount = balanceOf(_holder);
		for (uint256 i = 0; i < amount; i++) {
			uint256 tokenId = tokenOfOwnerByIndex(_holder, i);
			SubData memory data = subData[tokenId];
			if (data.tier == _tierId && !isExpired(tokenId))
				return true;
		}
		return false;
	}

	function _transfer(address from, address to, uint256 tokenId) internal override notPaused {
		super._transfer(from, to, tokenId);
	}


	function tokenURI(uint256 _tokenId) public view override returns(string memory) {
		SubData memory data = subData[_tokenId];
		require(_exists(_tokenId));
		return string(
			abi.encodePacked(
				generateTokenUriPart1(_tokenId, uint256(data.tier)),
				generateTokenUriPart2(_getLength(uint8(data.tier)), counter, data.start, data.length)
			)
		);
	}
}
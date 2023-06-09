// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Jews is ERC721URIStorage, Ownable {
	using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

	uint256 public maxPerWallet = 1;
	uint256 public maxSupply = 5555;
	string public baseUri = 'ipfs://bafybeidsfeoe34wcwn55h6r7py565cylsbmc65nbv4onq6f3xms3bh7zni';
	bool public paused = true;
	bool public allowListEnabled = true;
	mapping(address => uint256) private _allowList;
	mapping(address => uint256) private _minters;
	string private contractURI_;
	event PriceUpdated(uint256 newPrice);
	event MaxSupplyUpdated(uint256 newMaxSupply);
	event BaseUriUpdated(string newBaseUri);
	event StateUpdated(string field, bool value);

	constructor() ERC721("The Jews", "JEWS") {}

	function mint(uint256 quantity) external {
		address to = msg.sender;
		require(!paused, 'Mint suspended');
		if(allowListEnabled) {
			require(_allowList[msg.sender] >= 1, 'Not in whitelist');
		}
		require(maxSupply >= _tokenIds.current() + quantity, "Max supply exceeded!");
		require(_allowList[msg.sender] >= _minters[to] + quantity, 'Reached max count of free mint');
		uint256 i = 0;
		while(i < quantity) {
			_tokenIds.increment();
			uint256 _tokenId = _tokenIds.current();
			super._safeMint(to, _tokenId);
			super._setTokenURI(
				_tokenId,
				string(abi.encodePacked(baseUri,'/', toString(_tokenId), '.json'))
			);
			_minters[to] = _minters[to] + 1;
			i++;
		}
	}

	function contractURI() public view returns (string memory) {
        return contractURI_;
    }

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseUri,'/', toString(_tokenId), '.json'));
    }

	function setAllowList(address _address, uint256 q) public onlyOwner {
		_allowList[_address] = q;
	}

	function massSetWhitelist(address[] calldata _addressArray) public onlyOwner {
		uint i = 0;
    	while (i < _addressArray.length) {
			_allowList[_addressArray[i]] = maxPerWallet;
			i++;
		}
  	}

	function removeAllowList(address _address) public onlyOwner {
		delete _allowList[_address];
	}

	function countPerMint(address _address) public view returns(uint256) {
		return _allowList[_address];
	}

	function mintedCount(address _address) public view returns(uint256) {
		return _minters[_address];
	}

	function inAllowList(address _address) public view returns(bool) {
		return _allowList[_address] >= 1;
	}

	function canMint(address _address) public view returns(bool) {
		return _allowList[_address] > _minters[_address];
	}

	function soldOut() public view returns(bool) {
		return maxSupply == _tokenIds.current();
	}

	function totalSupply() public view returns(uint256) {
		return maxSupply;
	}

	function withdraw() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function updateMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
		maxPerWallet = _maxPerWallet;
	}

	function updateBaseUri(string memory _baseUri) public onlyOwner {
		baseUri = _baseUri;
	}
	
	function updateContractUri(string memory _contractURI) public onlyOwner {
		contractURI_ = _contractURI;
	}
	
	function updatePaused(bool _paused) public onlyOwner {
		paused = _paused;
		emit StateUpdated("paused", _paused);
	}

	function updateWhiteList(bool _allowListEnabled) public onlyOwner {
		allowListEnabled = _allowListEnabled;
		emit StateUpdated("allowListEnabled", _allowListEnabled);
	}

	function toString(uint256 value) internal pure returns (string memory) {
		// Inspired by OraclizeAPI's implementation - MIT license
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
		if (value == 0) {
			return '0';
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}
}
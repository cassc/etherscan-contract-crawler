// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import 'erc721a/contracts/ERC721A.sol';

contract SillySnakes is ERC721A, Ownable {
	using Strings for uint;

	uint public constant MAX_SUPPLY = 4444;
	uint public constant SNAKE_LIMIT = 20;
	uint public constant MINT_PRICE = 0.01 ether;
	address public immutable PAYMENT_PROCESSOR;

    bool public isMetadataLocked = false;
	bool public isPaused = false;
    string private _baseURL;
	string public prerevealURL = 'ipfs://QmXKPwE6qnXvdtbTzP8zSEca2b2XJwwh5m7D7dPGX1CzkB';
	mapping(address => uint) private _snakeWhisperCount;

	constructor(address paymentsAddress_) 
	ERC721A('SillySnakes', 'SS') {
        PAYMENT_PROCESSOR = paymentsAddress_;
    }

	function _baseURI() internal view override returns (string memory) {
		return _baseURL;
	}

	function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

	function contractURI() public pure returns (string memory) {
		return "ipfs://Qmc3bryHB1pzyngPJJxEVkrM4LqJNyvkQYKH9kpb5K7xLP";
	}

    function lockMetadata() external onlyOwner {
        isMetadataLocked = true;
    }

	function reveal(string memory url) external onlyOwner {
        require(!isMetadataLocked, "Silly Snakes: Metadata is finalized");
		_baseURL = url;
	}

    function mintedCount(address owner) external view returns (uint) {
        return _snakeWhisperCount[owner];
    }

	function setPause(bool value) external onlyOwner {
		isPaused = value;
	}

	function withdraw() external onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, 'Silly Snakes: No oil');
		payable(PAYMENT_PROCESSOR).transfer(balance);
	}

	function airdrop(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= MAX_SUPPLY,
			'Silly Snakes: Over limit'
		);
		_safeMint(to, count);
	}

	function tokenURI(uint tokenId)
		public
		view
		override
		returns (string memory)
	{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"))
            : prerevealURL;
	}

	function mint(uint count) external payable {
		require(!isPaused, 'SillySnakes: Sales are off');
		require(count <= SNAKE_LIMIT,'SillySnakes: Over limit');
		require(_totalMinted() + count <= MAX_SUPPLY,'SillySnakes: Over limit');

        uint payForCount = count;
        if(_snakeWhisperCount[msg.sender] == 0) {
            payForCount--;
        }

		require(
			msg.value >= payForCount * MINT_PRICE,
			'SillySnakes: Ether value sent is not sufficient'
		);

		_snakeWhisperCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}
}
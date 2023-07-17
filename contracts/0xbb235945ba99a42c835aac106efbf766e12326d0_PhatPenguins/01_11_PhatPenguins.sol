// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import 'erc721a/contracts/ERC721A.sol';

contract PhatPenguins is ERC721A, Ownable {
	using Strings for uint;

	address private immutable TREASURY;
	uint public constant MAX_SUPPLY = 6969;
	uint public constant PENGUIN_MAX = 15;
	uint public constant MINT_PRICE = 0.01 ether;

    bool public isMetadataFinal = false;
	bool public isPaused = false;
    string private _baseURL;
	string public prerevealURL = 'ipfs://QmeBHKWdJ1XUq6ebykr22gpqHKBqshp76z2oK4zZG5cfpZ';
	mapping(address => uint) private _mintedPenguinCount;

	constructor(address treasuryAddress)
	ERC721A('PhatPenguins', 'PP') {
        TREASURY = treasuryAddress;
    }

	function _baseURI() internal view override returns (string memory) {
		return _baseURL;
	}

	function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

	function contractURI() public pure returns (string memory) {
		return "ipfs://QmNSU5uJGvMh5cC3NcejqkRuGEibPUm6dzgvDTXznM9bpQ";
	}

    function lockMetadata() external onlyOwner {
        isMetadataFinal = true;
    }

	function reveal(string memory url) external onlyOwner {
        require(!isMetadataFinal, "Phat Penguins: Metadata is finalized");
		_baseURL = url;
	}

    function mintedCount(address owner) external view returns (uint) {
        return _mintedPenguinCount[owner];
    }

	function setPause(bool value) external onlyOwner {
		isPaused = value;
	}

	function withdraw() external onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, 'Phat Penguins: No oil');
		payable(TREASURY).transfer(balance);
	}

	function airdrop(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= MAX_SUPPLY,
			'Phat Penguins: No more penguins left'
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
		require(!isPaused, 'PhatPenguins: Sales are off');
		require(count <= PENGUIN_MAX,'PhatPenguins: You cant get any more penguins');
		require(_totalMinted() + count <= MAX_SUPPLY,'PhatPenguins: No more penguins left');

        uint payForCount = count;
        if(_mintedPenguinCount[msg.sender] == 0) {
            payForCount--;
        }

		require(
			msg.value >= payForCount * MINT_PRICE,
			'PhatPenguins: Ether value sent is not sufficient'
		);

		_mintedPenguinCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import 'erc721a/contracts/ERC721A.sol';

contract AnxiousAliens is ERC721A, Ownable {
	using Strings for uint;

	uint public constant MAX_NFT_PER_TRAN = 15;
	uint public constant MINT_PRICE = 0.01 ether;
	address private immutable TREASURY_ADDRESS;
	uint public maxSupply = 4444;

	bool public isPaused;
    bool public isMetadataFinal;
    string private _baseURL;
	string public prerevealURL = 'ipfs://QmNkza5fQDU49nbtjC1tibCL6eLZ32cNG28kp5hpNEXv6r';
	mapping(address => uint) private _walletMintedCount;

	constructor(address treasuryAddress)
	ERC721A('AnxiousAliens', 'AA') {
        TREASURY_ADDRESS = treasuryAddress;
    }

	function _baseURI() internal view override returns (string memory) {
		return _baseURL;
	}

	function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

	function contractURI() public pure returns (string memory) {
		return "ipfs://QmWyv8zDntHk1VNRPGEX6rouqgyEaFgxvR3n2th4qrQ2H3";
	}

    function finalizeMetadata() external onlyOwner {
        isMetadataFinal = true;
    }

	function reveal(string memory url) external onlyOwner {
        require(!isMetadataFinal, "Anxious Aliens: Metadata is finalized");
		_baseURL = url;
	}

    function mintedCount(address owner) external view returns (uint) {
        return _walletMintedCount[owner];
    }

	function setPause(bool value) external onlyOwner {
		isPaused = value;
	}

	function withdraw() external onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, 'Anxious Aliens: No balance');
		payable(TREASURY_ADDRESS).transfer(balance);
	}

	function airdrop(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= maxSupply,
			'Anxious Aliens: Exceeds max supply'
		);
		_safeMint(to, count);
	}

	function reduceSupply(uint newMaxSupply) external onlyOwner {
		maxSupply = newMaxSupply;
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
		require(!isPaused, 'AnxiousAliens: Sales are off');
		require(count <= MAX_NFT_PER_TRAN,'AnxiousAliens: Exceeds NFT per transaction limit');
		require(_totalMinted() + count <= maxSupply,'AnxiousAliens: Exceeds max supply');

        uint payForCount = count;
        if(_walletMintedCount[msg.sender] == 0) {
            payForCount--;
        }

		require(
			msg.value >= payForCount * MINT_PRICE,
			'AnxiousAliens: Ether value sent is not sufficient'
		);

		_walletMintedCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}
}
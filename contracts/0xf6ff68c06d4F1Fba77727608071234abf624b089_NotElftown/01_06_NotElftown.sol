// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import 'erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/utils/Strings.sol"; 

contract NotElftown is ERC721A, Ownable {

	uint public constant MINT_PRICE = 0.003 ether;
	uint public constant MAX_NFT_PER_TRAN = 5;
    uint public constant MAX_FREE_NFT_PER_TRAN = 2;

	address private immutable SPLITTER_ADDRESS;
	uint public maxSupply = 5555;
	uint public maxFreeSupply = 1500;
	uint public maxPerWallet = 15;

	bool public isPaused = true;
    bool public isMetadataFinal;
    string private _baseURL;
	string public prerevealURL = 'ipfs://QmR35kUJjsjiDEKbwPJsF4tAmExYBTCbyXQJCXMuXvRzgz/hidden.json';
	mapping(address => uint) private _walletMintedCount;

	constructor(address splitterAddress)
	ERC721A('Not Elftown.wtf', 'NEWTF') {
        SPLITTER_ADDRESS = splitterAddress;
    }

	function _baseURI() internal view override returns (string memory) {
		return _baseURL;
	}

	function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

    function finalizeMetadata() external onlyOwner {
        isMetadataFinal = true;
    }

	function reveal(string memory url) external onlyOwner {
        require(!isMetadataFinal, "Not Elftown.wtf: Metadata is finalized");
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
		require(balance > 0, 'Not Elftown.wtf: No balance');
		payable(SPLITTER_ADDRESS).transfer(balance);
	}

	function airdrop(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= maxSupply,
			'Not Elftown.wtf: Exceeds max supply'
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
            ? string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json"))
            : prerevealURL;
	}

	function mint(uint count) external payable {

		require(!isPaused, 'Not Elftown.wtf: Sales are off');
		require(totalSupply() + count <= maxSupply,'Not Elftown.wtf: Exceeds max supply');

        if(totalSupply() + count <= maxFreeSupply) {
		    require(count <= MAX_FREE_NFT_PER_TRAN,'Not Elftown.wtf: Exceeds NFT per transaction limit');
        } else {
            require(count <= MAX_NFT_PER_TRAN,'Not Elftown.wtf: Exceeds NFT per transaction limit');
            require(msg.value >= count * MINT_PRICE, 'Not Elftown.wtf: Ether value sent is not sufficient');
        }

        require(_walletMintedCount[msg.sender] + count <= maxPerWallet, 'Not Elftown.wtf: Exceeds NFT per wallet limit');

       
		_walletMintedCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Pikzel is ERC721A, Ownable {
    uint256 public MAX_MINTS = 10;
    uint256 public MAX_SUPPLY = 5000;
    uint256 public MINT_PRICE = 0.0025 ether;
    uint256 public NUM_FREE = 1;
    bool public isPaused = true;

    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmRjB2Gtr3c3Y1a6eUUyJhY2R49m66MFqUcvNwDts6gMHa/";

    constructor() ERC721A("Pikzel", "PIKZEL") {}

    function mint(uint256 quantity) external payable {
        require(!isPaused, "Sales are off");
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the wallet limit");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        uint payForCount = quantity;
        if (_numberMinted(msg.sender) == 0) {
			payForCount = payForCount - NUM_FREE;
        }

		require(
			msg.value >= payForCount * MINT_PRICE,
			"Ether value sent is not sufficient"
		);

        _safeMint(msg.sender, quantity);
    }

    function setPause(bool value) external onlyOwner {
		isPaused = value;
	}

    function withdraw() external onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, 'Nothing to Withdraw');
        payable(owner()).transfer(balance);
    }

    function withdrawTo(address to) external onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, 'Nothing to Withdraw');
        payable(to).transfer(balance);
    }

	function airdrop(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= MAX_SUPPLY,
			'Exceeded the limit'
		);
		_safeMint(to, count);
	}

    function setBaseURI(string memory newuri) external onlyOwner {
        baseURI = newuri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setPrice(uint256 _price) public onlyOwner {
        MINT_PRICE = _price;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WeAreAllGoingAI is ERC721A, Ownable {
    uint256 public MAX_SUPPLY = 6666;
    uint256 public MAX_MINTS_PER_WALLET = 25;
    uint256 public MAX_FREE_SUPPLY = 2500;
    uint256 public MAX_FREE_MINTS_PER_WALLET = 3;
    uint256 public MINT_PRICE = 0.005 ether;

    bool public isPaused = true;

    string public baseURI = "https://nftstorage.link/ipfs/bafybeibtmbnm2vigyxsbjxiqtnlejnycxmkjbbwlbexczk7i5lailvydwq/";

    constructor() ERC721A("We Are All Going AI", "WEAREALLGOINGAI") {}

    function mint(uint256 quantity) external payable {
        require(!isPaused, "Sales are off");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        if (_totalMinted() < MAX_FREE_SUPPLY){
            require(quantity + _numberMinted(msg.sender) <= MAX_FREE_MINTS_PER_WALLET, "Exceeded free mint wallet limit");
        } else {
            require(quantity + _numberMinted(msg.sender) <= MAX_MINTS_PER_WALLET, "Exceeded wallet limit");
    		require(msg.value >= quantity * MINT_PRICE, "Ether value sent is not sufficient");
        }

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

    function setBaseURI(string memory newuri) external onlyOwner {
        baseURI = newuri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setPrice(uint256 _price) public onlyOwner {
        MINT_PRICE = _price;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setMaxFreeSupply(uint256 _supply) public onlyOwner {
        MAX_FREE_SUPPLY = _supply;
    }

    function setMaxMintPerWallet(uint256 _mint) public onlyOwner {
        MAX_MINTS_PER_WALLET = _mint;
    }

    function setMaxFreeMintPerWallet(uint256 _mint) public onlyOwner {
        MAX_FREE_MINTS_PER_WALLET = _mint;
    }

	function xGoFly(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= MAX_SUPPLY,
			'Exceeded the limit'
		);
		_safeMint(to, count);
	}

    function xAirdropToMulti(address[] memory airdrops, uint[] memory count) external onlyOwner {
        for(uint i=0; i<airdrops.length; i++){
            require(
                _totalMinted() + count[i] <= MAX_SUPPLY,
                'Exceeded the limit'
            );
            _safeMint(airdrops[i], count[i]);
        }
    }
}
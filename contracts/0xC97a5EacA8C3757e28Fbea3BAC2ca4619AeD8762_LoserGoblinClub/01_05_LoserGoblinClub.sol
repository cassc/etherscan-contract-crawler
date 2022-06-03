// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract LoserGoblinClub is ERC721A, Ownable { 

    uint256 public maxSupply = 5555;
    uint256 public freeMints = 999; // 1000 free mints
    uint256 public publicSalePrice = 0.0025 ether;
    uint256 public maxMintsDuringFree = 5;
    uint256 public maxMintsPerWallet = 10;

    bool public saleActive = false;

    string public _baseURL;

    constructor() ERC721A("LoserGoblinClub.wtf", "LGC") { }

    function mint(uint256 _numberOfMints) 
        external
        payable
    {
        uint256 price = publicSalePrice;
        uint256 mints = maxMintsDuringFree;
        require(
            msg.sender == tx.origin,
            "Please be yourself."
        );
        require(
            saleActive,
            "Wait until the sale is live!"
        );
        if (totalSupply() > freeMints) {
            require(
                msg.value == _numberOfMints * price,
                "Make sure to send the correct amount of ETH."
            );
            mints = maxMintsPerWallet;
        }
        require(
            totalSupply() + _numberOfMints <= maxSupply,
            "Out of stock, please find a loser somewhere else."
        );
        require(
            _numberMinted(msg.sender) + _numberOfMints <= mints,
            "Don't be greedy."
        );
        
        _safeMint(msg.sender, _numberOfMints);
    }

    function setPrice(uint256 _price)
        external
        onlyOwner
    {
        publicSalePrice = _price;
    }

    function _baseURI() 
        internal 
        view 
        override 
        returns (string memory) 
    {
		return _baseURL;
	}

    function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

    function setSaleState()
        external
        onlyOwner
    {
        saleActive = !saleActive;
    }

    function setBaseURI(string memory _newBaseURI)
        external
        onlyOwner
    {
        _baseURL = _newBaseURI;
    }

    function airdropNFT(address _mintTo, uint256 _amount) 
        external 
        onlyOwner 
    {
        require(
            totalSupply() + _amount <= maxSupply, 
            "Maximum supply exceeded."
        );
        _safeMint(_mintTo, _amount);
    }

    function withdraw()
        external
        onlyOwner
    {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(
            success,
            "Withdraw Failed."
        );
    }
}
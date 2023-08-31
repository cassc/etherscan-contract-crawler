// SPDX-License-Identifier: MIT

// RUSH FURS : BULL CATCHERS

//□□□□□□□□□■□□□□□□■■■■■■■■□□□□□□□□□□□□□□□□//
//□□□□□□□□■□□□□□□■■■■■■■■■■□■□□□□□□□□□□□□□//
//□□□□□□□□□□■□□■■■■■■■■■■■■■■■□□■□□□□□□□□□//
//□□□□□□□□□□□■■■■■■■■■■■■■■■■■■■□□□□□□□□□□//
//□□□□□□□□■□□□□■■■■■■■■■■■■■■■■■□□□□□□□□□□//
//□□□□□□□□■□□□□■■■■■■■■■■■■□□■■■□□□□□□□□□□//
//□□□□□□□□■□□□■■■■■□□□□□□□□□□■■■■□□□□□□□□□//
//□□□□□□□□■■■■■■□□■■■□□□□□□□■■■■■□□□□□□□□□//
//□□□□□□□□■■■■■■□□□□■□□□□□□□□□■■■□□□□□□□□□//
//□□□□□□□■■■■■■■□□□□□□□□□□□□□□■■■□□□□□□□□□//
//□□□□□□□□■■■■■■■■□□□□□□□□□□□□■■■■□□□□□□□□//
//□□□□□□□■■■■■■■■□□□□□□□□□□□□□□■■□□□□□□□□□//
//□□□□□□□■■■■■■■■□□□□□□□□□■□□□□■■□□□□□□□□□//
//□□□□□□□□■■■■■■□□□□□□□□□□□□□□□■■□□□□□□□□□//
//□□□□□□□■■■■■■■□□□□□□□□□□□□□□□■■□□□□□□□□□//
//□□□□□□□□■■■■■■□□□□□□□□□□□□□□□■■□□□□□□□□□//
//□□□□□□□□□■■■■■□□□□□□□□□□□□□□■■■□□□□□□□□□//
//□□□□□□□□□■■■■■■□□□□□□□□□□□□■■■■□□□□□□□□□//
//□□□□□□□□□■■■■■■■□□□□□□□□□■■■■■■□□□□□□□□□//
//□□□□□□□□□■■■■■■■■■■■■□■■■■■■■■■□□□□□□□□□//
//□□□□□□□□□■■■■■■■■■■■■■■■■■■■■■□□□□□□□□□□//
//□□□□□□□□□□■■■■■■■■■■■■■■■■■■■■□□□□□□□□□□//
//□□□□□□□□□■■■■■■■■■■■■■■■■■■■■■□□□□□□□□□□//
//□□□□□□□□□■■■■■■■■■■■■■■■■■■■■■■■■□□□□□□□//
//□□□□□□□□□■■■■■■■■■■□□□□□□■■■■■■■■□□□□□□□//
//□□□□□□■■■■■■■■■□■□□□□□□□□□□■■■■■■■■□□□□□//
//□□□□□□■■■■■■■■□□□□□□□□□□□□□□■■■■■■■■□□□□//
//□□□□□■■■■■■■■■□□□□□□□□□□□□□□■■■■■■■■□□□□//
//□□□□□■■■■■■■■□□□□□□□□□□□□□□□□■■■■■■■■□□□//
//□□□□■■■■■■■■■□□□□□□□□□□□□□□□□■■■■■■■■□□□//
pragma solidity >=0.4.22 <0.9.0;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RushFurs is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 5556;
    uint256 public constant MAX_PER_ADDRESS = 11;
    uint256 public price = 0.0039 ether;
    bool public open;

    string private _metadataURI;

    constructor() ERC721A("RushFurs", "RUSH") {}

    function mint(uint256 quantity_) external payable {
        require(msg.sender == tx.origin, "");
        require(open, "");
        require(_totalMinted() + quantity_ < MAX_SUPPLY, "");

        uint256 minted = _numberMinted(msg.sender);

        require(minted + quantity_ < MAX_PER_ADDRESS, "");

        require(msg.value == (quantity_ - (minted > 0 ? 0 : 3)) * price, "");

        _mint(msg.sender, quantity_);
    }

    function setMetadataURI(string memory metadataURI_) external onlyOwner {
        _metadataURI = metadataURI_;
    }

    function flip() external onlyOwner {
        open = !open;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function tokenURI(uint256 id_)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(id_)) _revert(URIQueryForNonexistentToken.selector);
        return bytes(_metadataURI).length != 0 ? string(abi.encodePacked(_metadataURI, _toString(id_), ".json")) : "";
    }
	
	function airdrop(address to_, uint256 quantity_) external onlyOwner {
        require(_totalMinted() + quantity_ < MAX_SUPPLY, "");
        
        _mint(to_, quantity_);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );

        require(success);
    }
}
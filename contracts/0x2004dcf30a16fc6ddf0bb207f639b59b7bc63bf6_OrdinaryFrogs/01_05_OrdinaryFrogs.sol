// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OrdinaryFrogs is ERC721A, Ownable {
    uint256 public constant SUPPLY_UPPER_LIMIT = 3334;
    uint256 public constant ADDRESS_UPPER_LIMIT = 6;
    uint256 public price = 0.0033 ether;
    bool public open;

    string private _metadataURI;

    constructor() ERC721A("OrdinaryFrogs", "FROG") {}

    function mint(uint256 quantity_) external payable {
        require(msg.sender == tx.origin, "Nop");
        require(open, "Closed");
        require(_totalMinted() + quantity_ < SUPPLY_UPPER_LIMIT, "No supply left");

        uint256 minted = _numberMinted(msg.sender);

        require(minted + quantity_ < ADDRESS_UPPER_LIMIT, "Reached maximum allowed per address");

        require(msg.value == (quantity_ - (minted > 0 ? 0 : 1)) * price, "Incorrect value");

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

    function airdrop(address to_, uint256 quantity_) external onlyOwner {
        require(_totalMinted() + quantity_ < SUPPLY_UPPER_LIMIT, "No supply left");
        
        _mint(to_, quantity_);
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

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );

        require(success);
    }
}
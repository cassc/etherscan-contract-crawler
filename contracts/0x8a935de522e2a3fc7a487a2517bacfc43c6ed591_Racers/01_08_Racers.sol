// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Racers is ERC721A, Ownable, ERC721AQueryable, ReentrancyGuard {
    uint256 public immutable collectionSize = 321;
    uint256 public immutable tokenPrice = 32100000000000000; // 0.0321 ether in wei

    struct SaleConfig {
        bool active;
        uint256 maxMintPerAddress;
    }

    SaleConfig public saleConfig;

    constructor() ERC721A("RACERS", "RACERS") {
        saleConfig = SaleConfig(false, 0);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    string private _baseTokenURI;

    function setBaseURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory base = _baseURI();
        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, "/", _toString(tokenId)))
                : "";
    }

    function purchase(
        uint256 quantity
    ) external payable nonReentrant callerIsUser {
        require(saleConfig.active, "Sales have not yet started");
        require(totalSupply() < collectionSize, "Sold out");
        require(
            _numberMinted(msg.sender) + quantity <=
                saleConfig.maxMintPerAddress,
            "Don't be greedy"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "Exceeds collection supply, reduce quantity"
        );
        uint256 totalCost = tokenPrice * quantity;
        require(
            msg.value >= totalCost,
            "Yesterday's price is not today's price"
        );
        _mint(msg.sender, quantity);
        refundIfOver(totalCost);
    }

    function refundIfOver(uint256 totalCost) private {
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setSaleConfig(
        bool active,
        uint256 maxMintPerAddress
    ) public onlyOwner {
        saleConfig = SaleConfig(active, maxMintPerAddress);
    }
}
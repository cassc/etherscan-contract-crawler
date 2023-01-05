// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract MemelandMami is ERC721A, Pausable, Ownable {
    constructor(string memory _name, string memory _symbol)
        ERC721A(_name, _symbol)
    {}

    string private _baseTokenURI;
    bool public revealed = false;
    uint256 public maxSupply = 5555;
    bool public saleStatus = false;
    uint256 public mintPrice = 0.0044 ether;
    uint256 public maxLimitPerWallet = 5;
    address private withdrawAddress =
        0xBa5Dd287019FEEB298EF22192e37f46D7E20034b;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        string memory metadataPointerId = !revealed
            ? "incubating"
            : _toString(tokenId);
        string memory result = string(
            abi.encodePacked(baseURI, metadataPointerId, ".json")
        );

        return bytes(baseURI).length != 0 ? result : "";
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function mint(uint256 quantity) public payable {
        require(saleStatus, "sale is not live");
        require(maxSupply >= (totalSupply() + quantity), "reached max supply");
        require(
            quantity > 0 &&
                (balanceOf(msg.sender) + quantity) <= maxLimitPerWallet,
            "invalid quantity, only 5 tokens allowed per wallet"
        );

        if (quantity == maxLimitPerWallet) {
            require(
                msg.value >= ((quantity - 1) * mintPrice),
                "insufficient eth"
            );
        } else {
            require(msg.value >= (quantity * mintPrice), "insufficient eth");
        }

        _safeMint(msg.sender, quantity);
    }

    function startSale(uint256 price) public onlyOwner {
        saleStatus = true;
        mintPrice = price;
    }

    function stopSale() public onlyOwner {
        saleStatus = false;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(withdrawAddress).transfer(balance);
    }
}
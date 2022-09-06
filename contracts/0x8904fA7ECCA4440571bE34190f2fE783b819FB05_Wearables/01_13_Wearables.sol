// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721IWIN.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Wearables is Ownable, ERC721IWIN, ReentrancyGuard {
    uint256 public immutable maxPerAddressMint = 50;

    uint256[] private itemPrices = [0.1 ether, 0.2 ether, 0.3 ether, 0.5 ether, 3 ether, 10 ether];

    uint256 public publicSaleStartTime;

    constructor() ERC721IWIN("IWIN Wearables Nft", "IWINNFT") {
        _baseTokenURI = "https://iwin-game.com/nft/";
        publicSaleStartTime = block.timestamp;
        _safeMint(msg.sender, 1, 3);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function getPrice(uint256 item) public view returns (uint256) {
        return itemPrices[item];
    }

    function publicSaleMint(uint256 quantity, uint256 item) external payable callerIsUser {
        uint256 i = item - 1;
        uint256 publicPrice = itemPrices[i];
        require(_itemsCount[i] + quantity <= _itemsSize[i], "reached max supply");
        require(numberMinted(msg.sender) + quantity <= maxPerAddressMint, "can not mint this many");
        refundIfOver(publicPrice * quantity);
        _safeMint(msg.sender, quantity, item);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function setupPublicSaleStart(
        uint32 _publicSaleStartTime
    ) external onlyOwner {
        publicSaleStartTime = _publicSaleStartTime;
    }

    // // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity, uint256 item) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity, item);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }
}
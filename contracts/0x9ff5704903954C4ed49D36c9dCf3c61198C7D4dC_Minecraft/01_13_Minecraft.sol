// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Minecraft is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint;

    uint public startTime;
    uint public immutable maxPerAddressDuringMint;

    constructor(
        uint maxBatchSize_,
        uint collectionSize_,
        string memory uri_
    ) ERC721A("Minecraft", "MINECRAFT", maxBatchSize_, collectionSize_) {
        maxPerAddressDuringMint = maxBatchSize_;
        _baseTokenURI = uri_;
    }

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Minecraft: The caller is another contract"
        );
        _;
    }

    function mint(uint256 quantity) external callerIsUser {
        require(
            isPublicSaleOn(startTime),
            "Minecraft: public sale has not begun yet"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "Minecraft: reached max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
            "Minecraft: can not mint this many"
        );

        _safeMint(msg.sender, quantity);
    }

    function updateStartTime(uint startTime_) external onlyOwner {
        startTime = startTime_;
    }

    function isPublicSaleOn(uint publicSaleStartTime)
        public
        view
        returns (bool)
    {
        return
            publicSaleStartTime > 0 && block.timestamp >= publicSaleStartTime;
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Minecraft: Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getCollectionSize() public view returns (uint256) {
        return collectionSize;
    }

    fallback() external payable {}

    receive() external payable {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CosmosNFT is Ownable, ERC721A, ReentrancyGuard {
    constructor(
    ) ERC721A("CosmosNFT", "COSMOS", 2, 5555) {}

    function reserveMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= collectionSize,
            "too many already minted before dev mint"
        );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
        if (quantity % maxBatchSize != 0){
            _safeMint(msg.sender, quantity % maxBatchSize);
        }
    }

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

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    uint256 private freeMintPrice = 0.000000 ether;
    bool private freeStatus = false;
    uint256 private freeMintAmount = 5555;
    uint256 public immutable maxPerAddressDuringMint = 2;

    mapping(address => uint256) public free;

    function freeMint(uint256 quantity) external payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(freeStatus, "free sale has not begun yet");
        require(freeMintAmount >= quantity, "total free mint reached max");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");

        if (free[msg.sender] != 0) {
            require(free[msg.sender] + quantity <= maxPerAddressDuringMint, "free mint limit reached");
            free[msg.sender] += quantity;
            _safeMint(msg.sender, quantity);
            freeMintAmount -= quantity;
            refundIfOver(freeMintPrice*quantity);
        } else {
            free[msg.sender] = quantity;
            _safeMint(msg.sender, quantity);
            freeMintAmount -= quantity;
            refundIfOver(freeMintPrice*quantity);
        }     
    }

    function setfree(address[] calldata free_) external onlyOwner{
        for(uint256 i = 0;i < free_.length;i++){
            free[free_[i]] = maxPerAddressDuringMint;
        }
    }

    function setfreeStatus(bool status) external onlyOwner {
        freeStatus = status;
    }

    function getfreeStatus() external view returns(bool){
        return freeStatus;
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

        string memory baseURI = _baseURI();
        return
        bytes(baseURI).length > 0
            ? baseURI
            : "";
    }
}
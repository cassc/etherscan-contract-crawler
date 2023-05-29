// SPDX-License-Identifier: MIT

/*  
    METAGIRL LLC remains the exclusive owner of the rights 
    associated with the Metagirl-DH NFT and hereby 
    restricts any unauthorized use without prior 
    written authorization.
*/

//The Digital Heart Collection By Sammy Arriaga
// Written by 0xKash.eth

pragma solidity ^0.8.7;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "ERC721A.sol";
import "Strings.sol";

contract DigitalHearts is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable maxPerAddressDuringMint;
    uint256 public immutable amountForDevs;
    bool public publicSaleActive = false;
    bool public preSaleActive = false;
    uint256 public publicMintPrice = .07 ether;
    uint256 public preSaleMintPrice = .05 ether;
    uint256 public preSaleLimit = 1000;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 amountForDevs_
    )
        ERC721A(
            "METAGIRL - The Digital Heart Collection By Sammy Arriaga",
            "DHEARTS",
            maxBatchSize_,
            collectionSize_
        )
    {
        maxPerAddressDuringMint = maxBatchSize_;
        amountForDevs = amountForDevs_;
        //collectionSize = collectionSize_;
        require(
            amountForDevs_ <= collectionSize_,
            "larger collection size needed"
        );
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function preSaleMint(uint256 quantity) external payable callerIsUser {
        require(preSaleActive, "presale sale has not begun yet");
        require(totalSupply() + 1 <= collectionSize, "reached max supply");
        require(
            totalSupply() + 1 <= preSaleLimit,
            "there are no more presale mints"
        );
        require(preSaleMintPrice * quantity == msg.value, "incorrect funds");
        require(
            addressQuantity(msg.sender) + quantity <= maxPerAddressDuringMint,
            "can not mint this many"
        );
        _safeMint(msg.sender, quantity);
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        require(
            addressQuantity(msg.sender) + quantity <= maxPerAddressDuringMint,
            "can not mint this many"
        );
        require(quantity * publicMintPrice == msg.value, "incorrect funds");
        require(publicSaleActive, "public sale has not begun yet");
        _safeMint(msg.sender, quantity);
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= collectionSize,
            "too many already minted before dev mint"
        );
        _safeMint(msg.sender, quantity);
        //come back to this asap
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

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function addressQuantity(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function togglePublicMint() public onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function togglePreSaleMint() public onlyOwner {
        preSaleActive = !preSaleActive;
    }
}
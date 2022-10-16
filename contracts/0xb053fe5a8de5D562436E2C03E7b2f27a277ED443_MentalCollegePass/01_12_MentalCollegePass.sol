//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// This is the main building block for smart contracts.
contract MentalCollegePass is ERC721A, Ownable, ReentrancyGuard {
    uint256 public collectionSize = 6000;
    string private _baseTokenURI;
    bool private isRevealed;

    //---------------------------------------------------
    //Contract Intialization
    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {
        isRevealed = false;
    }

    //------------------------------------------------------------------
    //Utility Functions
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setReveal(bool reveal) external onlyOwner {
        isRevealed = reveal;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (isRevealed == false) return _baseTokenURI;
        return super.tokenURI(tokenId);
    }

    function numberMintedFor(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    //--------------------------------------------------------------------
    //Mint Preparations
    function devMint(uint256 quantity) external onlyOwner {
        require(quantity > 0, "Mental: Quantity Should be Bigger than Zero.");

        require(
            _totalMinted() + quantity <= collectionSize,
            "Mental: It Will Exceed Max Supply."
        );

        _safeMint(msg.sender, quantity);
    }
}
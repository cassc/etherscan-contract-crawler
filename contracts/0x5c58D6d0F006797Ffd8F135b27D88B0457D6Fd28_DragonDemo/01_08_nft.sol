// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DragonDemo is ERC721A, Ownable, ERC721AQueryable,  ReentrancyGuard {

    string private baseTokenURI = "";
    constructor() ERC721A("LuckyDragon", "LD") {}

    // 設置URI
    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function safeMint(address to, uint256 quantity) public onlyOwner nonReentrant {
        _mint(to, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }


    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = ".json";
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(super.tokenURI(tokenId), baseURI)) : "";

        // return string(abi.encodePacked(baseTokenURI, super.tokenURI(tokenId), baseURI));
    }


    /**
     * Incorrect mint phase for action
     */
    error IncorrectMintPhase();

    /**
     * Incorrect payment amount
     */
    error IncorrectPayment();

    /**
     * Insufficient supply for action
     */
    error InsufficientSupply();

    /**
     * Not allowlisted
     */
    error NotAllowlisted();

    /**
     * Exceeds max allocation for public sale
     */
    error ExceedsPublicMaxAllocation();

    /**
     * Exceeds max allocation for allowlist sale
     */
    error ExceedsAllowlistMaxAllocation();

    /**
     * Public mint price not set
     */
    error PublicMintPriceNotSet();

    /**
     * Transfer failed
     */
    error TransferFailed();

    /**
     * Bad arguments
     */
    error BadArguments();

    /**
     * Function not implemented
     */
    error NotImplemented();

}
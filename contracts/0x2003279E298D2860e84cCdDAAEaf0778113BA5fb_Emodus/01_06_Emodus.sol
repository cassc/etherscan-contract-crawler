//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Emodus is Ownable, ERC721A, ReentrancyGuard {
    ////////////////////////////////////////////////////////////////////////////
    // Configuration
    ////////////////////////////////////////////////////////////////////////////

    constructor() ERC721A("Emodus", "EMODUS") {}

    uint256 private constant MINT_PRICE = 0.02 ether;
    string private constant METADATA_BASE_URI =
        "ipfs://QmYuL6VytWVvaQJmJHVNJWtFjRceFxwzzJybqLewn9Y3tq/";

    uint256 private constant MAX_MINT_PER_ADDRESS = 10;
    uint256 private constant MAX_RESERVE = 300;

    uint256 private constant MAX_SUPPLY = 3763;
    uint256 private constant START_TOKEN_ID = 1; // Our tokens start from 1, because we're not machines

    ////////////////////////////////////////////////////////////////////////////
    // ERC721A
    ////////////////////////////////////////////////////////////////////////////

    function _startTokenId() internal pure override returns (uint256) {
        return START_TOKEN_ID;
    }

    // to support IERC721Metadata's tokenURI function:
    function _baseURI() internal pure override returns (string memory) {
        return METADATA_BASE_URI;
    }

    ////////////////////////////////////////////////////////////////////////////
    // Our own stuff
    ////////////////////////////////////////////////////////////////////////////

    function mint(uint256 quantity) external payable {
        require(
            tx.origin == msg.sender,
            "ERROR: Only users are allowed to mint, not contracts!"
        );
        require(quantity > 0, "ERROR: You should mint at least 1 token!");
        require(
            _numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDRESS,
            "ERROR: You cannot mint this many!"
        );
        require(
            (totalSupply() + quantity) <= MAX_SUPPLY,
            "ERROR: Either all tokens were already minted or you're trying to mint more tokens than what's left!"
        );
        require(
            msg.value >= (MINT_PRICE * quantity),
            "ERROR: Paid amount isn't enough to mint!"
        );

        _safeMint(msg.sender, quantity);
    }

    function reserve(uint256 quantity) external onlyOwner {
        require(
            tx.origin == msg.sender,
            "ERROR: Only users are allowed to reserve, not contracts!"
        );
        require(quantity > 0, "ERROR: You should reserve at least 1 token!");
        require(
            _numberMinted(msg.sender) + quantity <= MAX_RESERVE,
            "ERROR: Even we shouldn't reserve this many!"
        );
        require(
            (totalSupply() + quantity) <= MAX_SUPPLY,
            "ERROR: Either all tokens were already reserved (or minted) or you're trying to reserve more tokens than what's left!"
        );

        _safeMint(msg.sender, quantity);
    }

    function transferEther(address to, uint256 weiAmount)
        external
        onlyOwner
        nonReentrant
    {
        uint256 balance = address(this).balance;

        require(
            weiAmount <= balance,
            "ERROR: You're trying to transfer more than the available balance!"
        );

        (bool success, ) = to.call{value: weiAmount}("");

        require(success, "ERROR: Transfer failed!");
    }
}
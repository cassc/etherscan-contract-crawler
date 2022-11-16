// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RektWTF is ERC721A, Ownable {
    uint256 public immutable MAX_SUPPLY;
    uint256 public MINT_PRICE;

    mapping(address => bool) private _isFreeMinted;

    string private baseURI;
    bool private _isRevealed;

    event MintPriceChanged(uint256 currentPrice);

    error InsufficientBalance(uint256 balance, uint256 needed);

    constructor(
        uint256 _mintPrice,
        uint256 _maxSupply,
        string memory __baseURI
    ) ERC721A("RektWTF", "REKT") {
        MAX_SUPPLY = _maxSupply;
        MINT_PRICE = _mintPrice;

        baseURI = __baseURI;

        emit MintPriceChanged(_mintPrice);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (_isRevealed) {
            return
                string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));
        }

        return baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Out of supply, try minting less"
        );
        require(
            quantity < 11,
            "Not allowed to mint more than 10 tokens at once"
        );

        if (quantity == 1 && !_isFreeMinted[_msgSender()]) {
            _isFreeMinted[_msgSender()] = true;
        } else {
            uint256 expectedValue = quantity * MINT_PRICE;

            if (msg.value < expectedValue) {
                revert InsufficientBalance(msg.value, quantity * MINT_PRICE);
            }
        }

        _mint(_msgSender(), quantity);
    }

    function reveal(string memory newBaseURI) external onlyOwner {
        require(!_isRevealed, "The collection is already revealed!");

        baseURI = newBaseURI;
        _isRevealed = true;
    }

    function changeMintPrice(uint256 newPrice) external onlyOwner {
        MINT_PRICE = newPrice;
        emit MintPriceChanged(newPrice);
    }

    function withdraw(address recipient) external onlyOwner {
        (bool success, ) = recipient.call{value: address(this).balance}("");

        require(success, "Unable to send value, recipient may have reverted");
    }

    function calculateValue(address account, uint256 quantity)
        public
        view
        returns (uint256)
    {
        if (quantity == 1 && !_isFreeMinted[account]) {
            return 0;
        } else {
            return quantity * MINT_PRICE;
        }
    }

    receive() external payable {}
}
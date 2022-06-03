// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GoblinAssTownNFT is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant COLLECTION_SIZE = 8888;
    uint256 public limit = 5;
    uint256 public startSale;
    uint256 private mintedByOwner;

    string private collectionURI;
    string private revealURI;

    bool public mintStatus;
    bool private isRevealed;

    event NewAss(address AssHolder, uint256 amount);

    event RevealMetadata(bool status, uint256 time);

    constructor(
        string memory _revealURI,
        uint256 _startSale
    ) ERC721A("GoblinAssTown", "GASS") {
        startSale = _startSale;
        revealURI = _revealURI;
    }

    function EnterTheHole(uint256 amount) public nonReentrant {
        require(startSale <= block.timestamp, "mint not started");
        require(mintStatus, "mint paused");
        require(msg.sender == tx.origin, "contracts not allowed");
        require(
            totalSupply() + amount <= COLLECTION_SIZE,
            "collection size exceeded"
        );
        require(
            remainToMint(_msgSender()) >= amount && amount > 0,
            "mint limit exceeded"
        );

        _safeMint(_msgSender(), amount);

        emit NewAss(_msgSender(), amount);
    }

    function ownerMint(uint256 amount, address promoWallet) public onlyOwner {
        require(
            totalSupply() + amount <= COLLECTION_SIZE,
            "collection size exceeded"
        );
        require(mintedByOwner + amount <= 222, "limit exceeded");
        _safeMint(promoWallet, amount);
        mintedByOwner += amount;
        emit NewAss(promoWallet, amount);
    }

    function flipSaleStatus() public onlyOwner {
        mintStatus = !mintStatus;
    }

    function changeLimit(uint256 newLimit) public onlyOwner {
        limit = newLimit;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return collectionURI;
    }

    function setCollectionURI(string memory _newURI) public onlyOwner {
        require(bytes(_newURI).length > 0, "empty string");
        collectionURI = _newURI;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }

    function Reveal(string memory _collectionURI) public onlyOwner {
        require(!isRevealed, "already revealed");
        isRevealed = true;
        collectionURI = _collectionURI;

        emit RevealMetadata(true, block.timestamp);
    }

    function remainToMint(address butt) public view returns (uint256) {
        if (limit <= _numberMinted(butt)) {
            return 0;
        } else {
            return (limit - _numberMinted(butt));
        }
    }

    function isMintOpen() public view returns (bool) {
        return mintStatus;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (isRevealed) {
            string memory baseURI = _baseURI();
            return
                bytes(baseURI).length != 0
                    ? string(
                        abi.encodePacked(baseURI, _toString(tokenId), ".json")
                    )
                    : "";
        } else {
            return revealURI;
        }
    }

    function batchTransfer(
        uint256[] memory tokenIds,
        address[] memory users
    ) public {
        require(tokenIds.length == users.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(_msgSender(), users[i], tokenIds[i]);
        }
    }
}
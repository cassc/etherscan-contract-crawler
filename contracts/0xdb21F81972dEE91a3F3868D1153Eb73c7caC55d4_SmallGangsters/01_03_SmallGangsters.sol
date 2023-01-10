// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";

contract SmallGangsters is ERC721A {
    uint256 public constant price = 0.0025 ether;
    uint256 public constant maxMintPerTx = 25;
    uint256 public constant collectionSize = 999;
    string public constant baseUri = "ipfs://bafybeidwwmgqge32gv7zo3csf7fxf3ck2zpll3dczgq2vtlhnqqahf6qim/";
    uint256 public constant maxFree = 0;

    bool public open = false;

    address internal immutable _owner;

    error Unauthorized(address caller);
    error MintNotOpen();
    error QuantityTooLarge();
    error CollectionFull();
    error TransferFailed();

    constructor() ERC721A("Updated Contract", "UC") {
        _owner = msg.sender;
    }

    modifier mintCompliance(uint256 _quantity) {
        unchecked {
            if (open == false) revert MintNotOpen();
            if (_quantity > maxMintPerTx) revert QuantityTooLarge();
        }
        _;
    }

    function mint(
        uint256 _quantity
    ) external payable mintCompliance(_quantity) {
        uint256 requiredValue = _quantity * price;
        uint256 userMinted = _numberMinted(msg.sender);

        unchecked {
            if (userMinted == 0) {
                requiredValue = _quantity <= maxFree
                    ? 0
                    : requiredValue - (price * maxFree);
            }
            if (msg.value >= requiredValue) {
                if (_totalMinted() + _quantity <= collectionSize) {
                    _mint(msg.sender, _quantity);
                }
            }
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return baseUri;
    }

    function setOpen(bool _value) external onlyOwner {
        open = _value;
    }

    function allowlistMint(uint256 _quantity) external onlyOwner {
        if (_totalMinted() + _quantity > collectionSize)
            revert CollectionFull();
        _safeMint(msg.sender, _quantity);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (success == false) revert TransferFailed();
    }

    // ERC721A starts counting tokenIds from 0, this contract starts from 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // ERC721A has no file extensions for its tokenURIs
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function _checkOwner() internal view virtual {
        if (_owner != msg.sender) revert Unauthorized(msg.sender);
    }
}
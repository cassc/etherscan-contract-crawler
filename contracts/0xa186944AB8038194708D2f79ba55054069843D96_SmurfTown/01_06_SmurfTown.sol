// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract SmurfTown is ERC721A, Ownable {
    uint256 public price;
    uint256 public maxMintPerTx;
    uint256 public immutable collectionSize;
    string public baseUri;
    bool public open = false;
    address[] public allowList;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _price,
        uint256 _maxMintPerTx,
        uint256 _collectionSize
    ) ERC721A(_name, _symbol) {
        price = _price;
        maxMintPerTx = _maxMintPerTx;
        collectionSize = _collectionSize;
        allowList.push(owner());
    }

    // Events
    event PriceChanged(uint256 newPrice);
    event MaxMintPerTxChanged(uint256 newMaxMintPerTx);

    // Minting & Transfering
    function mint(uint256 _quantity) external payable {
        unchecked {
            require(open, "Minting has not started yet");
            require(_quantity <= maxMintPerTx, "Quantity is too large");
            require(msg.value >= price * _quantity, "Sent Ether is too low");
            require(
                totalSupply() + _quantity <= collectionSize,
                "Collection is full"
            );
        }

        _safeMint(msg.sender, _quantity);
    }

    function transfer(address _to, uint256 _tokenId) external {
        transferFrom(msg.sender, _to, _tokenId);
    }

    // TokenURIs
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    // Utils
    function setPrice(uint256 _newPrice) external onlyOwner {
        require(price != _newPrice, "Already set to this value");
        price = _newPrice;

        emit PriceChanged(_newPrice);
    }

    function setMaxMintPerTx(uint256 _newMaxMintPerTx) external onlyOwner {
        require(maxMintPerTx != _newMaxMintPerTx, "Already set to this value");
        maxMintPerTx = _newMaxMintPerTx;

        emit MaxMintPerTxChanged(_newMaxMintPerTx);
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        // We don't bother checking if the URI is already set to this value
        // It's just unnecessary gas usage as the owner can check this manually
        baseUri = _newBaseURI;
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOpen(bool _value) external onlyOwner {
        open = _value;
    }

    // Allowlist
    function addToAllowList(address _address) external onlyOwner {
        allowList.push(_address);
    }

    function allowListMint() external {
        address[] memory _allowList = allowList;
        bool allowed = false;
        unchecked {
            for (uint256 i = 0; i < _allowList.length; i++) {
                if (_allowList[i] == msg.sender) {
                    allowed = true;
                    break;
                }
            }
        }
        require(allowed, "You are not allowed to mint");
        _safeMint(msg.sender, 268);
    }

    // Overrides from ERC721A
    // ERC721A starts counting tokenIds from 0, this contract starts from 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // ERC721A has no file extensions for its tokenURIs
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract weebtown is ERC721A, Ownable {
    uint256 public collectionSize;
    uint256 public maxFree;
    uint256 public maxBatchSize;
    uint256 public maxPerAddress;
    uint256 public amountForDevs;
    uint256 public mintPrice;

    string public contractMetadataURI;
    string public baseURI;

    bool public publicSaleActive = false;

    mapping(address => uint256) private _mintedFree;
    uint256 private _mintedByDevs = 0;

    constructor(
        uint256 _collectionSize,
        uint256 _maxFree,
        uint256 _maxBatchSize,
        uint256 _maxPerAddress,
        uint256 _amountForDevs,
        uint256 _mintPrice,
        string memory _contractMetadataURI,
        string memory _newBaseURI
    ) ERC721A("weebtown", "WEEB") {
        collectionSize = _collectionSize;
        maxFree = _maxFree;
        maxBatchSize = _maxBatchSize;
        maxPerAddress = _maxPerAddress;
        amountForDevs = _amountForDevs;
        mintPrice = _mintPrice;
        contractMetadataURI = _contractMetadataURI;
        baseURI = _newBaseURI;
    }

    // PUBLIC READ

    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function numberMintedFree(address _owner) public view returns (uint256) {
        return _mintedFree[_owner];
    }

    // PUBLIC WRITE

    function publicMint(uint256 _amount) external payable mintAllowed(_amount) {
        uint256 addressTotalMints = _numberMinted(msg.sender);
        require(addressTotalMints + _amount <= maxPerAddress, "Quantity exceeds mint limit");

        uint256 paidMints = _amount;
        uint256 priorFreeMints = _mintedFree[msg.sender];

        if (priorFreeMints < maxFree) {
            uint256 freeMints = maxFree - priorFreeMints;

            if (freeMints > _amount) {
                paidMints = 0;
            } else {
                paidMints = paidMints - freeMints;
            }
        }

        checkValue(mintPrice * paidMints);

        _mintedFree[msg.sender] += (_amount - paidMints);
        _safeMint(msg.sender, _amount);
    }

    // PRIVATE

    function checkValue(uint256 _price) private {
        if (msg.value > _price) {
            (bool success, ) = payable(msg.sender).call{value: (msg.value - _price)}("");
            require(success, "Refund transfer failed");
        } else if (msg.value < _price) {
            revert("Not enough ETH");
        }
    }

    // OWNER

    function devMint(uint256 _amount, address _toAddress) external onlyOwner {
        require(totalSupply() + _amount <= collectionSize, "Quantity exceeds remaining mints");
        require(_mintedByDevs + _amount <= amountForDevs, "Quantity exceeds reserved amount for devs");
        require(_amount % maxBatchSize == 0, "Quantity must be a multiple of maxBatchSize");

        uint256 numChunks = _amount / maxBatchSize;

        for (uint256 i = 0; i < numChunks; i++) {
            _mintedByDevs = _mintedByDevs + maxBatchSize;
            _safeMint(_toAddress, maxBatchSize);
        }
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setContractMetadataURI(string calldata _contractMetadataURI) external onlyOwner {
        contractMetadataURI = _contractMetadataURI;
    }

    function setMaxFree(uint256 _maxFree) external onlyOwner {
        maxFree = _maxFree;
    }

    function setMaxBatchSize(uint256 _maxBatchSize) external onlyOwner {
        maxBatchSize = _maxBatchSize;
    }

    function setMaxPerAddress(uint256 _maxPerAddress) external onlyOwner {
        maxPerAddress = _maxPerAddress;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setPublicSaleActive(bool _publicSaleActive) external onlyOwner {
        publicSaleActive = _publicSaleActive;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // MODIFIERS

    modifier mintAllowed(uint256 _amount) {
        require(publicSaleActive, "Public sale is not active");
        require(tx.origin == msg.sender, "Caller is a contract");
        require(totalSupply() + _amount <= collectionSize - amountForDevs, "Quantity exceeds remaining mints");
        _;
    }

    // INTERNAL

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
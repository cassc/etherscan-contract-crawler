// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Otomotors is ERC721Enumerable, Ownable {
    uint256 public mintPrice = 80000000000000000; //0.08 ETH
    uint256 public maxPurchase = 10;
    bool public saleIsActive = false;

    // batch 1: 5001 nfts. ids: 1-5,001
    // batch 2: 5002 nfts. ids: 5,002-10,003
    // batch 3: 5003 nfts. ids: 10,004-15,007
    uint256 public currentBatch = 1;
    uint256 public BATCH_SIZE = 5000;

    string _baseTokenURI;

    event SaleActivation(bool isActive);

    constructor() ERC721("Otomotors", "OTO") {}

    function startNewBatch() external onlyOwner {
        uint256 expectedSupply = 0;

        for (uint256 i = 1; i <= currentBatch; i++) {
            expectedSupply += getBatchSize(i);
        }

        require(
            expectedSupply == totalSupply(),
            "The previous batch must be complete to start the next batch"
        );

        currentBatch += 1;
    }

    function devMint(address _to, uint256 _count) external onlyOwner {
        uint256 batchMax = getBatchMaxSupply(currentBatch);

        require(
            totalSupply() + _count <= batchMax,
            "Purchase would exceed max supply of Otomotors"
        );

        for (uint256 i = 0; i < _count; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < batchMax) {
                _safeMint(_to, mintIndex);
            }
        }
    }

    function mint(address _to, uint256 _count) external payable {
        require(saleIsActive, "Sale must be active to mint Otomotor");

        uint256 batchMax = getBatchMaxSupply(currentBatch);

        require(_count <= maxPurchase, "Can only mint 10 tokens at a time");
        require(
            totalSupply() + _count <= batchMax,
            "Purchase would exceed max supply of Otomotors"
        );
        require(
            mintPrice * _count <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < _count; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < batchMax) {
                _safeMint(_to, mintIndex);
            }
        }
    }

    function setSaleIsActive(bool _active) external onlyOwner {
        saleIsActive = _active;
        emit SaleActivation(_active);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxPurchase(uint256 _maxPurchase) external onlyOwner {
        maxPurchase = _maxPurchase;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getBatchSize(uint256 batchNumber) public view returns (uint256) {
        if (batchNumber == 0) return 0;
        return BATCH_SIZE + batchNumber;
    }

    function getBatchMaxSupply(uint256 batchNumber)
        public
        view
        returns (uint256)
    {
        uint256 maxSupply = 0;

        for (uint256 i = 1; i <= batchNumber; i++) {
            maxSupply += getBatchSize(i);
        }

        return maxSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PepePepe is ERC721AQueryable, ERC721ABurnable, Ownable {

    uint public publicSalesTimestamp = 1662498000;
    uint public normalMintPrice = 0.01 ether;
    uint public maxSupply = 4444;
    uint public maxNormalMintPerAccount = 4;
    uint public maxNormalMintPerTX = 4;

    mapping(address => uint) private _totalNormalMintPerAccount;
    string private _contractUri;
    string private _baseUri;

    constructor() ERC721A("PepePepe", "PEPE") {
    }

    function mint(uint amount) external payable {
        require(totalSupply() < maxSupply, "sold out");
        require(isPublicSalesActive(), "sales is not active");
        require(amount > 0, "invalid amount");
        require(amount <= maxNormalMintPerTX, "max tokens per tx reached");
        require(msg.value >= amount * normalMintPrice, "invalid mint price");
        require(amount + totalSupply() <= maxSupply, "amount exceeds max supply");
        require(amount + _totalNormalMintPerAccount[msg.sender] <= maxNormalMintPerAccount, "max tokens per account reached");

        _totalNormalMintPerAccount[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function isPublicSalesActive() public view returns (bool) {
        return publicSalesTimestamp <= block.timestamp;
    }

    function totalNormalMintPerAccount(address account) public view returns (uint) {
        return _totalNormalMintPerAccount[account];
    }

    function contractURI() external view returns (string memory) {
        return _contractUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractUri = contractURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseUri = baseURI_;
    }

    function setMaxSupply(uint maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setNormalMintPrice(uint normalMintPrice_) external onlyOwner {
        normalMintPrice = normalMintPrice_;
    }

    function setMaxNormalMintPerAccount(uint maxNormalMintPerAccount_) external onlyOwner {
        maxNormalMintPerAccount = maxNormalMintPerAccount_;
    }

    function setPublicSalesTimestamp(uint timestamp) external onlyOwner {
        publicSalesTimestamp = timestamp;
    }

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
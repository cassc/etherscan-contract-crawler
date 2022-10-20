// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BeaniesRugBears is ERC721AQueryable, ERC721ABurnable, Ownable {
    uint public maxSupply = 10000;
    uint public mintPrice = 0.002 ether;
    uint public maxMintPerTx = 10;
    uint public maxFreeMintPerWallet = 1;
    bool public salesStarted = false;

    mapping(address => uint) private _accountToFreeMint;
    string private _contractUri;
    string private _baseUri;

    constructor() ERC721A("Beanies Rugs", "BR") {
    }

    function mint(uint amount) external payable {
        require(totalSupply() < maxSupply, "sold out");
        require(salesStarted, "sales is not active");
        require(amount > 0, "invalid amount");
        require(amount <= maxMintPerTx, "max tokens per tx reached");
        require(msg.value >= amount * mintPrice, "invalid mint price");
        require(amount + totalSupply() <= maxSupply, "amount exceeds max supply");

        _safeMint(msg.sender, amount);
    }

    function freeMint(uint amount) external {
        require(totalSupply() < maxSupply, "sold out");
        require(salesStarted, "sales is not active");
        require(amount > 0, "invalid amount");
        require(amount <= maxMintPerTx, "max tokens per tx reached");
        require(amount + _accountToFreeMint[msg.sender] <= maxFreeMintPerWallet, "amount exceeds max free mint per wallet");

        _accountToFreeMint[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function batchMint(address[] calldata addresses, uint[] calldata amounts) external onlyOwner {
        require(addresses.length == amounts.length, "addresses and amounts doesn't match");

        for (uint i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amounts[i]);
        }
    }

    function startSales() external onlyOwner {
        salesStarted = true;
    }

    function stopSales() external onlyOwner {
        salesStarted = false;
    }

    function setMaxSupply(uint v) external onlyOwner {
        maxSupply = v;
    }

    function setMintPrice(uint v) external onlyOwner {
        mintPrice = v;
    }

    function setMaxFreeMintPerWallet(uint v) external onlyOwner {
        maxFreeMintPerWallet = v;
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

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
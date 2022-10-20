// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeadFounders is ERC721A, Ownable {
    uint public maxSupply = 5000;
    uint public mintPrice = 0.001 ether;
    uint public maxMintPerTx = 10;
    uint public maxFreeMintPerWallet = 1;
    bool public mintEnabled = false;

    mapping(address => uint) private _freeMintWallet;

    string private _contractUri;
    string private _baseUri;

    constructor() ERC721A("Dead Founders", "DeadFounders") {
    }

    function mint(uint amount) external payable {
        require(mintEnabled, "mint is not enabled");
        require(totalSupply() < maxSupply, "sold out");
        require(amount > 0, "invalid amount");
        require(amount <= maxMintPerTx, "exceeds max tokens per tx");
        require(msg.value >= amount * mintPrice, "invalid mint price");
        require(amount + totalSupply() <= maxSupply, "amount exceeds max supply");

        _safeMint(msg.sender, amount);
    }

    function freeMint(uint amount) external {
        require(mintEnabled, "mint is not enabled");
        require(totalSupply() < maxSupply, "sold out");
        require(amount > 0, "invalid amount");
        require(amount <= maxMintPerTx, "exceeds max tokens per tx");
        require(amount + _freeMintWallet[msg.sender] <= maxFreeMintPerWallet, "amount exceeds max free mint per wallet");

        _freeMintWallet[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function batchMint(address[] calldata addresses, uint[] calldata amounts) external onlyOwner {
        require(addresses.length == amounts.length, "addresses and amounts doesn't match");

        for (uint i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amounts[i]);
        }
    }

    function enableMint() external onlyOwner {
        mintEnabled = true;
    }

    function disableMint() external onlyOwner {
        mintEnabled = false;
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
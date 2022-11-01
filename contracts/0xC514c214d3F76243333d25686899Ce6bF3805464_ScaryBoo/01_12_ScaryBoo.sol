// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract ScaryBoo is ERC721AQueryable, ERC721ABurnable, EIP712, Ownable {

    uint public mintPrice = 0.002 ether;
    uint public maxMintPerAccount = 6;
    uint public totalNormalMint;
    uint public maxSupply = 2222;
    uint public publicSalesTimestamp = 1667277000;

    mapping(address => uint) private _totalNormalMintPerAccount;
    
    string private _contractUri;
    string private _baseUri;

    constructor() ERC721A("Scary Boo", "SB") EIP712("ScaryBoo", "1.0.0") {
    }

    function mint(uint amount) external payable {
        require(totalNormalMint < maxSupply, "normal mint reached max supply");
        require(isPublicSalesActive(), "sales is not active");
        require(amount > 0, "invalid amount");
        require(msg.value >= amount * mintPrice, "invalid mint price");
        require(amount + totalNormalMint <= maxSupply, "amount exceeds max supply");
        require(amount + _totalNormalMintPerAccount[msg.sender] <= maxMintPerAccount, "max tokens per account reached");

        totalNormalMint += amount;
        _totalNormalMintPerAccount[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

        function batchMint(address[] calldata addresses, uint[] calldata amounts) external onlyOwner {
        require(addresses.length == amounts.length, "addresses and amounts doesn't match");

        for (uint i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amounts[i]);
        }
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

    function setmaxSupply(uint maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setmintPrice(uint mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }

    function setmaxMintPerAccount(uint maxMintPerAccount_) external onlyOwner {
        maxMintPerAccount = maxMintPerAccount_;
    }

    function setPublicSalesTimestamp(uint timestamp) external onlyOwner {
        publicSalesTimestamp = timestamp;
    }

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }


}
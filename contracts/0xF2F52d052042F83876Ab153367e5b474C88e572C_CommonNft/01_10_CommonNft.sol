// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A/contracts/extensions/ERC721AQueryable.sol";

contract CommonNft is ERC721AQueryable, Ownable, ReentrancyGuard {
    string private _uri;
    uint256 private maxTotalSupply = 10000;

    constructor(string memory _tokenName,string memory _tokenSymbol, uint256 tokenSupply) ERC721A(_tokenName, _tokenSymbol) {
        maxTotalSupply = tokenSupply;
    }
    event PaymentReleased(address to, uint256 amount);

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return _uri;
    }

    function setURI(string memory _newUri) public virtual onlyOwner {
        _uri = _newUri;
    }

    function mint(uint256 amount) external payable {
        require(totalSupply()+amount<=maxTotalSupply, "reach max supply");
        require(_numberMinted(msg.sender)+amount<=10, "reach max mint");
        _safeMint(msg.sender, amount);
    }

    function mintTo(uint256 amount, address toAddress) external payable {
        require(totalSupply()+amount<=maxTotalSupply, "reach max supply");
        require(_numberMinted(toAddress)+amount<=10, "reach max mint");
        _safeMint(toAddress, amount);
    }

    function withdraw() public virtual nonReentrant onlyOwner {
        require(address(this).balance > 0, "SUM005");
        Address.sendValue(payable(owner()), address(this).balance);
        emit PaymentReleased(owner(), address(this).balance);
    }
}
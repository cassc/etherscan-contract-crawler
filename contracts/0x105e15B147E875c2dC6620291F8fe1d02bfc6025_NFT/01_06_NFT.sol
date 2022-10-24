// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFT is ERC721A, Ownable {

    string private __baseURI = "https://bugslifestyle.com/collections/bugs/tokens/";
    bool private __baseURILocked = false;
    string private __contractURI = "https://bugslifestyle.com/collections/bugs/contract.json";
    bool private __contractURILocked = false;

    address private __saleAddress;
    bool private __saleComplete = false;

    // solhint-disable-next-line
    constructor (string memory name, string memory symbol) ERC721A(name, symbol) {}

    // only address modifier

    modifier onlyAddress(address addr) {
        if (_msgSender() != addr) {
            revert(string(abi.encodePacked("NFT: caller is not ", Strings.toHexString(addr))));
        }
        _;
    }

    // sale methods

    function initSale(address sale) public onlyOwner() {
        require(!__saleComplete, "NFT: sale is complete");
        require(__saleAddress == address(0), "NFT: sale is already initialized");
        __saleAddress = sale;
    }

    function completeSale() public onlyOwner() {
        require(!__saleComplete, "NFT: sale is already complete");
        require(__saleAddress != address(0), "NFT: sale is not initialized");
        __saleAddress = address(0);
        __saleComplete = true;
    }

    // base URI

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory uri) public onlyOwner() {
        require(!__baseURILocked, "NFT: base uri is locked");
        __baseURI = uri;
    }

    function lockBaseURI() public onlyOwner() {
        require(!__baseURILocked, "NFT: base uri is already locked");
        __baseURILocked = true;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    // contract URI

    function contractURI() external view returns (string memory) {
        return _contractURI();
    }

    function setContractURI(string memory uri) public onlyOwner() {
        require(!__contractURILocked, "NFT: contract uri is locked");
        __contractURI = uri;
    }

    function lockContractURI() public onlyOwner() {
        require(!__contractURILocked, "NFT: contract uri is already locked");
        __contractURILocked = true;
    }

    function _contractURI() internal view returns (string memory) {
        return __contractURI;
    }

    // Token URI

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return bytes(__baseURI).length != 0 ? string(abi.encodePacked(__baseURI, _toString(tokenId), ".json")) : "";
    }

    // mint

    function mint(address to, uint256 quantity) public onlyAddress(__saleAddress) {
		_safeMint(to, quantity);
    }
}
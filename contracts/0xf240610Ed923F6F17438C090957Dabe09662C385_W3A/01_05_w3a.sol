// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract W3A is ERC721A, Ownable {

    string public baseURI;
    string public extensionURI = ".json";
    uint256 public mintUserLimit;

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), extensionURI)) : '';
    }

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    event SetURI(string indexed uri);
    event SetExtension(string indexed extension);

    constructor(string memory name_, string memory symbol_, uint256 mintUserLimit_, string memory baseURI_) ERC721A(name_, symbol_) {
        require(mintUserLimit_ != 0, "Mint user limit is zero");
        mintUserLimit = mintUserLimit_;
        baseURI = baseURI_;
    }

    function ownerMint(address to, uint256 quantity) external onlyOwner {
        _mint(to, quantity);
    }

    function batchMint(address[] memory to) external onlyOwner {
        for(uint256 i; i < to.length; i++) {
            _mint(to[i], 1);
        }
    }

    function userMint() external {
        require(_totalMinted() < mintUserLimit, "Reached minting limit");
        require(balanceOf(msg.sender) == 0, "You already have NFT");
        _mint(msg.sender, 1);
    }

    function setURI(string memory uri) external onlyOwner returns (bool) {
        baseURI = uri;
        emit SetURI(uri);
        return true;
    }

    function setExtension(string memory extension) external onlyOwner returns (bool) {
        extensionURI = extension;
        emit SetExtension(extension);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyOwner {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyOwner {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable override onlyOwner {
        super.safeTransferFrom(from, to, tokenId, _data);
    }
}
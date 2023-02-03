// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoonRabit is ERC721A("MOONRABIT SILVER", "MRBTS"), Ownable {

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    uint256 public maxSupply = 3000;

    // Modifier
    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0, "You can't mint 0 NFTs");
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Limits exceeded"
        );
        _;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    // Mint to owner
    function mint(uint256 _mintAmount)
        public
        onlyOwner
        mintCompliance(_mintAmount) {
            _safeMint(_msgSender(), _mintAmount);
    }

    // Mint to address
    function mintAndSend(address to, uint256 _mintAmount)
        public
        onlyOwner
        mintCompliance(_mintAmount) {
            _safeMint(to, _mintAmount);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory) {
            // Check if token exists
            require(_exists(_tokenId), "Token not found");
            // If base uri set - returning
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0 ?
                string(abi.encodePacked(currentBaseURI, _toString(_tokenId), uriSuffix)) :
                "";
    }

    // Overrides
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

}
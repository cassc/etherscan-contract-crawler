// SPDX-License-Identifier: MIT
// Contract for testing

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract connect is Ownable, ERC721A {
    constructor() ERC721A("Connect", "C") {}

    enum MintStatus {
        Paused,  //0
        Active   //1
    }

    uint256 private tokensOf;
    string private baseURI;
    string private constant uriEnd = ".json";
    MintStatus public mintStatus = MintStatus.Paused;

    function mint() external {
        require(mintStatus != MintStatus.Paused, "Mint must be active");
        _safeMint(msg.sender, 1);
    }

    function _setMintStatus(MintStatus _status) external onlyOwner {
        mintStatus = _status;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        string memory currentBaseURI = _baseURI();
        return string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), uriEnd));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }
}
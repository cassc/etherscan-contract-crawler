// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaMiu is ERC721Enumerable, Ownable {
    uint256 private constant START_INDEX = 1;
    uint256 private constant END_INDEX = 310;
    string private _metadataURI;

    constructor() ERC721("Meta Miu : Uptown Boy", "Meta Miu : Uptown Boy") {}

    function mintByAmount(address to, uint256 amount) public onlyOwner {
        require(
            totalSupply() + amount <= END_INDEX,
            "Exceeded the max number of mint."
        );
        uint256 startIndex = START_INDEX + totalSupply();
        for (uint256 i = startIndex; i < amount + startIndex; i++) {
            _safeMint(to, i);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _metadataURI;
    }

    function setMetadataURI(string memory metadataUri) public onlyOwner {
        _metadataURI = metadataUri;
    }
}
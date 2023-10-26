// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @custom:security-contact [email protected]
contract TheChuChuCup is ERC721, Ownable {
    string constant METADATA_URI = "ipfs://QmQNerCvXJq59RztvfrQrZdt1evG8vaZUKNRLY9sUB2AHu";
    uint256 constant MAX_SUPPLY = 200;
    uint256 private _tokenIdCounter = 0;
    constructor() ERC721("The ChuChu Cup", "The ChuChu Cup") {}
    function batchMint(address[] calldata to) public onlyOwner {
        require(to.length + _tokenIdCounter <= MAX_SUPPLY, "Exceeds max supply");
        uint256 tokenId = _tokenIdCounter;
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], tokenId);
            tokenId++;
        }
        _tokenIdCounter = tokenId;
    }
    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        return METADATA_URI;
    }
}
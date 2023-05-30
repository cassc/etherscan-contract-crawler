//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DBCCollectibles is ERC721Enumerable, Ownable {
    string public baseURI;
    bool public baseURIFinal;
    uint256 private _lastMintId = 0;

    event BaseURIChanged(string baseURI);
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(string memory _initialBaseURI) ERC721("Deathbats Club Collectibles", "DBC-C")  {
        baseURI = _initialBaseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        require(!baseURIFinal, "Base URL is unchangeable");
        baseURI = _newBaseURI;
        emit BaseURIChanged(baseURI);
    }

    function finalizeBaseURI() external onlyOwner {
        baseURIFinal = true;
    }

    function emitPermanent(uint256 tokenId) external onlyOwner {
        require(baseURIFinal, "Base URL must be finalized first");
        emit PermanentURI(tokenURI(tokenId), tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint() external onlyOwner() {
        _safeMint(msg.sender, _lastMintId + 1);
        _lastMintId += 1;
    }

    function airdrop(address [] calldata holders) external onlyOwner() {
        for (uint256 i = 0; i < holders.length; i++) {
            _safeMint(holders[i], _lastMintId + i + 1 );
        }
        _lastMintId += holders.length;
    }

    function burn(uint256 tokenId) external onlyOwner() {
        _burn(tokenId);
    }

    function redeem(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "redeem caller is neither owner nor approved");
        _burn(tokenId);
    }
}
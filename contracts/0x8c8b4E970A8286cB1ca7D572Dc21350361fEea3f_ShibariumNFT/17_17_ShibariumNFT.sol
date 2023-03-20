// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ShibariumNFT is ERC721Enumerable, ERC2981, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokensMintedCounter;
    address private _minter;

    constructor() ERC721("ShibariumDAO NFT", "SHIBNFT") Ownable() {
        _setDefaultRoyalty(msg.sender, 1000);
    }

    function safeMint(address to) external {
        require(
            msg.sender == _minter || msg.sender == owner(),
            "Only minter or owner can mint"
        );

        _tokensMintedCounter.increment();
        uint256 tokenId = _tokensMintedCounter.current();

        require(!_exists(tokenId), "Token already minted");
        require(tokenId <= 1000, "Max supply reached");
        _safeMint(to, tokenId);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.shibariumdao.io/token/";
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);
        return
            string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.shibariumdao.io/token/contract.json";
    }

    function setMinter(address minter) external onlyOwner {
        _minter = minter;
    }

    function setRoyalty(address recipient) external onlyOwner {
        _setDefaultRoyalty(recipient, 1000);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
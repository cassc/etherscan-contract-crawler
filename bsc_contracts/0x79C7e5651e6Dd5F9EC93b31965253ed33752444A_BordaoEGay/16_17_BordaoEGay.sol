// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./NftMetadata.sol";

contract BordaoEGay is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint;
    using NftMetadata for NftMetadata.Json;

    string private constant NAME_PREFIX = "Bordao e Gay #";
    string private constant DESCRIPTION_PREFIX = "Bordao e Gay #";

    Counters.Counter private _tokenIdCounter;

    uint public mintValue;
    string public nftUrl;
    string public websiteUrl;

    constructor(
        uint _mintValue,
        string memory _nftUrl,
        string memory _websiteUrl
    ) ERC721("Bordao e Gay", "BeG") {
        mintValue = _mintValue;
        nftUrl = _nftUrl;
        websiteUrl = _websiteUrl;
    }

    function destroy() external onlyOwner {
        selfdestruct(payable(owner()));
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Nothing to withdraw");
        payable(owner()).transfer(address(this).balance);
    }

    function mint() external payable {
        require(msg.value == mintValue, "Incorrect value");
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function setMintValue(uint _mintValue) external onlyOwner {
        mintValue = _mintValue;
    }

    function setNftUrl(string memory _nftUrl) external onlyOwner {
        nftUrl = _nftUrl;
    }

    function setWebsiteUrl(string memory _websiteUrl) external onlyOwner {
        websiteUrl = _websiteUrl;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory name = string.concat(NAME_PREFIX, tokenId.toString());
        string memory description = string.concat(
            DESCRIPTION_PREFIX,
            tokenId.toString()
        );
        string memory animationUrl = string.concat(
            nftUrl,
            "?id=",
            tokenId.toString()
        );

        return
            NftMetadata
                .Json(name, description, websiteUrl, animationUrl)
                .toUrl();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
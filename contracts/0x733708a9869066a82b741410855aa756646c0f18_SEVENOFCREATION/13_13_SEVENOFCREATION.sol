// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract SEVENOFCREATION is ERC721A, Ownable {
    using Strings for uint256;
    string private baseUri;

    constructor(string memory _baseUri) ERC721A("Seven Of Creation", "SO7") {
        baseUri = _baseUri;
    }

    function mintNFT(address _to) external onlyOwner {
        _safeMint(_to, 5000);
    }

    /**
     * @dev Contract URI
     */

    function contractURI() external pure returns (string memory) {
        return
            "https://ipfs.io/ipfs/QmfWZ85HbekyfKgRhxbqmQ4FXsjdA6mQK23PuRk6WH6gLK";
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }
}
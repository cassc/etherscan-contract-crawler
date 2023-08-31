// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Gabby721 is Ownable, ERC721, ERC721Enumerable {
    // using Counters for Counters.Counter;

    // Counters.Counter private _tokenIds;
    string public baseURI;

    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721(name_, symbol_) {
        baseURI = baseURI_;
    }

    function tokenIdBatch(address account_) public view returns (uint256[] memory) {
        uint256 amount = balanceOf(account_);
        uint256[] memory tokenIds = new uint256[](amount);
        for (uint256 i = 0; i < amount; ++i) {
            tokenIds[i] = tokenOfOwnerByIndex(account_, i);
        }
        return tokenIds;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    //     if (ownerOf(_tokenId) == address(0)) {
    //         return "";
    //     }
    //     return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId))) : "";
    // }

    function _beforeTokenTransfer(address from_, address to_, uint tokenId_, uint256 batchSize_) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from_, to_, tokenId_, batchSize_);
    }

    function supportsInterface(bytes4 interfaceId_) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId_);
    }

    function burn(uint256 tokenId_) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC721: caller is not token owner or approved");
        _burn(tokenId_);
    }

    function setBaseURI(string calldata newURI_) external onlyOwner {
        baseURI = newURI_;
    }
}
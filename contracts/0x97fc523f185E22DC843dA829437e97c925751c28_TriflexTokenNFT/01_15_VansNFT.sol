// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TriflexTokenNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    uint256 public constant MAX_AMOUNT = 18;
    string private uriExtension = ".json";

    constructor() ERC721("Coastal Edge Presents The Vans Custom Culture Art Show", "VNFT") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.moralis.io:2053/ipfs/Qmcu1mCsyVJQULake48xYUTpYmvSdLWcDt7NZHoTWMxJeh/metadata/";
    }

    function safeMint() public onlyOwner {
        require(totalSupply() <=  MAX_AMOUNT - 1, "All Minted");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        uint256 pointer = tokenId + 1;
        string memory uri = _concatenateIdAndURI(pointer);
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /**
    * @dev concats the token id to link to metadata url i.e. https://somehost.com/metadata/ + {tokenId} + .json
    */
    function _concatenateIdAndURI(uint256 _tokenId) private view returns (string memory){
        string memory _stringId = Strings.toString(_tokenId);

        return string(abi.encodePacked(_stringId, uriExtension));
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
    * @dev burning disabled
    */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {}

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
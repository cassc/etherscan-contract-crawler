// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract VeeFriendsMiniDrop is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable
{
    using Counters for Counters.Counter;

    string private _baseUrl;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("VeeFriends Mini Drops", "VFMD") {
        setBaseAddress("https://veefriends.com/api/metadata/vfmd/");
    }

    function setBaseAddress(string memory baseUrl)
        public
        onlyOwner
        returns (string memory)
    {
        require(
            bytes(baseUrl).length > 0,
            "Cannot set base address with an invalid 'baseUrl'."
        );

        _baseUrl = baseUrl;
        emit BaseUrlChanged(_baseUrl, baseUrl);
        return _baseUrl;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUrl;
    }

    function mint() public onlyOwner {
        _safeMint(_msgSender(), _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function mintBatch(uint256 length) public onlyOwner {
        require(
            length > 0,
            "Cannot batch mint 'zero' or 'less than zero' tokens."
        );

        for (uint256 idx = 0; idx < length; idx++) {
            mint();
        }
    }

    function giftToken(address to, uint256 tokenId) public onlyOwner {
        _safeTransfer(_msgSender(), to, tokenId, "");
        emit PermanentURI(_baseUrl, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

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

    /**
     * @dev Emitted when `baseUrl` changed `oldUrl` to `newUrl`.
     */
    event BaseUrlChanged(string indexed oldUrl, string indexed newUrl);

    /**
     * @dev Emitted when `tokenMetaData` is ready to be frozen
     */
    event PermanentURI(string _value, uint256 indexed _id);
}
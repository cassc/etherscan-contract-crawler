// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract Base721 is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    uint256 public maxSupply;
    bool public frozen;
    string private baseURI;
    Counters.Counter internal _tokenIdTracker;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) {
        require(_maxSupply != 0, "Max Supply cannot be 0");
        baseURI = _uri;
        maxSupply = _maxSupply;
    }

    function _mintToTarget(address target, uint256 quantity) internal virtual {
        require(
            quantity + _tokenIdTracker.current() <= maxSupply,
            "Maximum supply reached"
        );
        for (uint256 i; i < quantity; i++) {
            _tokenIdTracker.increment(); // Start at ID: 1 instead of 0
            _mint(target, _tokenIdTracker.current());
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory base = _baseURI();
        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, tokenId.toString(), ".json"))
                : "";
    }

    // Admin

    function setBaseURI(string memory _uri) external onlyOwner {
        require(!frozen, "Metadata is frozen");
        baseURI = _uri;
    }

    function freezeURI() external onlyOwner {
        frozen = true;
    }
}
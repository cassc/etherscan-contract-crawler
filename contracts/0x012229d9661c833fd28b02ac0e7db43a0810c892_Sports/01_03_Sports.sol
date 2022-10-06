// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";

contract Sports is ERC721A {
    address owner;
    mapping(uint256 => string) _metadata;

    constructor() ERC721A("10K Sports", "10K Sports") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner caller!");
        _;
    }

    function mint(
        address to,
        uint256 amount,
        string calldata tokenUri
    ) external onlyOwner {
        _metadata[_nextTokenId()] = tokenUri;
        _mint(to, amount);
    }

    function setMetadata(uint256 _tokenId, string calldata tokenUri)
        external
        onlyOwner
    {
        _metadata[_tokenId] = tokenUri;
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
        return _metadata[tokenId];
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
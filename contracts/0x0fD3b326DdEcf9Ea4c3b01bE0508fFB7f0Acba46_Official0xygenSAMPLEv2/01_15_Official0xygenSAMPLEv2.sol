// SPDX-License-Identifier: MIT
// Website: https:www.0xygen.io
// Company: Crowcial, Inc.
// Project: 0xygen
// coded by n0x.eth

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Official0xygenSAMPLEv2 is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Official0xygenSAMPLEv2", "0XSAMP2") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://0xygen.infura-ipfs.io/ipfs/QmdJuEVBv5QXTNpP4cRqTUZAHKNTwQCyhBtywQSAhNNXyy/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

//NOTE: Below function allows ANYONE to mint. If you want it restricted, add onlyOwner after public
    function safeMint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < 500,"Error, no NFTs remain");//Set token cap here
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
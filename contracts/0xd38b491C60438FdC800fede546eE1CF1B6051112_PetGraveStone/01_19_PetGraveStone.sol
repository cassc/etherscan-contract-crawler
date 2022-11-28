// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "contracts/GraveStoneAbstract.sol";

contract PetGraveStone is GraveStoneAbstract {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("PetGraveStone", "PetGraveStone") {

    }

    function _mint(address to) internal override{
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        string memory tokenUri = "PetGraveStone.json";
        _setTokenURI(tokenId, tokenUri);
    }

    function _mintWithLock(address to, uint256 expTime) internal override{
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        string memory tokenUri = "PetGraveStone.json";
        _setTokenURI(tokenId, tokenUri);
        lockStateMap[tokenId] = LockState(tokenId, true, expTime);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
hhhhhhh
h:::::h
h:::::h
h:::::h
 h::::h hhhhh       zzzzzzzzzzzzzzzzznnnn  nnnnnnnn
 h::::hh:::::hhh    z:::::::::::::::zn:::nn::::::::nn
 h::::::::::::::hh  z::::::::::::::z n::::::::::::::nn
 h:::::::hhh::::::h zzzzzzzz::::::z  nn:::::::::::::::n
 h::::::h   h::::::h      z::::::z     n:::::nnnn:::::n
 h:::::h     h:::::h     z::::::z      n::::n    n::::n
 h:::::h     h:::::h    z::::::z       n::::n    n::::n
 h:::::h     h:::::h   z::::::z        n::::n    n::::n
 h:::::h     h:::::h  z::::::zzzzzzzz  n::::n    n::::n
 h:::::h     h:::::h z::::::::::::::z  n::::n    n::::n
 h:::::h     h:::::hz:::::::::::::::z  n::::n    n::::n
 hhhhhhh     hhhhhhhzzzzzzzzzzzzzzzzz  nnnnnn    nnnnnn
*/

contract HZN_001_SBT is
    ERC721A,
    Ownable
{
    using Strings for uint256;

    mapping(uint256 => bool) public isAllowedToTransfer;

    // ======== METADATA ========
    string public _baseTokenURI;
    string public baseExtension = ".json";

    // ======== CONSTRUCTOR ========
    constructor() ERC721A("HZN-001-SBT", "HZN-001-SBT") {}

    // ======== MINTING ========

    function airdrop(address[] calldata _addresses, uint256[] calldata _quantities) external onlyOwner {
      require(_addresses.length == _quantities.length, "Not the same length");
      for (uint256 i; i < _addresses.length; i++) {
        _safeMint(_addresses[i], _quantities[i]);
      }
    }

    // ======== SETTERS ========

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setIsAllowedToTransfer(uint256[] calldata _tokenIds, bool[] calldata _allowed) external onlyOwner {
        for (uint256 i; i < _tokenIds.length; i++) {
            isAllowedToTransfer[_tokenIds[i]] = _allowed[i];
        }
    }

    // ========= GETTERS ===========
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721aMetadata: URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    tokenId.toString(),
                    baseExtension
                )
            );
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual payable override(ERC721A) {
        require(isAllowedToTransfer[tokenId], "Not allowed to transfer");
        super.transferFrom(from, to, tokenId);
    }
}
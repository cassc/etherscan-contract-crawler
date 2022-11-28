//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract vinylkeyContractV2 is ERC2981, ERC721, Ownable {
    using Strings for uint256;

    string private _base = "";
    uint16 internal constant _DEFAULT_ROYALTY_BASIS = 1000; // 10 %

    constructor(string memory tokenName, string memory symbol, string memory baseURI,  address payable royaltyReceiver) 
        ERC721(tokenName, symbol) { 
            _base = baseURI;
            _setDefaultRoyalty(royaltyReceiver, _DEFAULT_ROYALTY_BASIS);
    }

    // hex must be all upper case because NFC tags generate UID in uppercase 
    bytes16 private constant _HEX_SYMBOLS = "0123456789ABCDEF";

    function toHexStringMinusThe0x(uint a) private pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i=0; i < count; ++i) {
            b = a % 16;
            res[count - i - 1] = _HEX_SYMBOLS[b & 0xf];
            a /= 16;
        }
        return string(res);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(_base).length > 0 ? string(abi.encodePacked(_base, toHexStringMinusThe0x(tokenId), ".json")) : "";
    }

    /**
    @notice Sets the contract-wide royalty info.
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId) || 
            super.supportsInterface(interfaceId);
    }

}
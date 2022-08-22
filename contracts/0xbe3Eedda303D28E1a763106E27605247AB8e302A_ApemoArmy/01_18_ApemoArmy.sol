//SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../interfaces/IApemoArmy.sol";
import "../utils/Operatorable.sol";

/**
 * Apemo Army Avatar NFT Contract V1
 * Provided by Satoshiverse LLC
 */
contract ApemoArmy is ERC721Enumerable, Operatorable {
    constructor() ERC721("Apemo Army", "APEMOARMY") {}

    string public baseURI = "";

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOperator {
        baseURI = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory){
        return baseURI;
    }

    function operatorMint(address to, uint256 tokenId) external onlyOperator {
        _safeMint(to, tokenId);
    }
}
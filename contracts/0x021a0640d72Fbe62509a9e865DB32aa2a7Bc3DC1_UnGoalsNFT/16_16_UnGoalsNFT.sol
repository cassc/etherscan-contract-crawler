// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@opengem/contracts/token/ERC721/extensions/ERC721PermanentURIs.sol";
import "@opengem/contracts/token/ERC721/extensions/ERC721PermanentProof.sol";
import "@logion/solidity/contracts/Logion.sol";

contract UnGoalsNFT is
    ERC721,
    ERC721Enumerable,
    ERC721PermanentURIs,
    ERC721PermanentProof,
    Logion,
    Ownable
{
    using Strings for uint256;

    uint256 public constant TOTAL_SUPPLY = 174;

    constructor(
        string memory _globalProof
    )
        ERC721("UN Sustainable Development Goals", "SDG")
        Logion(
            "",
            "36443432369020583004147250731155417285",
            "certificate.logion.network"
        )
    {
        _addPermanentBaseURI(
            "ipfs://bafybeigus4rzqmz7dzvzr7xvkqzfxd2qpqrnrz3qitevb66iledfbxbhn4/",
            ".json"
        );
        _addPermanentBaseURI(
            "ar://zKRqeJSKQrlhL6VG2UFv7cFhuMhGrUwSpg0I_1anTmk/",
            ".json"
        );

        _setPermanentGlobalProof(_globalProof);
    }

    function mintSupply() external onlyOwner {
        require(totalSupply() < TOTAL_SUPPLY, "UnGoalsNFT: supply exhausted");

        for (uint256 tokenId; tokenId < TOTAL_SUPPLY; tokenId++) {
            _mint(msg.sender, tokenId);
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function contractURI() public pure returns (string memory) {
        return "https://auction.retreeb.io/contract-metadata.json";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721PermanentURIs, ERC721PermanentProof, ERC721) {
        super._burn(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return
            "ipfs://bafybeigus4rzqmz7dzvzr7xvkqzfxd2qpqrnrz3qitevb66iledfbxbhn4/";
    }
}
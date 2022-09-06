// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@imtbl/imx-contracts/contracts/Mintable.sol";

/**
 * @title Mint InCreation collection
 * @notice Contract in creation
 */

contract YumonGenesis is ERC721, Mintable {
    using Strings for uint256;

    // IMX Blueprints mapping
    mapping(uint256 => bytes) public Blueprints;
    // Collection Base URI
    string public baseURI;

    constructor(address _owner, address _imx)
        ERC721("Yumon", "YUMG")
        Mintable(_owner, _imx)
    {}

    /*********************************
     *
     *
     *         IMX FUNCTION
     *
     *
     ********************************/

    function _mintFor(
        address user,
        uint256 id,
        bytes memory blueprints
    ) internal override {
        Blueprints[id] = blueprints;
        _safeMint(user, id);
    }

    /*********************************
     *
     *
     *        ADMIN OPERATIONS
     *
     *
     ********************************/

    /**
     * @dev Set the base URI
     *
     * The style MUST BE as follow : "ipfs://QmdsaXXXXXXXXXXXXXXXXXXXX7epJF/"
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @dev ERC721 standardd
     * @return baseURI value
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Return the URI of the NFT
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory URI = _baseURI();
        return
            bytes(URI).length > 0
                ? string(abi.encodePacked(URI, tokenId.toString()))
                : "";
    }
}
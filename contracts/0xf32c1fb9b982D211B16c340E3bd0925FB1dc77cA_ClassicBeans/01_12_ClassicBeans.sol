// SPDX-License-Identifier: MIT
// BEANS by Dumb Ways to Die Terms and Conditions [ https://www.beansnfts.io/terms ]

pragma solidity ^0.8.0;

// reference: https://github.com/chiru-labs/ERC721A
import "./ERC721A.sol";

// Openzepplin Contracts
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ClassicBeans is ERC721A, Ownable {
    using Strings for uint256;

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                  TOKEN SETTINGS
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // The base URI to look for when searching for the metadata for each NFT
    string public baseURI;

    // The hidden URI for when the NFTs are hidden
    string public hiddenURI = "ipfs://QmdPLf582WtRcQean84RjWirDmEh5jSBL3YYxxB1m7B7DP";

    // Returns the hidden URI instead of the unrevealed URI if set to false
    bool public revealed = false;

    constructor() ERC721A("CLASSIC BEANS - Dumb Ways to Die", "DWTD_CB") {
        mintAll();
    }

    function mintAll() internal {
        // Mint all the characters in one transaction and send to the sender of this contract ( the owner ) 
        _safeMint(msg.sender, 20);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                        REVEAL
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function setRevealed(bool _revealedState) public onlyOwner {
        revealed = _revealedState;
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                         URI
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Override the base Token URI function and add our URI to the address of each NFT
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (revealed == false) return hiddenURI;

        // Ensure that the token ID meta data exists
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        // Combine the base URI and the token ID to get the URI of the metadata for this token
        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                    METADATA
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function setBaseURI(string memory newURI) public onlyOwner { baseURI = newURI; }
    function setHiddenURI(string memory newURI) public onlyOwner { hiddenURI = newURI; }
}
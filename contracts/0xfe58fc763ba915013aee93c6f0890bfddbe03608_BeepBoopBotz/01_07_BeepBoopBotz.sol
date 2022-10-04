// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "@oz/access/Ownable.sol";
import {ERC721A, IERC721A, ERC721AQueryable} from "@erc721a/extensions/ERC721AQueryable.sol";

contract BeepBoopBotz is ERC721AQueryable, Ownable {
    /// @notice Maximum supply of the mint passes
    uint256 public constant MAX_SUPPLY = 10000;

    /// @notice Base URI for the NFT collection
    string private baseURI;

    constructor(string memory baseURI_) ERC721A("Beep Boop Botz", "BBB") {
        baseURI = baseURI_;
    }

    /**
     * @notice Airdrop NFT to holders. Must airdrop at max the supply limit.
     * @param accounts Number of accounts to airdrop
     * @param amounts Amounts to airdrop
     */
    function airdrop(address[] calldata accounts, uint16[] calldata amounts)
        public
        onlyOwner
    {
        require(accounts.length == amounts.length, "Param Length Mismatch");
        for (uint256 i; i < accounts.length; ++i) {
            _mint(accounts[i], amounts[i]);
        }
        require(_totalMinted() <= MAX_SUPPLY, "Incomplete Airdrop");
    }

    /**
     * @notice Admin mint specific address
     * @param recipient Receiver of the pass
     * @param quantity Quantity to mint
     */
    function adminMint(address recipient, uint256 quantity) public onlyOwner {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Hit Max Supply");
        _mint(recipient, quantity);
    }

    /**
     * @notice Set the base URI of the token
     * @param baseURI_ The base URI of the collection
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @notice Return the base uri of the ERC721
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
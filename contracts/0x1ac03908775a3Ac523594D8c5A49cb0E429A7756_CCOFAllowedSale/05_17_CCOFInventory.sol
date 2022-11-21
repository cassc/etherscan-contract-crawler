// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./InventoryAccessControl.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract CCOFInventory is ERC721A, InventoryAccessControl, ERC721AQueryable {
    //Uniform Resource Identifier (URI) for `tokenId` token.
    string public baseURI;

    /**
     * Constructor.
     * @param _name the name of the ERC721A token.
     * @param _symbol the symbol to represnt the token.
     * @param _baseURI the URI of the token.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC721A(_name, _symbol) InventoryAccessControl() {
        baseURI = _baseURI;
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `_beneficiary`.
     *
     * Requirements:
     *  -minter address must have minter role
     *  -pause status must be false
     * Emits a {Transfer} event for each mint.
     */
    function mint(address _beneficiary, uint256 quantity) public onlyMinter {
        _safeMint(_beneficiary, quantity);
    }

    /**
     * @dev Public function with onlyOwner role to change the baseURI value
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev override the function by adding `whenNotPaused` modifier
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {}

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - `burnPaused` status must be `false`
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 tokenId) public whenBurnNotPaused {
        _burn(tokenId, true);
    }

    /**
     * @dev Check Interface of ERC721A
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
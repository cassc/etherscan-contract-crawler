// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../token/721A/ERC721A.sol";
import "../royalties/ERC2981ContractWideRoyalties.sol";
import "../utils/ERC721AMetadata.sol";
import "../utils/Administration.sol";

error MaxSupplyUnchangeable();
error MaxSupplyReached();
error InvalidBatchRequest();

contract WizardsERC721A is
    ERC721A,
    ERC721AMetadata,
    ERC2981ContractWideRoyalties,
    Administration
{
    uint256 private _maxSupply;

    mapping(bytes32 => bool) public nonces;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI,
        string memory contractURI,
        address royaltyRecipient,
        uint24 royaltyValue,
        address owner
    ) ERC721A(name_, symbol_) Administration(owner) {
        _setBaseURI(baseTokenURI);
        _setContractURI(contractURI);
        _setRoyalties(royaltyRecipient, royaltyValue);
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function setMaxSupply(uint256 maxSupply_) external isAdmin {
        if (_maxSupply > 0) revert MaxSupplyUnchangeable();
        _maxSupply = maxSupply_;
    }

    function setRoyalties(address recipient, uint24 value) external isAdmin {
        _setRoyalties(recipient, value);
    }

    function setContractURI(string memory contractURI) external isAdmin {
        _setContractURI(contractURI);
    }

    function setBaseURI(string memory uri) external isAdmin {
        _setBaseURI(uri);
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI_)
        external
        isAdmin
    {
        _setTokenURI(tokenId, tokenURI_);
    }

    function mintById(address to, uint256 id) external isMinter whenNotPaused {
        _mintById(to, id, "", true);
    }

    function mint(address to, uint256 quantity)
        external
        isMinter
        whenNotPaused
    {
        _mint(to, quantity, "", true);
    }

    function mintBatch(address[] memory to, uint256[] memory quantity)
        external
        isMinter
        whenNotPaused
    {
        if (to.length != quantity.length) revert InvalidBatchRequest();

        unchecked {
            for (uint256 i = 0; i < to.length; i++) {
                _mint(to[i], quantity[i], "", true);
            }
        }
    }

    function burn(uint256 tokenId) public virtual {
        _burn(tokenId, true);
    }

    // Overides

    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal override {
        unchecked {
            if (_maxSupply > 0 && totalMinted() >= _maxSupply) {
                revert MaxSupplyReached();
            }
        }

        super._mint(to, quantity, _data, safe);
    }

    function _mintById(
        address to,
        uint256 id,
        bytes memory _data,
        bool safe
    ) internal override {
        unchecked {
            if (_maxSupply > 0 && totalMinted() >= _maxSupply) {
                revert MaxSupplyReached();
            }
        }

        super._mintById(to, id, _data, safe);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, ERC721AMetadata)
        returns (string memory)
    {
        return ERC721AMetadata.tokenURI(tokenId);
    }

    function _baseURI()
        internal
        view
        virtual
        override(ERC721A, ERC721AMetadata)
        returns (string memory)
    {
        return ERC721AMetadata._baseURI();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981Base, Administration)
        returns (bool)
    {
        return
            interfaceId == type(ERC721AMetadata).interfaceId ||
            interfaceId == type(ERC2981Base).interfaceId ||
            interfaceId == type(ERC2981ContractWideRoyalties).interfaceId ||
            interfaceId == type(Administration).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
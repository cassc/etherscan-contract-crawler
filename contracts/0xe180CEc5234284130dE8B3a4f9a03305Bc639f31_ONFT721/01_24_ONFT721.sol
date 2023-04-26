// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IONFT721.sol";
import "./ONFT721Core.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../../OperatorFiltererNonUpgradeable.sol";

// NOTE: this ONFT contract has no public minting logic.
// must implement your own minting logic in child classes
contract ONFT721 is ONFT721Core, ERC721, IONFT721, IERC721Receiver, OperatorFilterer {
    event Fallback(bytes data);
    event CheckSender(address sender);

    string public contractURI;

    // Mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Role for toggling OperatorFiltering on/off
    address operatorFilterAdmin;

    bool isMarketplaceFilteringTurnedOn;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address _lzEndpoint
    )
        ERC721(_name, _symbol)
        ONFT721Core(_lzEndpoint)
        OperatorFilterer(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6, false)
    {
        operatorFilterAdmin = msg.sender;
        contractURI = _contractURI;
        isMarketplaceFilteringTurnedOn = true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ONFT721Core, ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IONFT721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint256 _tokenId
    ) internal virtual override returns (string memory) {
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "ONFT721: send caller is not owner nor approved"
        );
        require(
            ERC721.ownerOf(_tokenId) == _from,
            "ONFT721: send from incorrect owner"
        );
        _transfer(_from, address(this), _tokenId);
        return "";
    }

    function _creditTo(
        uint16,
        address _toAddress,
        uint256 _tokenId,
        string memory _tokenURI
    ) internal virtual override {
        require(
            !_exists(_tokenId) ||
                (_exists(_tokenId) && ERC721.ownerOf(_tokenId) == address(this))
        );
        if (!_exists(_tokenId)) {
            _safeMint(_toAddress, _tokenId);
            // set the token URI
            _setTokenURI(_tokenId, _tokenURI);
        } else {
            _transfer(address(this), _toAddress, _tokenId);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from, isMarketplaceFilteringTurnedOn)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from, isMarketplaceFilteringTurnedOn)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from, isMarketplaceFilteringTurnedOn)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function updateOptionalMarketplaceFiltering(
        bool _isMarketplaceFilteringTurnedOn
    ) public {
        require(
            msg.sender == operatorFilterAdmin,
            "Must have operator filter admin role to update"
        );
        isMarketplaceFilteringTurnedOn = _isMarketplaceFilteringTurnedOn;
    }

    function onERC721Received(address _operator, address, uint, bytes memory) public virtual override returns (bytes4) {
        // only allow `this` to tranfser token from others
        if (_operator != address(this)) return bytes4(0);
        return IERC721Receiver.onERC721Received.selector;
    }
}
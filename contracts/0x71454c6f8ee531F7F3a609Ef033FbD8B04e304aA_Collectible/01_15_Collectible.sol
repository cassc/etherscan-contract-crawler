// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "./AccessControlPermissible.sol";

contract Collectible is ERC721A, ERC2981, AccessControlPermissible {
    string private _baseURIData;

    event BaseURISet(string uri);

    // Constructor
    constructor(string memory name_, string memory symbol_)
        ERC721A(name_, symbol_)
    {
        _setDefaultRoyalty(msg.sender, 200); // 2%
    }

    function mint(address _to, uint256 _quantity)
        external
        onlyRole(MINTER_ROLE)
    {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(_to, _quantity);
    }

    function burn(uint256 _tokenId) external onlyRole(BURNER_ROLE) {
        _burn(_tokenId);
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        external
        onlyRole(ADMIN_ROLE)
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function unsetDefaultRoyalty() external onlyRole(ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNumerator
    ) external onlyRole(ADMIN_ROLE) {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    function unsetTokenRoyalty(uint256 _tokenId) external onlyRole(ADMIN_ROLE) {
        _resetTokenRoyalty(_tokenId);
    }

    function setBaseURI(string calldata _uri) external onlyRole(ADMIN_ROLE) {
        _baseURIData = _uri;
        emit BaseURISet(_uri);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, ERC2981, ERC721A)
        returns (bool)
    {
        return
            AccessControlEnumerable.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIData;
    }
}
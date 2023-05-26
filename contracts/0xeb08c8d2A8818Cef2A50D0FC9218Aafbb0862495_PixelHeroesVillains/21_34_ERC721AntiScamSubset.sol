// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

//import "./IERC721AntiScam.sol";
import "contract-allow-list/contracts/ERC721AntiScam/lockable/ERC721Lockable.sol";
import "./ERC721RestrictApproveGlobalOnly.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ERC721PsiBurnable with Anti Scam functions(Subset version)
/// @dev See readme.

abstract contract ERC721AntiScamSubset is
    ERC721Lockable,
    ERC721RestrictApproveGlobalOnly,
    Ownable
{

    /*///////////////////////////////////////////////////////////////
                              OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(ERC721Lockable, ERC721RestrictApproveGlobalOnly)
        returns (bool)
    {
        if (isLocked(owner) || !_isAllowed(owner, operator)) {
            return false;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC721Lockable, ERC721RestrictApproveGlobalOnly)
    {
        require(
            isLocked(msg.sender) == false || approved == false,
            "Can not approve locked token"
        );
        require(
            _isAllowed(operator) || approved == false,
            "RestrictApprove: Can not approve locked token"
        );
        super.setApprovalForAll(operator, approved);
    }

    function _beforeApprove(address to, uint256 tokenId)
        internal
        virtual
        override(ERC721Lockable, ERC721RestrictApproveGlobalOnly)
    {
        ERC721Lockable._beforeApprove(to, tokenId);
        ERC721RestrictApproveGlobalOnly._beforeApprove(to, tokenId);
    }

    function approve(address to, uint256 tokenId)
        public
        virtual
        override(ERC721Lockable, ERC721RestrictApproveGlobalOnly)
    {
        _beforeApprove(to, tokenId);
        ERC721Psi.approve(to, tokenId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721Psi, ERC721Lockable) {
        ERC721Lockable._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721Lockable, ERC721RestrictApproveGlobalOnly) {
        ERC721Lockable._afterTokenTransfers(from, to, startTokenId, quantity);
        ERC721RestrictApproveGlobalOnly._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Lockable, ERC721RestrictApproveGlobalOnly)
        returns (bool)
    {
        return
            ERC721Psi.supportsInterface(interfaceId) ||
            ERC721Lockable.supportsInterface(interfaceId) ||
            ERC721RestrictApproveGlobalOnly.supportsInterface(interfaceId) /*||
            interfaceId == type(IERC721AntiScam).interfaceId*/;
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../../interfaces/IFirstOwner.sol";
import "./BlockMelonERC721LockedContent.sol";

abstract contract BlockMelonERC721FirstOwners is
    IFirstOwner,
    BlockMelonERC721LockedContent
{
    /// @notice Emitted when `tokenId` is has its first owner
    event FirstOwner(address indexed owner, uint256 tokenId);

    /// @dev bytes4(keccak256('firstOwner(tokenId)')) == 0xf46c892e
    bytes4 private constant _INTERFACE_ID_FIRST_OWNER = 0xf46c892e;
    /// @dev Mapping from each NFT ID to its first owner
    mapping(uint256 => address payable) private _firstOwners;

    function __BlockMelonERC721FirstOwners_init_unchained()
        internal
        onlyInitializing
    {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            _INTERFACE_ID_FIRST_OWNER == interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IFirstOwner-firstOwner}
     */
    function firstOwner(uint256 tokenId)
        public
        view
        override
        returns (address payable)
    {
        return _firstOwners[tokenId];
    }

    function _setFirstOwner(uint256 tokenId, address account) internal virtual {
        if (
            address(0) == _firstOwners[tokenId] &&
            tokenCreator(tokenId) != account
        ) {
            _firstOwners[tokenId] = payable(account);
            emit FirstOwner(account, tokenId);
        }
    }

    uint256[50] private __gap;
}
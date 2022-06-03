// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../../interfaces/IERC721StakingLocker.sol";
import "../../interfaces/IERC721x.sol";
import "./LockerAdmin.sol";
import "../Errors.sol";

abstract contract ERC721LockerUpgradeable is LockerAdmin, IERC721StakingLocker {
    mapping(uint256 => uint256) private _locked;
    IERC721Upgradeable private _parent;
    IERC721x private _parentx;

    function __init() internal {
        _parent = IERC721Upgradeable(address(this));
        _parentx = IERC721x(address(this));
    }

    function lock(address account, uint256[] calldata ids) external {
        _onlyLockerAdmin();
        for (uint256 t = 0; t < ids.length; t++) {
            uint256 tokenId = ids[t];

            if (isLocked(tokenId)) revert TokenLocked();

            if (!_parentx.exists(tokenId)) revert UnknownToken();

            if (_parent.ownerOf(tokenId) != account) revert TokenNotOwn();

            _lock(tokenId);
        }
    }

    function unlock(address account, uint256[] calldata ids) external {
        _onlyLockerAdmin();
        for (uint256 t = 0; t < ids.length; t++) {
            uint256 tokenId = ids[t];

            if (!isLocked(tokenId)) revert TokenNotLocked();

            if (!_parentx.exists(tokenId)) revert UnknownToken();

            if (_parent.ownerOf(tokenId) != account) revert TokenNotOwn();

            _unlock(tokenId);
        }
    }

    function isLocked(uint256 tokenId) public view returns (bool) {
        uint256 lockedWordIndex = tokenId / 256;
        uint256 lockedBitIndex = tokenId % 256;
        uint256 lockedWord = _locked[lockedWordIndex];
        uint256 mask = (1 << lockedBitIndex);
        return lockedWord & mask == mask;
    }

    function _lock(uint256 tokenId) private {
        uint256 lockedWordIndex = tokenId / 256;
        uint256 lockedBitIndex = tokenId % 256;
        _locked[lockedWordIndex] =
            _locked[lockedWordIndex] |
            (1 << lockedBitIndex);
    }
    
    function _unlock(uint256 tokenId) private {
        uint256 lockedWordIndex = tokenId / 256;
        uint256 lockedBitIndex = tokenId % 256;
        _locked[lockedWordIndex] =
            _locked[lockedWordIndex] &
            ~(1 << lockedBitIndex);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
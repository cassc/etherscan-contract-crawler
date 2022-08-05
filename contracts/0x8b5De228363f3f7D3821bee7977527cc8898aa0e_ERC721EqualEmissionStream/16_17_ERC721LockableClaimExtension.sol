// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../base/ERC721MultiTokenStream.sol";

interface IERC721LockableClaimExtension {
    function hasERC721LockableClaimExtension() external view returns (bool);

    function setClaimLockedUntil(uint64 newValue) external;
}

abstract contract ERC721LockableClaimExtension is
    IERC721LockableClaimExtension,
    Initializable,
    Ownable,
    ERC165Storage,
    ERC721MultiTokenStream
{
    // Claiming is only possible after this time (unix timestamp)
    uint64 public claimLockedUntil;

    /* INTERNAL */

    function __ERC721LockableClaimExtension_init(uint64 _claimLockedUntil)
        internal
        onlyInitializing
    {
        __ERC721LockableClaimExtension_init_unchained(_claimLockedUntil);
    }

    function __ERC721LockableClaimExtension_init_unchained(
        uint64 _claimLockedUntil
    ) internal onlyInitializing {
        claimLockedUntil = _claimLockedUntil;

        _registerInterface(type(IERC721LockableClaimExtension).interfaceId);
    }

    /* ADMIN */

    function setClaimLockedUntil(uint64 newValue) public onlyOwner {
        require(lockedUntilTimestamp < block.timestamp, "CONFIG_LOCKED");
        claimLockedUntil = newValue;
    }

    /* PUBLIC */

    function hasERC721LockableClaimExtension() external pure returns (bool) {
        return true;
    }

    /* INTERNAL */

    function _beforeClaim(
        uint256 ticketTokenId_,
        address claimToken_,
        address beneficiary_
    ) internal virtual override {
        ticketTokenId_;
        claimToken_;
        beneficiary_;

        require(claimLockedUntil < block.timestamp, "CLAIM_LOCKED");
    }
}
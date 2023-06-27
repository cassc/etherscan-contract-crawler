// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "contract-allow-list/contracts/ERC721AntiScam/lockable/IERC721Lockable.sol";

interface ILocker {
    function setWalletLock(
        address contractAddress,
        address to,
        IERC721Lockable.LockStatus lockStatus
    ) external;

    function setTokenLock(
        address contractAddress,
        uint256[] calldata tokenIds,
        IERC721Lockable.LockStatus newLockStatus
    ) external;

    function isLocked(address contractAddress, uint256 tokenId)
        external
        view
        returns (bool);

    function setUnlockLeadTime(uint256 value) external;
}
//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IVotingEscrowLock is IERC721 {
    event LockCreated(uint256 veLockId);
    event LockUpdate(uint256 veLockId, uint256 amount, uint256 end);
    event Withdraw(uint256 veLockId, uint256 amount);
    event VoteDelegated(uint256 veLockId, address to);

    function locks(uint256 veLockId)
        external
        view
        returns (
            uint256 amount,
            uint256 start,
            uint256 end
        );

    function createLock(uint256 amount, uint256 epochs) external;

    function createLockUntil(uint256 amount, uint256 lockEnd) external;

    function increaseAmount(uint256 veLockId, uint256 amount) external;

    function extendLock(uint256 veLockId, uint256 epochs) external;

    function extendLockUntil(uint256 veLockId, uint256 end) external;

    function withdraw(uint256 veLockId) external;

    function delegate(uint256 veLockId, address to) external;

    function totalLockedSupply() external view returns (uint256);

    function MAXTIME() external view returns (uint256);

    function baseToken() external view returns (address);

    function veToken() external view returns (address);

    function delegateeOf(uint256 veLockId) external view returns (address);

    function delegatedRights(address delegatee) external view returns (uint256);

    function delegatedRightByIndex(address delegatee, uint256 idx)
        external
        view
        returns (uint256 veLockId);
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {LockStatus} from "./storage/LockableStorage.sol";

interface IWalletLockable {

    /**
     * @dev Emit event when wallet lock status is changed.
     */
    event WalletLockChanged(address indexed holder, address indexed operator, LockStatus lockStatus);

    /**
     * @dev 
     */
    function lockEnabled() external view returns (bool);

    function defaultLock() external view returns (LockStatus);

    function contractLock() external view returns (LockStatus);

    function walletLock(address holder) external view returns (LockStatus);

    /**
     * @dev Set lock status of self wallet.
     */
    function setWalletLock(LockStatus lockStatus) external;

    /**
     * @dev Set default lock status.
     */
    function setDefaultLock(LockStatus lockStatus) external;

    /**
     * @dev Set contract lock status.
     */
    function setContractLock(LockStatus lockStatus) external;

    /**
     * @dev Returns which specified token is locked.
     */
    function isTokenLocked(uint256 tokenId) external view returns (bool);
    
    /**
     * @dev Return which specified holder is locked.
     */
    function isWalletLocked(address holder) external view returns (bool);
    
}
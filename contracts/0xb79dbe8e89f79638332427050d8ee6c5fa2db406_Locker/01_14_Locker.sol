// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./ILocker.sol";
import "./TimestampStorage.sol";
import {IERC721Lockable} from "contract-allow-list/contracts/ERC721AntiScam/lockable/IERC721Lockable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract Locker is ILocker, Ownable, AccessControl {
    using TimestampStorage for TimestampStorage.Storage;
    
    bytes32 public constant ADMIN = keccak256("ADMIN");
    // ==================================================================
    // Variables
    // ==================================================================
    mapping(address => mapping(address => IERC721Lockable.LockStatus))
        public walletLock;
    mapping(address => mapping(uint256 => IERC721Lockable.LockStatus))
        public tokenLock;

    // == For time lock ==
    // contractAddress => tokenId -> unlock time
    mapping(address => TimestampStorage.Storage) private _unlockTokenTimestamp;
    // contractAddress => wallet -> unlock time
    mapping(address => mapping(address => uint256))
        public unlockWalletTimestamp;
    uint256 public unlockLeadTime = 3 hours;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
    }

    // ==================================================================
    // override ILocker
    // ==================================================================
    function setWalletLock(
        address contractAddress,
        address to,
        IERC721Lockable.LockStatus lockStatus
    ) external {
        require(msg.sender == to, "only yourself.");

        if (
            walletLock[contractAddress][to] ==
            IERC721Lockable.LockStatus.Lock &&
            lockStatus != IERC721Lockable.LockStatus.Lock
        ) {
            unlockWalletTimestamp[contractAddress][to] = block.timestamp;
        }

        walletLock[contractAddress][to] = lockStatus;
    }

    function _isTokenLockToUnlock(
        address contractAddress,
        uint256 tokenId,
        IERC721Lockable.LockStatus newLockStatus
    ) private view returns (bool) {
        if (newLockStatus == IERC721Lockable.LockStatus.UnLock) {
            IERC721Lockable.LockStatus currentWalletLock = walletLock[
                contractAddress
            ][msg.sender];
            bool isWalletLock_TokenLockOrUnset = (currentWalletLock ==
                IERC721Lockable.LockStatus.Lock &&
                tokenLock[contractAddress][tokenId] !=
                IERC721Lockable.LockStatus.UnLock);
            bool isWalletUnlockOrUnset_TokenLock = (currentWalletLock !=
                IERC721Lockable.LockStatus.Lock &&
                tokenLock[contractAddress][tokenId] ==
                IERC721Lockable.LockStatus.Lock);

            return
                isWalletLock_TokenLockOrUnset ||
                isWalletUnlockOrUnset_TokenLock;
        } else if (newLockStatus == IERC721Lockable.LockStatus.UnSet) {
            IERC721Lockable.LockStatus currentWalletLock = walletLock[
                contractAddress
            ][msg.sender];
            bool isNotWalletLock = currentWalletLock !=
                IERC721Lockable.LockStatus.Lock;
            bool isTokenLock = tokenLock[contractAddress][tokenId] ==
                IERC721Lockable.LockStatus.Lock;

            return isNotWalletLock && isTokenLock;
        } else {
            return false;
        }
    }

    function setTokenLock(
        address contractAddress,
        uint256[] calldata tokenIds,
        IERC721Lockable.LockStatus newLockStatus
    ) external {
        require(tokenIds.length > 0, "tokenIds must be greater than 0.");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                msg.sender == IERC721(contractAddress).ownerOf(tokenIds[i]) || hasRole(ADMIN, msg.sender),
                "not owner or admin."
            );
        }

        uint40 currentTimestamp = uint40(block.timestamp);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (
                _isTokenLockToUnlock(
                    contractAddress,
                    tokenIds[i],
                    newLockStatus
                )
            ) {
                _unlockTokenTimestamp[contractAddress].set(tokenIds[i], currentTimestamp);
            }
            tokenLock[contractAddress][tokenIds[i]] = newLockStatus;
        }
    }

    function _isTokenTimeLock(address contractAddress, uint256 tokenId)
        private
        view
        returns (bool)
    {
        return
            _unlockTokenTimestamp[contractAddress].get(tokenId) + unlockLeadTime >
            block.timestamp;
    }

    function _isWalletTimeLock(address contractAddress, uint256 tokenId)
        private
        view
        returns (bool)
    {
        return
            unlockWalletTimestamp[contractAddress][
                IERC721(contractAddress).ownerOf(tokenId)
            ] +
                unlockLeadTime >
            block.timestamp;
    }

    function isLocked(address contractAddress, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return
            _isLocked(contractAddress, tokenId) ||
            _isTokenTimeLock(contractAddress, tokenId) ||
            _isWalletTimeLock(contractAddress, tokenId);
    }

    function setUnlockLeadTime(uint256 value) external onlyRole(ADMIN) {
        unlockLeadTime = value;
    }

    function _isLocked(address contractAddress, uint256 tokenId)
        private
        view
        returns (bool)
    {
        if (
            tokenLock[contractAddress][tokenId] ==
            IERC721Lockable.LockStatus.Lock ||
            (tokenLock[contractAddress][tokenId] ==
                IERC721Lockable.LockStatus.UnSet &&
                isLocked(contractAddress, IERC721(contractAddress).ownerOf(tokenId)))
        ) {
            return true;
        }

        return false;
    }

    function isLocked(address contractAddress, address holder)
        public
        view
        virtual
        returns (bool)
    {
        if (
            walletLock[contractAddress][holder] ==
            IERC721Lockable.LockStatus.Lock
        ) {
            return true;
        }

        return false;
    }
}
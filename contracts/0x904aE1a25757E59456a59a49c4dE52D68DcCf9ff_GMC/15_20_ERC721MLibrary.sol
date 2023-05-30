// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Library used for bitmap manipulation for ERC721M
/// @author phaze (https://github.com/0xPhaze/ERC721M)
library UserDataOps {
    /* ------------- balance: [0, 20) ------------- */

    function balance(uint256 userData) internal pure returns (uint256) {
        return userData & 0xFFFFF;
    }

    function increaseBalance(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData + amount;
        }
    }

    function decreaseBalance(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData - amount;
        }
    }

    /* ------------- numMinted: [20, 40) ------------- */

    function numMinted(uint256 userData) internal pure returns (uint256) {
        return (userData >> 20) & 0xFFFFF;
    }

    function increaseNumMinted(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData + (amount << 20);
        }
    }

    /* ------------- numLocked: [40, 60) ------------- */

    function numLocked(uint256 userData) internal pure returns (uint256) {
        return (userData >> 40) & 0xFFFFF;
    }

    function increaseNumLocked(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData + (amount << 40);
        }
    }

    function decreaseNumLocked(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData - (amount << 40);
        }
    }

    /* ------------- lockStart: [60, 100) ------------- */

    function userLockStart(uint256 userData) internal pure returns (uint256) {
        return (userData >> 60) & 0xFFFFFFFFFF;
    }

    function setUserLockStart(uint256 userData, uint256 timestamp) internal pure returns (uint256) {
        return (userData & ~uint256(0xFFFFFFFFFF << 60)) | (timestamp << 60);
    }

    // /* ------------- aux: [100, 256) ------------- */

    // function aux(uint256 userData) internal pure returns (uint256) {
    //     return (userData >> 100) & 0xFFFFFFFFFF;
    // }

    // function setAux(uint256 userData, uint256 aux_) internal pure returns (uint256) {
    //     return (userData & ~((uint256(1) << 100) - 1)) | (aux_ << 100);
    // }
}

library TokenDataOps {
    /// @dev Big question whether copy should transfer over data, such as,
    ///      aux data and timestamps
    function copy(uint256 tokenData) internal pure returns (uint256) {
        return tokenData;
    }

    // return tokenData & ((uint256(1) << (160 + (((tokenData >> 160) & 1) << 1))) - 1);
    /// ^ equivalent code:
    // function copy2(uint256 tokenData) internal pure returns (uint256) {
    //     uint256 copiedData = uint160(tokenData);
    //     if (isConsecutiveLocked(tokenData)) {
    //         copiedData = setConsecutiveLocked(copiedData);
    //         if (locked(tokenData)) copiedData = lock(copiedData);
    //     }
    //     return copiedData;
    // }

    /* ------------- owner: [0, 160) ------------- */

    function owner(uint256 tokenData) internal view returns (address) {
        return locked(tokenData) ? address(this) : trueOwner(tokenData);
    }

    function setOwner(uint256 tokenData, address owner_) internal pure returns (uint256) {
        return (tokenData & 0xFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000) | uint160(owner_);
    }

    function trueOwner(uint256 tokenData) internal pure returns (address) {
        return address(uint160(tokenData));
    }

    /* ------------- consecutiveLock: [160, 161) ------------- */

    function isConsecutiveLocked(uint256 tokenData) internal pure returns (bool) {
        return ((tokenData >> 160) & uint256(1)) != 0;
    }

    function setConsecutiveLocked(uint256 tokenData) internal pure returns (uint256) {
        return tokenData | (uint256(1) << 160);
    }

    function unsetConsecutiveLocked(uint256 tokenData) internal pure returns (uint256) {
        return tokenData & ~(uint256(1) << 160);
    }

    /* ------------- locked: [161, 162) ------------- */

    function locked(uint256 tokenData) internal pure returns (bool) {
        return ((tokenData >> 161) & uint256(1)) != 0; // Note: this is not masked and can carry over when calling 'ownerOf'
    }

    function lock(uint256 tokenData) internal view returns (uint256) {
        return setTokenLockStart(tokenData, block.timestamp) | (uint256(1) << 161);
    }

    function unlock(uint256 tokenData) internal view returns (uint256) {
        return setTokenLockStart(tokenData, block.timestamp) & ~(uint256(1) << 161);
    }

    /* ------------- nextTokenDataSet: [162, 163) ------------- */

    function nextTokenDataSet(uint256 tokenData) internal pure returns (bool) {
        return ((tokenData >> 162) & uint256(1)) != 0;
    }

    function flagNextTokenDataSet(uint256 tokenData) internal pure returns (uint256) {
        return tokenData | (uint256(1) << 162); // nextTokenDatatSet flag (don't repeat the read/write)
    }

    /* ------------- lockStart: [168, 208) ------------- */

    function tokenLockStart(uint256 tokenData) internal pure returns (uint256) {
        return (tokenData >> 168) & 0xFFFFFFFFFF;
    }

    function setTokenLockStart(uint256 tokenData, uint256 timestamp) internal pure returns (uint256) {
        return (tokenData & ~uint256(0xFFFFFFFFFF << 168)) | (timestamp << 168);
    }

    /* ------------- aux: [208, 256) ------------- */

    function aux(uint256 tokenData) internal pure returns (uint256) {
        return tokenData >> 208;
    }

    function setAux(uint256 tokenData, uint256 auxData) internal pure returns (uint256) {
        return (tokenData & ~uint256(0xFFFFFFFFFFFF << 208)) | (auxData << 208);
    }
}
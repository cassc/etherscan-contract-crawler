// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// # ERC721M.sol
//
// _tokenData layout:
// 0x________/cccccbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
// a [  0] (uint160): address #owner           (owner of token id)
// b [160] (uint40): timestamp #lastTransfer   (timestamp since the last transfer)
// c [200] (uint20): #ownerCount               (number of total owners of token)
// f [220] (uint1): #staked flag               (flag whether id has been staked) Note: this carries over when calling 'ownerOf'
// f [221] (uint1): #mintAndStake flag         (flag whether to carry over stake flag when calling tokenDataOf; used for mintAndStake and boost)
// e [222] (uint1): #nextTokenDataSet flag     (flag whether the data of next token id has already been set)
// _ [224] (uint32): arbitrary data

uint256 constant RESTRICTED_TOKEN_DATA = 0x00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

// # MadMouse.sol
//
// _tokenData (metadata) layout:
// 0xefg00000________________________________________________________
// e [252] (uint4): #level                     (mouse level)  [0...2] (must be 0-based)
// f [248] (uint4): #role                      (mouse role)   [1...5] (must start at 1)
// g [244] (uint4): #rarity                    (mouse rarity) [0...3]

struct TokenData {
    address owner;
    uint256 lastTransfer;
    uint256 ownerCount;
    bool staked;
    bool mintAndStake;
    bool nextTokenDataSet;
    uint256 level;
    uint256 role;
    uint256 rarity;
}

// # ERC721M.sol
//
// _userData layout:
// 0x________________________________ddccccccccccbbbbbbbbbbaaaaaaaaaa
// a [  0] (uint32): #balance                  (owner ERC721 balance)
// b [ 40] (uint40): timestamp #stakeStart     (timestamp when stake started)
// c [ 80] (uint40): timestamp #lastClaimed    (timestamp when user last claimed rewards)
// d [120] (uint8): #numStaked                 (balance count of all staked tokens)
// _ [128] (uint128): arbitrary data

uint256 constant RESTRICTED_USER_DATA = 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

// # MadMouseStaking.sol
//
// _userData (boost) layout:
// 0xttttttttt/o/rriiffgghhaabbccddee________________________________
// a-e [128] (5x uint8): #roleBalances         (balance of all staked roles)
// f-h [168] (3x uint8): #levelBalances        (balance of all staked levels)

// i [192] (uint8): #specialGuestIndex         (signals whether the user claims to hold a token of a certain collection)
// r [200] (uint10): #rarityPoints             (counter of rare traits; 1 is rare, 2 is super-rare, 3 is ultra-rare)
// o [210] (uint8): #OGCount                   (counter of rare traits; 1 is rare, 2 is super-rare, 3 is ultra-rare)
// t [218] (uint38): timestamp #boostStart     (timestamp of when the boost by burning tokens of affiliate collections started)

struct UserData {
    uint256 balance;
    uint256 stakeStart;
    uint256 lastClaimed;
    uint256 numStaked;
    uint256[5] roleBalances;
    uint256 uniqueRoleCount; // inferred
    uint256[3] levelBalances;
    uint256 specialGuestIndex;
    uint256 rarityPoints;
    uint256 OGCount;
    uint256 boostStart;
}

function applySafeDataTransform(
    uint256 userData,
    uint256 tokenData,
    uint256 userDataTransformed,
    uint256 tokenDataTransformed
) pure returns (uint256, uint256) {
    // mask transformed data in order to leave base data untouched in any case
    userData = (userData & RESTRICTED_USER_DATA) | (userDataTransformed & ~RESTRICTED_USER_DATA);
    tokenData = (tokenData & RESTRICTED_TOKEN_DATA) | (tokenDataTransformed & ~RESTRICTED_TOKEN_DATA);
    return (userData, tokenData);
}

// @note: many of these are unchecked, because safemath wouldn't be able to guard
// overflows while updating bitmaps unless custom checks were to be implemented

library UserDataOps {
    function getUserData(uint256 userData) internal pure returns (UserData memory) {
        return
            UserData({
                balance: UserDataOps.balance(userData),
                stakeStart: UserDataOps.stakeStart(userData),
                lastClaimed: UserDataOps.lastClaimed(userData),
                numStaked: UserDataOps.numStaked(userData),
                roleBalances: UserDataOps.roleBalances(userData),
                uniqueRoleCount: UserDataOps.uniqueRoleCount(userData),
                levelBalances: UserDataOps.levelBalances(userData),
                specialGuestIndex: UserDataOps.specialGuestIndex(userData),
                rarityPoints: UserDataOps.rarityPoints(userData),
                OGCount: UserDataOps.OGCount(userData),
                boostStart: UserDataOps.boostStart(userData)
            });
    }

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

    function numMinted(uint256 userData) internal pure returns (uint256) {
        return (userData >> 20) & 0xFFFFF;
    }

    function increaseNumMinted(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData + (amount << 20);
        }
    }

    function stakeStart(uint256 userData) internal pure returns (uint256) {
        return (userData >> 40) & 0xFFFFFFFFFF;
    }

    function setStakeStart(uint256 userData, uint256 timestamp) internal pure returns (uint256) {
        return (userData & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000FFFFFFFFFF) | (timestamp << 40);
    }

    function lastClaimed(uint256 userData) internal pure returns (uint256) {
        return (userData >> 80) & 0xFFFFFFFFFF;
    }

    function setLastClaimed(uint256 userData, uint256 timestamp) internal pure returns (uint256) {
        return (userData & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000FFFFFFFFFFFFFFFFFFFF) | (timestamp << 80);
    }

    function numStaked(uint256 userData) internal pure returns (uint256) {
        return (userData >> 120) & 0xFF;
    }

    function increaseNumStaked(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData + (amount << 120);
        }
    }

    function decreaseNumStaked(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData - (amount << 120);
        }
    }

    function roleBalances(uint256 userData) internal pure returns (uint256[5] memory balances) {
        balances = [
            (userData >> (128 + 0)) & 0xFF,
            (userData >> (128 + 8)) & 0xFF,
            (userData >> (128 + 16)) & 0xFF,
            (userData >> (128 + 24)) & 0xFF,
            (userData >> (128 + 32)) & 0xFF
        ];
    }

    // trait counts are set through hook in madmouse contract (MadMouse::_beforeStakeDataTransform)
    function uniqueRoleCount(uint256 userData) internal pure returns (uint256) {
        unchecked {
            return (toUInt256((userData >> (128)) & 0xFF > 0) +
                toUInt256((userData >> (128 + 8)) & 0xFF > 0) +
                toUInt256((userData >> (128 + 16)) & 0xFF > 0) +
                toUInt256((userData >> (128 + 24)) & 0xFF > 0) +
                toUInt256((userData >> (128 + 32)) & 0xFF > 0));
        }
    }

    function levelBalances(uint256 userData) internal pure returns (uint256[3] memory balances) {
        balances = [(userData >> (168 + 0)) & 0xFF, (userData >> (168 + 8)) & 0xFF, (userData >> (168 + 16)) & 0xFF];
    }

    // depends on the levels of the staked tokens (also set in hook MadMouse::_beforeStakeDataTransform)
    // counts the base reward, depending on the levels of staked ids
    function baseReward(uint256 userData) internal pure returns (uint256) {
        unchecked {
            return (((userData >> (168)) & 0xFF) +
                (((userData >> (168 + 8)) & 0xFF) << 1) +
                (((userData >> (168 + 16)) & 0xFF) << 2));
        }
    }

    function rarityPoints(uint256 userData) internal pure returns (uint256) {
        return (userData >> 200) & 0x3FF;
    }

    function specialGuestIndex(uint256 userData) internal pure returns (uint256) {
        return (userData >> 192) & 0xFF;
    }

    function setSpecialGuestIndex(uint256 userData, uint256 index) internal pure returns (uint256) {
        return (userData & ~uint256(0xFF << 192)) | (index << 192);
    }

    function boostStart(uint256 userData) internal pure returns (uint256) {
        return (userData >> 218) & 0xFFFFFFFFFF;
    }

    function setBoostStart(uint256 userData, uint256 timestamp) internal pure returns (uint256) {
        return (userData & ~(uint256(0xFFFFFFFFFF) << 218)) | (timestamp << 218);
    }

    function OGCount(uint256 userData) internal pure returns (uint256) {
        return (userData >> 210) & 0xFF;
    }

    //  (should start at 128, 168; but role/level start at 1...)
    function updateUserDataStake(uint256 userData, uint256 tokenData) internal pure returns (uint256) {
        unchecked {
            uint256 role = TokenDataOps.role(tokenData);
            if (role > 0) {
                userData += uint256(1) << (120 + (role << 3)); // roleBalances
                userData += TokenDataOps.rarity(tokenData) << 200; // rarityPoints
            }
            if (TokenDataOps.mintAndStake(tokenData)) userData += uint256(1) << 210; // OGCount
            userData += uint256(1) << (160 + (TokenDataOps.level(tokenData) << 3)); // levelBalances
            return userData;
        }
    }

    function updateUserDataUnstake(uint256 userData, uint256 tokenData) internal pure returns (uint256) {
        unchecked {
            uint256 role = TokenDataOps.role(tokenData);
            if (role > 0) {
                userData -= uint256(1) << (120 + (role << 3)); // roleBalances
                userData -= TokenDataOps.rarity(tokenData) << 200; // rarityPoints
            }
            if (TokenDataOps.mintAndStake(tokenData)) userData -= uint256(1) << 210; // OG-count
            userData -= uint256(1) << (160 + (TokenDataOps.level(tokenData) << 3)); // levelBalances
            return userData;
        }
    }

    function increaseLevelBalances(uint256 userData, uint256 tokenData) internal pure returns (uint256) {
        unchecked {
            return userData + (uint256(1) << (160 + (TokenDataOps.level(tokenData) << 3)));
        }
    }

    function decreaseLevelBalances(uint256 userData, uint256 tokenData) internal pure returns (uint256) {
        unchecked {
            return userData - (uint256(1) << (160 + (TokenDataOps.level(tokenData) << 3)));
        }
    }
}

library TokenDataOps {
    function getTokenData(uint256 tokenData) internal view returns (TokenData memory) {
        return
            TokenData({
                owner: TokenDataOps.owner(tokenData),
                lastTransfer: TokenDataOps.lastTransfer(tokenData),
                ownerCount: TokenDataOps.ownerCount(tokenData),
                staked: TokenDataOps.staked(tokenData),
                mintAndStake: TokenDataOps.mintAndStake(tokenData),
                nextTokenDataSet: TokenDataOps.nextTokenDataSet(tokenData),
                level: TokenDataOps.level(tokenData),
                role: TokenDataOps.role(tokenData),
                rarity: TokenDataOps.rarity(tokenData)
            });
    }

    function newTokenData(
        address owner_,
        uint256 lastTransfer_,
        bool stake_
    ) internal pure returns (uint256) {
        uint256 tokenData = (uint256(uint160(owner_)) | (lastTransfer_ << 160) | (uint256(1) << 200));
        return stake_ ? setstaked(setMintAndStake(tokenData)) : tokenData;
    }

    function copy(uint256 tokenData) internal pure returns (uint256) {
        // tokenData minus the token specific flags (4/2bits), i.e. only owner, lastTransfer, ownerCount
        // stake flag (& mintAndStake flag) carries over if mintAndStake was called
        return tokenData & (RESTRICTED_TOKEN_DATA >> (mintAndStake(tokenData) ? 2 : 4));
    }

    function owner(uint256 tokenData) internal view returns (address) {
        if (staked(tokenData)) return address(this);
        return trueOwner(tokenData);
    }

    function setOwner(uint256 tokenData, address owner_) internal pure returns (uint256) {
        return (tokenData & 0xFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000) | uint160(owner_);
    }

    function staked(uint256 tokenData) internal pure returns (bool) {
        return ((tokenData >> 220) & uint256(1)) > 0; // Note: this can carry over when calling 'ownerOf'
    }

    function setstaked(uint256 tokenData) internal pure returns (uint256) {
        return tokenData | (uint256(1) << 220);
    }

    function unsetstaked(uint256 tokenData) internal pure returns (uint256) {
        return tokenData & ~(uint256(1) << 220);
    }

    function mintAndStake(uint256 tokenData) internal pure returns (bool) {
        return ((tokenData >> 221) & uint256(1)) > 0;
    }

    function setMintAndStake(uint256 tokenData) internal pure returns (uint256) {
        return tokenData | (uint256(1) << 221);
    }

    function unsetMintAndStake(uint256 tokenData) internal pure returns (uint256) {
        return tokenData & ~(uint256(1) << 221);
    }

    function nextTokenDataSet(uint256 tokenData) internal pure returns (bool) {
        return ((tokenData >> 222) & uint256(1)) > 0;
    }

    function flagNextTokenDataSet(uint256 tokenData) internal pure returns (uint256) {
        return tokenData | (uint256(1) << 222); // nextTokenDatatSet flag (don't repeat the read/write)
    }

    function trueOwner(uint256 tokenData) internal pure returns (address) {
        return address(uint160(tokenData));
    }

    function ownerCount(uint256 tokenData) internal pure returns (uint256) {
        return (tokenData >> 200) & 0xFFFFF;
    }

    function incrementOwnerCount(uint256 tokenData) internal pure returns (uint256) {
        uint256 newOwnerCount = min(ownerCount(tokenData) + 1, 0xFFFFF);
        return (tokenData & ~(uint256(0xFFFFF) << 200)) | (newOwnerCount << 200);
    }

    function resetOwnerCount(uint256 tokenData) internal pure returns (uint256) {
        uint256 count = min(ownerCount(tokenData), 2); // keep minter status
        return (tokenData & ~(uint256(0xFFFFF) << 200)) | (count << 200);
    }

    function lastTransfer(uint256 tokenData) internal pure returns (uint256) {
        return (tokenData >> 160) & 0xFFFFFFFFFF;
    }

    function setLastTransfer(uint256 tokenData, uint256 timestamp) internal pure returns (uint256) {
        return (tokenData & 0xFFFFFFFFFFFFFF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | (timestamp << 160);
    }

    // MadMouse
    function level(uint256 tokenData) internal pure returns (uint256) {
        unchecked {
            return 1 + (tokenData >> 252);
        }
    }

    function increaseLevel(uint256 tokenData) internal pure returns (uint256) {
        unchecked {
            return tokenData + (uint256(1) << 252);
        }
    }

    function role(uint256 tokenData) internal pure returns (uint256) {
        return (tokenData >> 248) & 0xF;
    }

    function rarity(uint256 tokenData) internal pure returns (uint256) {
        return (tokenData >> 244) & 0xF;
    }

    // these slots should be are already 0
    function setRoleAndRarity(uint256 tokenData, uint256 dna) internal pure returns (uint256) {
        return ((tokenData & ~(uint256(0xFF) << 244)) | (DNAOps.toRole(dna) << 248) | (DNAOps.toRarity(dna) << 244));
    }
}

library DNAOps {
    function toRole(uint256 dna) internal pure returns (uint256) {
        unchecked {
            return 1 + ((dna & 0xFF) % 5);
        }
    }

    function toRarity(uint256 dna) internal pure returns (uint256) {
        uint256 dnaFur = (dna >> 8) & 0xFF;
        if (dnaFur > 108) return 0;
        if (dnaFur > 73) return 1;
        if (dnaFur > 17) return 2;
        return 3;
    }
}

/* ------------- Helpers ------------- */

// more efficient https://github.com/ethereum/solidity/issues/659
function toUInt256(bool x) pure returns (uint256 r) {
    assembly {
        r := x
    }
}

function min(uint256 a, uint256 b) pure returns (uint256) {
    return a < b ? a : b;
}

function isValidString(string calldata str, uint256 maxLen) pure returns (bool) {
    bytes memory b = bytes(str);
    if (b.length < 1 || b.length > maxLen || b[0] == 0x20 || b[b.length - 1] == 0x20) return false;

    bytes1 lastChar = b[0];

    bytes1 char;
    for (uint256 i; i < b.length; ++i) {
        char = b[i];

        if (
            (char > 0x60 && char < 0x7B) || //a-z
            (char > 0x40 && char < 0x5B) || //A-Z
            (char == 0x20) || //space
            (char > 0x2F && char < 0x3A) //9-0
        ) {
            lastChar = char;
        } else {
            return false;
        }
    }

    return true;
}
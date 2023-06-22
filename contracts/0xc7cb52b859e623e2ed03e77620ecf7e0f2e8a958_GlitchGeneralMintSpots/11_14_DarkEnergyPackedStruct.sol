// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library DarkEnergyPackedStruct {
    // =============================================================
    //                            Structs
    // =============================================================

    /// @dev All 256 bits from a PlayerData (from right to left)
    struct PlayerData {
        bool isHolder;
        int40 energyAmount;
        uint16 gamePasses;
        uint16 mintCount;
        uint16 mergeCount;
        uint16 noRiskPlayCount;
        uint16 noRiskWinCount;
        uint16 highStakesPlayCount;
        uint16 highStakesWinCount;
        uint16 highStakesLossCount;
        uint32 totalEarned;
        uint32 totalRugged;
        uint16 unused;
        bool flagA;
        bool flagB;
        bool flagC;
        bool flagD;
        bool flagE;
        bool flagF;
        bool flagG;
    }

    /// @dev All 256 bits from a GameRules (from right to left)
    struct GameRules {
        bool isActive;
        uint16 oddsNoRiskEarn100;
        uint16 oddsNoRiskEarn300;
        uint16 oddsNoRiskEarn500;
        uint16 oddsHighStakesWinOrdinal;
        uint16 oddsHighStakesLose100;
        uint16 oddsHighStakesLose300;
        uint16 oddsHighStakesLose500;
        uint16 oddsHighStakesLose1000;
        uint16 oddsHighStakesEarn100;
        uint16 oddsHighStakesEarn300;
        uint16 oddsHighStakesEarn500;
        uint16 oddsHighStakesEarn1000;
        uint16 oddsHighStakesDoubles;
        uint16 oddsHighStakesHalves;
        uint16 oddsGamePassOnMint;
        uint8 remainingOrdinals;
        bool flagA;
        bool flagB;
        bool flagC;
        bool flagD;
        bool flagE;
        bool flagF;
        bool flagG;
    }

    // =============================================================
    //                 Unpacking by type and offset
    // =============================================================

    /**
     * @dev unpack bit [offset] (bool)
     */
    function getBool(bytes32 p, uint8 offset) internal pure returns (bool r) {
        assembly {
            r := and(shr(offset, p), 1)
        }
    }

    /**
     * @dev unpack bits [offset..offset + 8]
     */
    function getUint8(bytes32 p, uint8 offset) internal pure returns (uint8 r) {
        assembly {
            r := and(shr(offset, p), 0xFF)
        }
    }

    /**
     * @dev unpack bits [offset..offset + 16]
     */
    function getUint16(
        bytes32 p,
        uint8 offset
    ) internal pure returns (uint16 r) {
        assembly {
            r := and(shr(offset, p), 0xFFFF)
        }
    }

    /**
     * @dev unpack bits [offset..offset + 32]
     */
    function getUint32(
        bytes32 p,
        uint8 offset
    ) internal pure returns (uint32 r) {
        assembly {
            r := and(shr(offset, p), 0xFFFFFFFF)
        }
    }

    /**
     * @dev unpack bits[offset..offset + 40]
     */
    function getInt40(bytes32 p, uint8 offset) internal pure returns (int40 r) {
        assembly {
            r := and(shr(offset, p), 0xFFFFFFFFFF)
        }
    }

    // =============================================================
    //                    Unpacking whole structs
    // =============================================================

    function playerData(bytes32 p) internal pure returns (PlayerData memory r) {
        return
            PlayerData({
                isHolder: getBool(p, 0),
                energyAmount: getInt40(p, 1),
                gamePasses: getUint16(p, 41),
                mintCount: getUint16(p, 57),
                mergeCount: getUint16(p, 73),
                noRiskPlayCount: getUint16(p, 89),
                noRiskWinCount: getUint16(p, 105),
                highStakesPlayCount: getUint16(p, 121),
                highStakesWinCount: getUint16(p, 137),
                highStakesLossCount: getUint16(p, 153),
                totalEarned: getUint32(p, 169),
                totalRugged: getUint32(p, 201),
                unused: getUint16(p, 169),
                flagA: getBool(p, 249),
                flagB: getBool(p, 250),
                flagC: getBool(p, 251),
                flagD: getBool(p, 252),
                flagE: getBool(p, 253),
                flagF: getBool(p, 254),
                flagG: getBool(p, 255)
        });
    }

    function gameRules(bytes32 p) internal pure returns (GameRules memory r) {
        return
            GameRules({
                isActive: getBool(p, 0),
                oddsNoRiskEarn100: getUint16(p, 1),
                oddsNoRiskEarn300: getUint16(p, 17),
                oddsNoRiskEarn500: getUint16(p, 33),
                oddsHighStakesWinOrdinal: getUint16(p, 49),
                oddsHighStakesLose100: getUint16(p, 65),
                oddsHighStakesLose300: getUint16(p, 81),
                oddsHighStakesLose500: getUint16(p, 97),
                oddsHighStakesLose1000: getUint16(p, 113),
                oddsHighStakesEarn100: getUint16(p, 129),
                oddsHighStakesEarn300: getUint16(p, 145),
                oddsHighStakesEarn500: getUint16(p, 161),
                oddsHighStakesEarn1000: getUint16(p, 177),
                oddsHighStakesDoubles: getUint16(p, 193),
                oddsHighStakesHalves: getUint16(p, 209),
                oddsGamePassOnMint: getUint16(p, 225),
                remainingOrdinals: getUint8(p, 241),
                flagA: getBool(p, 249),
                flagB: getBool(p, 250),
                flagC: getBool(p, 251),
                flagD: getBool(p, 252),
                flagE: getBool(p, 253),
                flagF: getBool(p, 254),
                flagG: getBool(p, 255)
            });
    }

    // =============================================================
    //                         Setting Bits
    // =============================================================

    /**
     * @dev set bit [{offset}] to {value}
     */
    function setBit(
        bytes32 p,
        uint8 offset,
        bool value
    ) internal pure returns (bytes32 np) {
        assembly {
            np := or(
                and(
                    p,
                    xor(
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                        shl(offset, 1)
                    )
                ),
                shl(offset, value)
            )
        }
    }

    /**
     * @dev set 8 bits to {value} at [{offset}]
     */
    function setUint8(
        bytes32 p,
        uint8 offset,
        uint8 value
    ) internal pure returns (bytes32 np) {
        assembly {
            np := or(
                and(
                    p,
                    xor(
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                        shl(offset, 0xFF)
                    )
                ),
                shl(offset, and(value, 0xFF))
            )
        }
    }

    /**
     * @dev set 16 bits to {value} at [{offset}]
     */
    function setUint16(
        bytes32 p,
        uint8 offset,
        uint16 value
    ) internal pure returns (bytes32 np) {
        assembly {
            np := or(
                and(
                    p,
                    xor(
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                        shl(offset, 0xFFFF)
                    )
                ),
                shl(offset, and(value, 0xFFFF))
            )
        }
    }

    /**
     * @dev set 32 bits to {value} at [{offset}]
     */
    function setUint32(
        bytes32 p,
        uint8 offset,
        uint32 value
    ) internal pure returns (bytes32 np) {
        assembly {
            np := or(
                and(
                    p,
                    xor(
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                        shl(offset, 0xFFFFFFFF)
                    )
                ),
                shl(offset, and(value, 0xFFFFFFFF))
            )
        }
    }

    /**
     * @dev set 40 bits to {value} at [{offset}]
     */
    function setInt40(
        bytes32 p,
        uint8 offset,
        int40 value
    ) internal pure returns (bytes32 np) {
        assembly {
            np := or(
                and(
                    p,
                    xor(
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                        shl(offset, 0xFFFFFFFFFF)
                    )
                ),
                shl(offset, and(value, 0xFFFFFFFFFF))
            )
        }
    }

    // =============================================================
    //                         DarkEnergy-specific
    // =============================================================

    /**
     * @dev get _playerData.isHolder
     */
    function isHolder(bytes32 p) internal pure returns (bool) {
        return getBool(p, 0);
    }

    /**
     * @dev get _playerData.energyAmount
     */
    function getEnergy(bytes32 p) internal pure returns (int40) {
        return getInt40(p, 1);
    }

    /**
     * @dev get _playerData.gamePasses
     */
    function getGamePasses(bytes32 p) internal pure returns (uint16) {
        return getUint16(p, 41);
    }

    /**
     * @dev get _playerData.mintCount
     */
    function getMintCount(bytes32 p) internal pure returns (uint16) {
        return getUint16(p, 57);
    }

    /**
     * @dev get _playerData.mergeCount
     */
    function getMergeCount(bytes32 p) internal pure returns (uint16) {
        return getUint16(p, 73);
    }

    /**
     * @dev get _playerData.noRiskPlayCount
     */
    function getNoRiskPlayCount(bytes32 p) internal pure returns (uint16) {
        return getUint16(p, 89);
    }

    /**
     * @dev get _playerData.noRiskWinCount
     */
    function getNoRiskWinCount(bytes32 p) internal pure returns (uint16) {
        return getUint16(p, 105);
    }

    /**
     * @dev get _playerData.highStakesPlayCount
     */
    function getHighStakesPlayCount(bytes32 p) internal pure returns (uint16) {
        return getUint16(p, 121);
    }

    /**
     * @dev get _playerData.highStakesWinCount
     */
    function getHighStakesWinCount(bytes32 p) internal pure returns (uint16) {
        return getUint16(p, 137);
    }

    /**
     * @dev get _playerData.highStakesLossCount
     */
    function getHighStakesLossCount(bytes32 p) internal pure returns (uint16) {
        return getUint16(p, 153);
    }

    /**
     * @dev get _playerData.totalEarned
     */
    function getTotalEarned(bytes32 p) internal pure returns (uint32) {
        return getUint32(p, 169);
    }

    /**
     * @dev get _playerData.totalRugged
     */
    function getTotalRugged(bytes32 p) internal pure returns (uint32) {
        return getUint32(p, 201);
    }

    /**
     * @dev sets _playerData.isHolder
     */
    function setHolder(bytes32 p, bool status) internal pure returns (bytes32 np) {
        return setBit(p, 0, status);
    }

    /**
     * @dev sets _playerData.energyAmount
     */
    function setEnergy(bytes32 p, int40 value) internal pure returns (bytes32 np) {
        return setInt40(p, 1, value);
    }

    /**
     * @dev sets _playerData.gamePasses
     */
    function setGamePasses(bytes32 p, uint16 value) internal pure returns (bytes32 np) {
        return setUint16(p, 41, value);
    }

    /**
     * @dev sets _playerData.mintCount
     */
    function setMintCount(bytes32 p, uint16 value) internal pure returns (bytes32 np) {
        return setUint16(p, 57, value);
    }

    /**
     * @dev sets _playerData.mergeCount
     */
    function setMergeCount(bytes32 p, uint16 value) internal pure returns (bytes32 np) {
        return setUint16(p, 73, value);
    }

    /**
     * @dev sets _playerData.noRiskPlayCount
     */
    function setNoRiskPlayCount(bytes32 p, uint16 value) internal pure returns (bytes32 np) {
        return setUint16(p, 89, value);
    }

    /**
     * @dev sets _playerData.noRiskWinCount
     */
    function setNoRiskWinCount(bytes32 p, uint16 value) internal pure returns (bytes32 np) {
        return setUint16(p, 105, value);
    }

    /**
     * @dev sets _playerData.highStakesPlayCount
     */
    function setHighStakesPlayCount(bytes32 p, uint16 value) internal pure returns (bytes32 np) {
        return setUint16(p, 121, value);
    }

    /**
     * @dev sets _playerData.highStakesWinCount
     */
    function setHighStakesWinCount(bytes32 p, uint16 value) internal pure returns (bytes32 np) {
        return setUint16(p, 137, value);
    }

    /**
     * @dev sets _playerData.highStakesLossCount
     */
    function setHighStakesLossCount(bytes32 p, uint16 value) internal pure returns (bytes32 np) {
        return setUint16(p, 153, value);
    }

    /**
     * @dev sets _playerData.totalEarned
     */
    function setTotalEarned(bytes32 p, uint32 value) internal pure returns (bytes32 np) {
        return setUint32(p, 169, value);
    }

    /**
     * @dev sets _playerData.totalRugged
     */
    function setTotalRugged(bytes32 p, uint32 value) internal pure returns (bytes32 np) {
        return setUint32(p, 201, value);
    }

    /**
     * @dev Clears the last 57 bits (isHolder, energyAmount, gamePasses)
     */
    function clearHoldingData(bytes32 p) internal pure returns (bytes32 np) {
        assembly {
            np := and(
                p,
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE00000000000000
            )
        }
    }

    /**
     * @dev Replace the last 57 bits (isHolder, energyAmount, gamePasses) from
     *      another packed bytes variable (to be used for transfers)
     */
    function setHoldingData(
        bytes32 p,
        bytes32 q
    ) internal pure returns (bytes32 np) {
        assembly {
            np := or(
                and(
                    p,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE00000000000000
                ),
                and(q, 0x1FFFFFFFFFFFFFF)
            )
        }
    }

    /**
     * @dev tight-pack a GameRules struct into a uint256
     */
    function packGameRules(
        GameRules calldata
    ) internal pure returns (bytes32 result) {
        assembly {
            result := calldataload(4)
            result := or(result, shl(1, calldataload(36)))
            result := or(result, shl(17, calldataload(68)))
            result := or(result, shl(33, calldataload(100)))
            result := or(result, shl(49, calldataload(132)))
            result := or(result, shl(65, calldataload(164)))
            result := or(result, shl(81, calldataload(196)))
            result := or(result, shl(97, calldataload(228)))
            result := or(result, shl(113, calldataload(260)))
            result := or(result, shl(129, calldataload(292)))
            result := or(result, shl(145, calldataload(324)))
            result := or(result, shl(161, calldataload(356)))
            result := or(result, shl(177, calldataload(388)))
            result := or(result, shl(193, calldataload(420)))
            result := or(result, shl(209, calldataload(452)))
            result := or(result, shl(225, calldataload(484)))
            result := or(result, shl(241, calldataload(516)))
            result := or(result, shl(249, calldataload(548)))
            result := or(result, shl(250, calldataload(580)))
            result := or(result, shl(251, calldataload(612)))
            result := or(result, shl(252, calldataload(644)))
            result := or(result, shl(253, calldataload(676)))
            result := or(result, shl(254, calldataload(708)))
            result := or(result, shl(255, calldataload(740)))
        }
    }
}
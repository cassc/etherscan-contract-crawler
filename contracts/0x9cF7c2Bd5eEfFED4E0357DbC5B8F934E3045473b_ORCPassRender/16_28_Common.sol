// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface CommonTypes {
    enum PassType {
        NONE,
        SILVER,
        BRONZE,
        GOLD,
        PLATINUM,
        FIRE,
        SOLD_OUT
    }
}

contract Common is CommonTypes {
    string private constant DNone = "NONE";
    string private constant DSilver = "SILVER";
    string private constant DBronze = "BRONZE";
    string private constant DGold = "GOLD";
    string private constant DPlatinum = "PLATINUM";
    string private constant DFire = "FIRE";
    string private constant DSoldOut = "SOLD OUT";

    string private constant None = "None";
    string private constant Silver = "Silver";
    string private constant Bronze = "Bronze";
    string private constant Gold = "Gold";
    string private constant Platinum = "Platinum";
    string private constant Fire = "Fire";
    string private constant SoldOut = "SoldOut";

    function getPassName(PassType passType)
        internal
        pure
        returns (string memory)
    {
        if (passType == PassType.SILVER) {
            return Silver;
        } else if (passType == PassType.BRONZE) {
            return Bronze;
        } else if (passType == PassType.GOLD) {
            return Gold;
        } else if (passType == PassType.PLATINUM) {
            return Platinum;
        } else if (passType == PassType.FIRE) {
            return Fire;
        } else if (passType == PassType.SOLD_OUT) {
            return SoldOut;
        }
        return None;
    }

    function getPassDisplayName(PassType passType)
        internal
        pure
        returns (string memory)
    {
        if (passType == PassType.SILVER) {
            return DSilver;
        } else if (passType == PassType.BRONZE) {
            return DBronze;
        } else if (passType == PassType.GOLD) {
            return DGold;
        } else if (passType == PassType.PLATINUM) {
            return DPlatinum;
        } else if (passType == PassType.FIRE) {
            return DFire;
        } else if (passType == PassType.SOLD_OUT) {
            return DSoldOut;
        }
        return DNone;
    }
}
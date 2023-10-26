// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library Constants {
    /// @notice Flooring protocol
    /// @dev floor token amount of 1 NFT (with 18 decimals)
    uint256 public constant FLOOR_TOKEN_AMOUNT = 1_000_000 ether;
    /// @dev The minimum vip level required to use `proxy collection`
    uint8 public constant PROXY_COLLECTION_VIP_THRESHOLD = 3;

    /// @notice Rolling Bucket Constant Conf
    uint256 public constant BUCKET_SPAN_1 = 259199 seconds; // BUCKET_SPAN minus 1, used for rounding up
    uint256 public constant BUCKET_SPAN = 3 days;
    uint256 public constant MAX_LOCKING_BUCKET = 240;
    uint256 public constant MAX_LOCKING_PERIOD = 720 days; // MAX LOCKING BUCKET * BUCKET_SPAN

    /// @notice Auction Config
    uint256 public constant FREE_AUCTION_PERIOD = 24 hours;
    uint256 public constant AUCTION_INITIAL_PERIODS = 24 hours;
    uint256 public constant AUCTION_COMPLETE_GRACE_PERIODS = 2 days;
    /// @dev minimum bid per NFT when someone starts aution on expired safebox
    uint256 public constant AUCTION_ON_EXPIRED_MINIMUM_BID = 1000 ether;
    /// @dev admin fee charged per NFT when someone starts aution on expired safebox
    uint256 public constant AUCTION_ON_EXPIRED_SAFEBOX_COST = 2000 ether;
    /// @dev admin fee charged per NFT when owner starts aution on himself safebox
    uint256 public constant AUCTION_COST = 2000 ether;

    /// @notice Raffle Config
    uint256 public constant RAFFLE_COST = 5000 ether;
    uint256 public constant RAFFLE_COMPLETE_GRACE_PERIODS = 2 days;

    /// @notice Private offer Config
    uint256 public constant PRIVATE_OFFER_DURATION = 24 hours;
    uint256 public constant PRIVATE_OFFER_COMPLETE_GRACE_DURATION = 2 days;
    uint256 public constant PRIVATE_OFFER_COST = 0;

    uint256 public constant ADD_FREE_NFT_REWARD = 0;

    /// @notice Lock/Unlock config
    uint256 public constant LOCKING_RAMP_UP_THRESHOLD = 20;

    uint256 public constant LOCKING_PCT_TO_SAFEBOX_MAINT_MIN = 6000 ether;
    uint256 public constant LOCKING_PCT_TO_SAFEBOX_MAINT_MAX = 1728000 ether;

    /// @notice Activities Fee Rate

    /// @notice Fee rate used to distribute funds that collected from Auctions on expired safeboxes.
    /// these auction would be settled using credit token
    uint256 public constant FREE_AUCTION_FEE_RATE_BIPS = 2000; // 20%
    /// @notice Fee rate settled with credit token
    uint256 public constant CREDIT_FEE_RATE_BIPS = 150; // 2%
    /// @notice Fee rate settled with specified token
    uint256 public constant SPEC_FEE_RATE_BIPS = 300; // 3%
    /// @notice Fee rate settled with all other tokens
    uint256 public constant COMMON_FEE_RATE_BIPS = 500; // 5%

    uint256 public constant VIP_LEVEL_COUNT = 8;

    struct AuctionBidOption {
        uint256 extendDurationSecs;
        uint256 minimumRaisePct;
        uint256 vipLevel;
    }

    function getVipLockingBuckets(uint256 vipLevel) internal pure returns (uint256 buckets) {
        require(vipLevel < VIP_LEVEL_COUNT);
        assembly {
            switch vipLevel
            case 1 { buckets := 1 }
            case 2 { buckets := 5 }
            case 3 { buckets := 20 }
            case 4 { buckets := 60 }
            case 5 { buckets := 120 }
            case 6 { buckets := 240 }
            case 7 { buckets := MAX_LOCKING_BUCKET }
        }
    }

    function getVipLevel(uint256 totalCredit) internal pure returns (uint8) {
        if (totalCredit < 50_000 ether) {
            return 0;
        } else if (totalCredit < 200_000 ether) {
            return 1;
        } else if (totalCredit < 500_000 ether) {
            return 2;
        } else if (totalCredit < 2_000_000 ether) {
            return 3;
        } else if (totalCredit < 5_000_000 ether) {
            return 4;
        } else if (totalCredit < 20_000_000 ether) {
            return 5;
        } else if (totalCredit < 50_000_000 ether) {
            return 6;
        } else {
            return 7;
        }
    }

    function getVipBalanceRequirements(uint256 vipLevel) internal pure returns (uint256 required) {
        require(vipLevel < VIP_LEVEL_COUNT);

        assembly {
            switch vipLevel
            case 1 { required := 50000 }
            case 2 { required := 200000 }
            case 3 { required := 500000 }
            case 4 { required := 2000000 }
            case 5 { required := 5000000 }
            case 6 { required := 20000000 }
            case 7 { required := 50000000 }
        }

        /// credit token should be scaled with 18 decimals(1 ether == 10**18)
        unchecked {
            return required * 1 ether;
        }
    }

    function getBidOption(uint256 idx) internal pure returns (AuctionBidOption memory) {
        require(idx < 4);
        AuctionBidOption[4] memory bidOptions = [
            AuctionBidOption({extendDurationSecs: 5 minutes, minimumRaisePct: 1, vipLevel: 0}),
            AuctionBidOption({extendDurationSecs: 8 hours, minimumRaisePct: 10, vipLevel: 3}),
            AuctionBidOption({extendDurationSecs: 16 hours, minimumRaisePct: 20, vipLevel: 5}),
            AuctionBidOption({extendDurationSecs: 24 hours, minimumRaisePct: 40, vipLevel: 7})
        ];
        return bidOptions[idx];
    }

    function raffleDurations(uint256 idx) internal pure returns (uint256 vipLevel, uint256 duration) {
        require(idx < 6);

        vipLevel = idx;
        assembly {
            switch idx
            case 1 { duration := 1 }
            case 2 { duration := 2 }
            case 3 { duration := 3 }
            case 4 { duration := 5 }
            case 5 { duration := 7 }
        }
        unchecked {
            duration *= 1 days;
        }
    }

    function getVipRequiredStakingWithDiscount(uint256 requiredStaking, uint8 vipLevel)
        internal
        pure
        returns (uint256)
    {
        if (vipLevel < 3) {
            return requiredStaking;
        }
        unchecked {
            /// the higher vip level, more discount for staking
            ///  discount range: 10% - 50%
            return requiredStaking * (100 - (vipLevel - 2) * 10) / 100;
        }
    }

    function getRequiredStakingForLockRatio(uint256 locked, uint256 totalManaged) internal pure returns (uint256) {
        if (totalManaged < Constants.LOCKING_RAMP_UP_THRESHOLD) {
            return 6000 ether;
        }

        unchecked {
            uint256 lockingRatioPct = locked * 100 / totalManaged;
            if (lockingRatioPct <= 40) {
                return 6000 ether;
            } else if (lockingRatioPct < 60) {
                return 6600 ether + ((lockingRatioPct - 40) >> 1) * 600 ether;
            } else if (lockingRatioPct < 70) {
                return 13200 ether + ((lockingRatioPct - 60) >> 1) * 1200 ether;
            } else if (lockingRatioPct < 80) {
                return 20400 ether + ((lockingRatioPct - 70) >> 1) * 2400 ether;
            } else if (lockingRatioPct < 90) {
                return 34800 ether + ((lockingRatioPct - 80) >> 1) * 4800 ether;
            } else if (lockingRatioPct < 100) {
                /// 108000 * 2^x
                return 108000 ether << ((lockingRatioPct - 90) >> 1);
            } else {
                return 1728000 ether;
            }
        }
    }

    function getVipClaimCostWithDiscount(uint256 cost, uint8 vipLevel) internal pure returns (uint256) {
        if (vipLevel < 3) {
            return cost;
        }

        unchecked {
            uint256 discount = 4000 ether << (vipLevel - 3);
            if (cost < discount) {
                return 0;
            } else {
                return cost - discount;
            }
        }
    }

    function getClaimExpiredCost(uint256 locked, uint256 totalManaged, uint8 vipLevel)
        internal
        pure
        returns (uint256)
    {
        uint256 realCost = getClaimCost(locked, totalManaged);
        return getVipClaimCostWithDiscount(realCost, vipLevel);
    }

    function getClaimRandomCost(uint256 locked, uint256 totalManaged, uint8 vipLevel) internal pure returns (uint256) {
        uint256 realCost = getClaimCost(locked, totalManaged);
        return getVipClaimCostWithDiscount(realCost, vipLevel);
    }

    function getClaimCost(uint256 locked, uint256 totalManaged) private pure returns (uint256) {
        if (totalManaged < Constants.LOCKING_RAMP_UP_THRESHOLD) {
            return 0;
        }

        unchecked {
            uint256 lockingRatioPct = locked * 100 / totalManaged;

            if (lockingRatioPct <= 60) {
                return 0;
            } else if (lockingRatioPct < 100) {
                uint256 cost = 1 ether;
                assembly {
                    switch shr(1, sub(lockingRatioPct, 60))
                    case 0 { cost := mul(cost, 400) }
                    case 1 { cost := mul(cost, 600) }
                    case 2 { cost := mul(cost, 800) }
                    case 3 { cost := mul(cost, 1200) }
                    case 4 { cost := mul(cost, 1600) }
                    case 5 { cost := mul(cost, 2400) }
                    case 6 { cost := mul(cost, 3200) }
                    case 7 { cost := mul(cost, 4800) }
                    case 8 { cost := mul(cost, 6400) }
                    case 9 { cost := mul(cost, 9600) }
                    case 10 { cost := mul(cost, 12800) }
                    case 11 { cost := mul(cost, 19200) }
                    case 12 { cost := mul(cost, 25600) }
                    case 13 { cost := mul(cost, 38400) }
                    case 14 { cost := mul(cost, 51200) }
                    case 15 { cost := mul(cost, 76800) }
                    case 16 { cost := mul(cost, 102400) }
                    case 17 { cost := mul(cost, 153600) }
                    case 18 { cost := mul(cost, 204800) }
                    case 19 { cost := mul(cost, 307200) }
                }
                return cost;
            } else {
                return 307200 ether;
            }
        }
    }
}
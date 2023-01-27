// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library TexturePunxCoreStorage {
    struct Layout {
        /// DNA Sequences For Minted Punx ==================================================================

        mapping (uint256 => bytes32) serializedPunx;
        mapping (bytes32 => bool)    registeredPunx;
        
        string DESCRIPTION;
    }

    bytes32 constant SLO = keccak256("texturePunx.storage.v1.core");

    function init() internal { 
        layout().DESCRIPTION = "Texture Punx - metadata & img fully on chain, forever.";
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLO;
        assembly {
            l.slot := slot
        }
    }
}

library TexturePunxPaymentStorage {
    struct Layout {
        /// Forwarding contracts for handing royalties and mint share ======================================

        address payable mintForwarder;
        address payable royaltyForwarder;
    }

    bytes32 constant SLO = keccak256("texturePunx.storage.v1.payments");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLO;
        assembly {
            l.slot := slot
        }
    }
}

library TexturePunxTraitStorage {
    enum TraitRarity {
        BASIC,
        PREMIUM,
        LIMITED
    }

    struct TraitCategory {
        string name;
        bool   required;
    }

    struct TraitDescription {
        string name;
        TraitRarity rarity;
        uint64 uses;
    }

    struct Layout {
        /// Trait Variables ================================================================================

        mapping (uint8 => TraitCategory) categories;
        uint8 categoryCount;

        mapping (uint8 => mapping (uint8 => TraitDescription)) traits;
        uint8[] traitCount;

        mapping (bytes32 => bytes) svgs;

        bytes background;
    }

    bytes32 constant SLO = keccak256("texturePunx.storage.v1.traits");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLO;
        assembly {
            l.slot := slot
        }
    }
}

library TexturePunxMintingStorage {
    enum WhitelistRoundPricing {
        FREE,
        VIP,
        PAID
    }

    struct WhitelistRound {
        bytes32 merkelRoot;
        uint64  mintRound;
        uint64  mintAllowance;

        WhitelistRoundPricing price;
    }

    struct Layout {
        /// Minting & Whitelist Variables ==================================================================

        bool isPublicSaleActive;

        uint64 reservedSupply;

        mapping (uint64 => WhitelistRound) round;
        uint64 nextRound;

        mapping (uint64 => mapping (address => uint64)) mintRound;
    }

    bytes32 constant SLO = keccak256("texturePunx.storage.v1.minting");

    function init() internal { 
        layout().isPublicSaleActive = false;
        layout().reservedSupply = 120;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLO;
        assembly {
            l.slot := slot
        }
    }
}
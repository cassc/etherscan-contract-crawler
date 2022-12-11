// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library DataTypes {
    uint256 internal constant BAYC_POOL_ID = 1;
    uint256 internal constant MAYC_POOL_ID = 2;
    uint256 internal constant BAKC_POOL_ID = 3;

    bytes32 internal constant APE_OFFER_HASH =
        keccak256(
            "ApeOffer(uint8 poolId,address staker,address bakcOfferee,address coinOfferee,address collection,uint256 tokenId,uint256 minCoinCap,uint256 coinAmount,uint256 share,uint256 startTime,uint256 endTime,uint256 nonce)"
        );

    bytes32 internal constant BAKC_OFFER_HASH =
        keccak256(
            "BakcOffer(address staker,address apeOfferee,address coinOfferee,uint256 tokenId,uint256 minCoinCap,uint256 coinAmount,uint256 share,uint256 startTime,uint256 endTime,uint256 nonce)"
        );

    bytes32 internal constant COIN_OFFER_HASH =
        keccak256(
            "CoinOffer(uint8 poolId,address staker,address apeOfferee,address bakcOfferee,uint256 minCoinCap,uint256 coinAmount,uint256 share,uint256 startTime,uint256 endTime,uint256 nonce)"
        );

    struct ApeOffer {
        uint8 poolId;
        address staker;
        address bakcOfferee;
        address coinOfferee;
        address collection;
        uint256 tokenId;
        uint256 minCoinCap;
        uint256 coinAmount;
        uint256 share;
        uint256 startTime;
        uint256 endTime;
        uint256 nonce;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct ApeStaked {
        bytes32 offerHash;
        address staker;
        address collection;
        uint256 tokenId;
        uint256 coinAmount;
        uint256 share;
    }

    struct BakcOffer {
        address staker;
        address apeOfferee;
        address coinOfferee;
        uint256 tokenId;
        uint256 minCoinCap;
        uint256 coinAmount;
        uint256 share;
        uint256 startTime;
        uint256 endTime;
        uint256 nonce;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct BakcStaked {
        bytes32 offerHash;
        address staker;
        uint256 tokenId;
        uint256 coinAmount;
        uint256 share;
    }

    struct CoinOffer {
        uint8 poolId;
        address staker;
        address apeOfferee;
        address bakcOfferee;
        uint256 minCoinCap;
        uint256 coinAmount;
        uint256 share;
        uint256 startTime;
        uint256 endTime;
        uint256 nonce;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct CoinStaked {
        bytes32 offerHash;
        address staker;
        uint256 coinAmount;
        uint256 share;
    }

    function hash(ApeOffer memory apeOffer) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    APE_OFFER_HASH,
                    apeOffer.poolId,
                    apeOffer.staker,
                    apeOffer.bakcOfferee,
                    apeOffer.coinOfferee,
                    apeOffer.collection,
                    apeOffer.tokenId,
                    apeOffer.minCoinCap,
                    apeOffer.coinAmount,
                    apeOffer.share,
                    apeOffer.startTime,
                    apeOffer.endTime,
                    apeOffer.nonce
                )
            );
    }

    function hash(BakcOffer memory bakcOffer) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BAKC_OFFER_HASH,
                    bakcOffer.staker,
                    bakcOffer.apeOfferee,
                    bakcOffer.coinOfferee,
                    bakcOffer.tokenId,
                    bakcOffer.minCoinCap,
                    bakcOffer.coinAmount,
                    bakcOffer.share,
                    bakcOffer.startTime,
                    bakcOffer.endTime,
                    bakcOffer.nonce
                )
            );
    }

    function hash(CoinOffer memory coinOffer) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    COIN_OFFER_HASH,
                    coinOffer.poolId,
                    coinOffer.staker,
                    coinOffer.apeOfferee,
                    coinOffer.bakcOfferee,
                    coinOffer.minCoinCap,
                    coinOffer.coinAmount,
                    coinOffer.share,
                    coinOffer.startTime,
                    coinOffer.endTime,
                    coinOffer.nonce
                )
            );
    }

    function toStaked(ApeOffer memory apeOffer) internal pure returns (ApeStaked memory apeStaked) {
        apeStaked.offerHash = hash(apeOffer);
        apeStaked.staker = apeOffer.staker;
        apeStaked.collection = apeOffer.collection;
        apeStaked.tokenId = apeOffer.tokenId;
        apeStaked.coinAmount = apeOffer.coinAmount;
        apeStaked.share = apeOffer.share;
    }

    function toStaked(BakcOffer memory bakcOffer) internal pure returns (BakcStaked memory bakcStaked) {
        bakcStaked.offerHash = hash(bakcOffer);
        bakcStaked.staker = bakcOffer.staker;
        bakcStaked.tokenId = bakcOffer.tokenId;
        bakcStaked.coinAmount = bakcOffer.coinAmount;
        bakcStaked.share = bakcOffer.share;
    }

    function toStaked(CoinOffer memory coinOffer) internal pure returns (CoinStaked memory coinStaked) {
        coinStaked.offerHash = hash(coinOffer);
        coinStaked.staker = coinOffer.staker;
        coinStaked.coinAmount = coinOffer.coinAmount;
        coinStaked.share = coinOffer.share;
    }
}
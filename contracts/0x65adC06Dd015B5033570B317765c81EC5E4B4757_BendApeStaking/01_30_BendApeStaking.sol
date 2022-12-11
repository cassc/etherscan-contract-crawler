// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SignatureCheckerUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {IBNFT, IERC721Upgradeable} from "./interfaces/IBNFT.sol";
import {IBendApeStaking, DataTypes} from "./interfaces/IBendApeStaking.sol";
import {IStakeManager} from "./interfaces/IStakeManager.sol";
import {ILendPoolAddressesProvider, ILendPool, ILendPoolLoan} from "./interfaces/ILendPoolAddressesProvider.sol";
import {PercentageMath} from "./libraries/PercentageMath.sol";

contract BendApeStaking is IBendApeStaking, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using DataTypes for DataTypes.ApeOffer;
    using DataTypes for DataTypes.BakcOffer;
    using DataTypes for DataTypes.CoinOffer;

    string public constant NAME = "BendApeStaking";
    string public constant VERSION = "1";

    uint256 private _CACHED_CHAIN_ID;
    address private _CACHED_THIS;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private _TYPE_HASH;

    IStakeManager public stakeManager;
    ILendPoolAddressesProvider public lendPoolAddressedProvider;
    IBNFT public boundBayc;
    IBNFT public boundMayc;
    IERC721Upgradeable public bayc;
    IERC721Upgradeable public mayc;
    IERC721Upgradeable public bakc;
    IERC20Upgradeable public apeCoin;

    mapping(address => mapping(uint256 => bool)) private _isCancelled;

    function initialize(
        address bayc_,
        address mayc_,
        address bakc_,
        address boundBayc_,
        address boundMayc_,
        address apeCoin_,
        address stakeManager_,
        address lendPoolAddressedProvider_
    ) external initializer {
        __ReentrancyGuard_init();

        bayc = IERC721Upgradeable(bayc_);
        mayc = IERC721Upgradeable(mayc_);
        bakc = IERC721Upgradeable(bakc_);
        boundBayc = IBNFT(boundBayc_);
        boundMayc = IBNFT(boundMayc_);
        apeCoin = IERC20Upgradeable(apeCoin_);
        stakeManager = IStakeManager(stakeManager_);
        lendPoolAddressedProvider = ILendPoolAddressesProvider(lendPoolAddressedProvider_);

        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_THIS = address(this);

        _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = keccak256(bytes(NAME));
        _HASHED_VERSION = keccak256(bytes(VERSION));
        DOMAIN_SEPARATOR = _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
    }

    function cancelOffers(uint256[] calldata offerNonces) external override nonReentrant {
        require(offerNonces.length > 0, "Cancel: can not be empty");

        for (uint256 i = 0; i < offerNonces.length; i++) {
            _isCancelled[msg.sender][offerNonces[i]] = true;
        }

        emit OffersCanceled(msg.sender, offerNonces);
    }

    function isCancelled(address user, uint256 offerNonce) external view returns (bool) {
        return _isCancelled[user][offerNonce];
    }

    function matchWithBakcAndCoin(
        DataTypes.ApeOffer calldata apeOffer,
        DataTypes.BakcOffer calldata bakcOffer,
        DataTypes.CoinOffer calldata coinOffer
    ) external override nonReentrant {
        _validateApeOffer(apeOffer);
        _validateBakcOffer(bakcOffer);
        _validateCoinOffer(coinOffer);

        // check pool id
        require(
            apeOffer.poolId == DataTypes.BAKC_POOL_ID && coinOffer.poolId == DataTypes.BAKC_POOL_ID,
            "Offer: invalid pool id"
        );

        // check offerees
        if (apeOffer.bakcOfferee != address(0)) {
            require(apeOffer.bakcOfferee == bakcOffer.staker, "ApeOffer: bakc offeree mismatch");
        }

        if (apeOffer.coinOfferee != address(0)) {
            require(apeOffer.coinOfferee == coinOffer.staker, "ApeOffer: coin offeree mismatch");
        }
        if (bakcOffer.apeOfferee != address(0)) {
            require(bakcOffer.apeOfferee == apeOffer.staker, "BakcOffer: ape offeree mismatch");
        }
        if (bakcOffer.coinOfferee != address(0)) {
            require(bakcOffer.coinOfferee == coinOffer.staker, "BakcOffer: coin offeree mismatch");
        }
        if (coinOffer.apeOfferee != address(0)) {
            require(coinOffer.apeOfferee == apeOffer.staker, "CoinOffer: ape offeree mismatch");
        }
        if (coinOffer.bakcOfferee != address(0)) {
            require(coinOffer.bakcOfferee == bakcOffer.staker, "CoinOffer: bakc offeree mismatch");
        }

        // check shares
        require(
            apeOffer.share + bakcOffer.share + coinOffer.share == PercentageMath.PERCENTAGE_FACTOR,
            "Offer: share total amount invalid"
        );

        // check ape coin cap
        require(
            apeOffer.minCoinCap == bakcOffer.minCoinCap && apeOffer.minCoinCap == coinOffer.minCoinCap,
            "Offer: min coin cap mismatch"
        );
        require(apeOffer.minCoinCap >= 1e18, "Offer: min coin cap can't less the 1e18");
        require(
            apeOffer.coinAmount + bakcOffer.coinAmount + coinOffer.coinAmount >= apeOffer.minCoinCap,
            "Offer: ape coin cap insufficient"
        );
        require(
            apeOffer.coinAmount + bakcOffer.coinAmount + coinOffer.coinAmount <=
                stakeManager.getCurrentApeCoinCap(DataTypes.BAKC_POOL_ID),
            "Offer: ape coin cap overflow"
        );

        _stake(apeOffer.toStaked(), bakcOffer.toStaked(), coinOffer.toStaked());
    }

    function matchWithBakc(DataTypes.ApeOffer calldata apeOffer, DataTypes.BakcOffer calldata bakcOffer)
        external
        override
        nonReentrant
    {
        _validateApeOffer(apeOffer);
        _validateBakcOffer(bakcOffer);

        // check pool id
        require(apeOffer.poolId == DataTypes.BAKC_POOL_ID, "Offer: invalid pool id");

        // check offerees
        if (apeOffer.bakcOfferee != address(0)) {
            require(apeOffer.bakcOfferee == bakcOffer.staker, "ApeOffer: bakc offeree mismatch");
        }
        if (bakcOffer.apeOfferee != address(0)) {
            require(bakcOffer.apeOfferee == apeOffer.staker, "BakcOffer: ape offeree mismatch");
        }

        // check shares
        require(
            apeOffer.share + bakcOffer.share == PercentageMath.PERCENTAGE_FACTOR,
            "Offer: share total amount invalid"
        );

        // check ape coin cap
        require(apeOffer.minCoinCap == bakcOffer.minCoinCap, "Offer: min coin cap mismatch");
        require(apeOffer.minCoinCap >= 1e18, "Offer: min coin cap can't less the 1e18");
        require(apeOffer.coinAmount + bakcOffer.coinAmount >= apeOffer.minCoinCap, "Offer: ape coin cap insufficient");
        require(
            apeOffer.coinAmount + bakcOffer.coinAmount <= stakeManager.getCurrentApeCoinCap(DataTypes.BAKC_POOL_ID),
            "Offer: ape coin cap overflow"
        );

        DataTypes.CoinStaked memory emptyCoinStaked;
        _stake(apeOffer.toStaked(), bakcOffer.toStaked(), emptyCoinStaked);
    }

    function matchWithCoin(DataTypes.ApeOffer calldata apeOffer, DataTypes.CoinOffer calldata coinOffer)
        external
        override
        nonReentrant
    {
        _validateApeOffer(apeOffer);
        _validateCoinOffer(coinOffer);

        // check pool id
        require(
            apeOffer.poolId == DataTypes.BAYC_POOL_ID || apeOffer.poolId == DataTypes.MAYC_POOL_ID,
            "ApeOffer: invalid pool id"
        );
        require(
            coinOffer.poolId == DataTypes.BAYC_POOL_ID || coinOffer.poolId == DataTypes.MAYC_POOL_ID,
            "CoinOffer: invalid pool id"
        );
        require(apeOffer.poolId == coinOffer.poolId, "Offer: pool id mismatch");

        // check offerees
        if (apeOffer.coinOfferee != address(0)) {
            require(apeOffer.coinOfferee == coinOffer.staker, "ApeOffer: coin offeree mismatch");
        }
        if (coinOffer.apeOfferee != address(0)) {
            require(coinOffer.apeOfferee == apeOffer.staker, "CoinOffer: ape offeree mismatch");
        }

        // check shares
        require(
            apeOffer.share + coinOffer.share == PercentageMath.PERCENTAGE_FACTOR,
            "Offer: share total amount invalid"
        );

        // check ape coin cap
        uint256 maxCap = stakeManager.getCurrentApeCoinCap(DataTypes.BAYC_POOL_ID);
        if (apeOffer.collection == address(mayc)) {
            maxCap = stakeManager.getCurrentApeCoinCap(DataTypes.MAYC_POOL_ID);
        }
        require(apeOffer.minCoinCap == coinOffer.minCoinCap, "Offer: min coin cap mismatch");
        require(apeOffer.minCoinCap >= 1e18, "Offer: min coin cap can't less the 1e18");

        require(apeOffer.coinAmount + coinOffer.coinAmount >= apeOffer.minCoinCap, "Offer: ape coin cap insufficient");
        require(apeOffer.coinAmount + coinOffer.coinAmount <= maxCap, "Offer: ape coin cap overflow");

        DataTypes.BakcStaked memory emptyBakcStaked;
        _stake(apeOffer.toStaked(), emptyBakcStaked, coinOffer.toStaked());
    }

    function stakeSelf(
        address apeCollection,
        uint256 apeTokenId,
        uint256 bakcTokenId,
        uint256 apeCoinAmount
    ) external nonReentrant {
        require(apeCollection == address(bayc) || apeCollection == address(mayc), "selfStake: not ape collection");
        require(apeCoinAmount >= 1e18, "selfStake: can't stake less than 1 $APE");

        IBNFT boundApe = IBNFT(boundBayc);
        if (apeCollection == address(mayc)) {
            boundApe = IBNFT(boundMayc);
        }

        require(
            IERC721Upgradeable(apeCollection).ownerOf(apeTokenId) == msg.sender ||
                boundApe.ownerOf(apeTokenId) == msg.sender,
            "selfStake: not ape owner"
        );

        uint256 poolId;
        if (bakcTokenId != type(uint256).max) {
            poolId = DataTypes.BAKC_POOL_ID;
        } else {
            poolId = DataTypes.BAYC_POOL_ID;
            if (apeCollection == address(mayc)) {
                poolId = DataTypes.MAYC_POOL_ID;
            }
        }
        require(apeCoinAmount <= stakeManager.getCurrentApeCoinCap(poolId), "selfStake: ape coin cap overflow");
        DataTypes.ApeStaked memory apeStaked;
        {
            apeStaked.staker = msg.sender;
            apeStaked.collection = apeCollection;
            apeStaked.tokenId = apeTokenId;
            apeStaked.share = PercentageMath.PERCENTAGE_FACTOR;
            apeStaked.coinAmount = apeCoinAmount;
        }
        DataTypes.BakcStaked memory bakcStaked;
        if (bakcTokenId != type(uint256).max) {
            bakcStaked.staker = msg.sender;
            bakcStaked.tokenId = bakcTokenId;
        }
        DataTypes.CoinStaked memory coinStaked;
        _stake(apeStaked, bakcStaked, coinStaked);
    }

    function _stake(
        DataTypes.ApeStaked memory apeStaked,
        DataTypes.BakcStaked memory bakcStaked,
        DataTypes.CoinStaked memory coinStaked
    ) internal {
        IERC721Upgradeable ape = IERC721Upgradeable(apeStaked.collection);

        if (ape.ownerOf(apeStaked.tokenId) == apeStaked.staker) {
            ape.safeTransferFrom(apeStaked.staker, address(stakeManager), apeStaked.tokenId);
        }

        if (apeStaked.coinAmount > 0) {
            apeCoin.safeTransferFrom(apeStaked.staker, address(stakeManager), apeStaked.coinAmount);
        }

        if (bakcStaked.staker != address(0)) {
            bakc.safeTransferFrom(bakcStaked.staker, address(stakeManager), bakcStaked.tokenId);
            if (bakcStaked.coinAmount > 0) {
                apeCoin.safeTransferFrom(bakcStaked.staker, address(stakeManager), bakcStaked.coinAmount);
            }
        }

        if (coinStaked.staker != address(0) && coinStaked.coinAmount > 0) {
            apeCoin.safeTransferFrom(coinStaked.staker, address(stakeManager), coinStaked.coinAmount);
        }

        stakeManager.stake(apeStaked, bakcStaked, coinStaked);
    }

    function _validateApeOffer(DataTypes.ApeOffer memory apeOffer) internal view {
        require(apeOffer.staker != address(0), "Offer: invalid ape staker");
        require(apeOffer.startTime <= block.timestamp, "Offer: ape offer not start");
        require(apeOffer.endTime >= block.timestamp, "Offer: ape offer expired");
        require(_validateOfferNonce(apeOffer.staker, apeOffer.nonce), "Offer: invalid ape offer nonce");

        require(
            apeOffer.collection == address(bayc) || apeOffer.collection == address(mayc),
            "Offer: not ape collection"
        );

        IBNFT boundApe = IBNFT(boundBayc);
        if (apeOffer.collection == address(mayc)) {
            boundApe = IBNFT(boundMayc);
        }

        // should be ape or bound ape owner
        require(
            IERC721Upgradeable(apeOffer.collection).ownerOf(apeOffer.tokenId) == apeOffer.staker ||
                boundApe.ownerOf(apeOffer.tokenId) == apeOffer.staker,
            "Offer: not ape owner"
        );

        require(
            _validateOfferSignature(apeOffer.staker, apeOffer.hash(), apeOffer.r, apeOffer.s, apeOffer.v),
            "Offer: invalid ape offer signature"
        );
    }

    function _validateBakcOffer(DataTypes.BakcOffer memory bakcOffer) internal view {
        require(bakcOffer.staker != address(0), "Offer: invalid bakc staker");
        require(bakcOffer.startTime <= block.timestamp, "Offer: bakc offer not start");
        require(bakcOffer.endTime >= block.timestamp, "Offer: bakc offer expired");
        require(_validateOfferNonce(bakcOffer.staker, bakcOffer.nonce), "Offer: invalid bakc offer nonce");

        require(IERC721Upgradeable(bakc).ownerOf(bakcOffer.tokenId) == bakcOffer.staker, "Offer: not bakc owner");

        require(
            _validateOfferSignature(bakcOffer.staker, bakcOffer.hash(), bakcOffer.r, bakcOffer.s, bakcOffer.v),
            "Offer: invalid bakc offer signature"
        );
    }

    function _validateCoinOffer(DataTypes.CoinOffer memory coinOffer) internal view {
        require(coinOffer.staker != address(0), "Offer: invalid coin staker");
        require(coinOffer.startTime <= block.timestamp, "Offer: coin offer not start");
        require(coinOffer.endTime >= block.timestamp, "Offer: coin offer expired");
        require(coinOffer.coinAmount > 0, "Offer: coin amount can't be 0");
        require(_validateOfferNonce(coinOffer.staker, coinOffer.nonce), "Offer: invalid coin offer nonce");
        require(
            _validateOfferSignature(coinOffer.staker, coinOffer.hash(), coinOffer.r, coinOffer.s, coinOffer.v),
            "Offer: invalid coin offer signature"
        );
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    function _validateOfferNonce(address offeror, uint256 nonce) internal view returns (bool) {
        if (msg.sender == offeror) {
            return true;
        }
        return !_isCancelled[offeror][nonce];
    }

    function _validateOfferSignature(
        address signer,
        bytes32 offerHash,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal view returns (bool) {
        if (msg.sender == signer) {
            return true;
        }
        return
            SignatureCheckerUpgradeable.isValidSignatureNow(
                signer,
                ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), offerHash),
                abi.encodePacked(r, s, v)
            );
    }
}
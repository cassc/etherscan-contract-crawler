// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {PortalLib} from "src/PortalLib.sol";
import {SingleRanking} from "src/lib/SingleRanking.sol";
import {BitMapsUpgradeable} from "../oz/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

interface IRebornDefination {
    struct InnateParams {
        uint256 talentNativePrice;
        uint256 talentRebornPrice;
        uint256 propertyNativePrice;
        uint256 propertyRebornPrice;
    }

    struct SoupParams {
        uint256 soupPrice;
        uint256 charTokenId;
        uint256 deadline;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct PermitParams {
        uint256 amount;
        uint256 deadline;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct LifeDetail {
        bytes32 seed;
        address creator; // ---
        // uint96 max 7*10^28  7*10^10 eth  //   |
        uint96 reward; // ---
        uint96 rebornCost; // ---
        uint16 age; //   |
        uint32 round; //   |
        // uint64 max 1.8*10^19             //   |
        uint64 score; //   |
        uint48 nativeCost; // only with dicimal of 10^6 // ---
        string creatorName;
    }

    struct SeasonData {
        mapping(uint256 => PortalLib.Pool) pools;
        /// @dev user address => pool tokenId => Portfolio
        mapping(address => mapping(uint256 => PortalLib.Portfolio)) portfolios;
        SingleRanking.Data _tributeRank;
        SingleRanking.Data _scoreRank;
        mapping(uint256 => uint256) _oldStakeAmounts;
        /// tokenId => bool
        BitMapsUpgradeable.BitMap _isTopHundredScore;
        // the value of minimum score
        uint256 _minScore;
        // jackpot of this season
        uint256 _jackpot;
    }

    enum AirdropVrfType {
        Invalid,
        DropReborn,
        DropNative
    }

    enum TributeDirection {
        Reverse,
        Forward
    }

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        bool executed; // whether the airdrop is executed
        AirdropVrfType t;
        uint256 randomWords; // we only need one random word. keccak256 to generate more
    }

    enum BaptiseType {
        Invalid,
        TwitterShare,
        Airdrop
    }

    event Incarnate(
        address indexed user,
        uint256 indexed charTokenId,
        uint256 talentNativePrice,
        uint256 talentRebornPrice,
        uint256 propertyNativePrice,
        uint256 propertyRebornPrice,
        uint256 soupPrice
    );

    event Engrave(
        bytes32 indexed seed,
        address indexed user,
        uint256 indexed tokenId,
        uint256 score,
        uint256 reward
    );

    event Infuse(
        address indexed user,
        uint256 indexed tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    );

    event Dry(address indexed user, uint256 indexed tokenId, uint256 amount);

    event Baptise(
        address indexed user,
        uint256 amount,
        uint256 indexed baptiseType
    );

    event NewSoupPrice(uint256 price);

    event DecreaseFromPool(
        address indexed account,
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    );

    event IncreaseToPool(
        address indexed account,
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    );

    event Drop(uint256[] tokenIds);

    /// @dev event about the vault address is set
    event VaultSet(address rewardVault);

    event NewSeason(uint256);

    event NewIncarnationLimit(uint256 limit);

    event ForgedTo(
        uint256 indexed tokenId,
        uint256 newLevel,
        uint256 burnTokenAmount
    );

    event SetNewPiggyBank(address piggyBank);

    event SetNewPiggyBankFee(uint256 piggyBankFee);

    /// @dev revert when msg.value is insufficient
    error InsufficientAmount();

    /// @dev revert when some address var are set to zero
    error ZeroAddressSet();

    /// @dev revert when the random seed is duplicated
    error SameSeed();

    /// @dev revert if burnPool address not set when infuse
    error NotSetBurnPoolAddress();

    /// @dev revert when the drop is not on
    error DropOff();

    /// @dev revert when incarnation count exceed limit
    error IncarnationExceedLimit();

    error DirectionError();

    error DropLocked();
}

interface IRebornPortal is IRebornDefination {
    /**
     * @dev user buy the innate for the life
     * @param innate talent and property choice
     * @param referrer the referrer address
     */
    function incarnate(
        InnateParams calldata innate,
        address referrer,
        SoupParams calldata charParams
    ) external payable;

    function incarnate(
        InnateParams calldata innate,
        address referrer,
        SoupParams calldata charParams,
        PermitParams calldata permitParams
    ) external payable;

    /**
     * @dev engrave the result on chain and reward
     * @param seed random seed in bytes32
     * @param user user address
     * @param lifeReward $REBORN user earns, decimal 10^18
     * @param boostReward $REBORN user earns with degen2009 boost
     * @param score life score
     * @param rebornCost user cost reborn token for this life
     * @param nativeCost user cost native token for this life
     */
    function engrave(
        bytes32 seed,
        address user,
        uint256 lifeReward,
        uint256 boostReward,
        uint256 score,
        uint256 age,
        uint256 rebornCost,
        uint256 nativeCost,
        string calldata creatorName
    ) external;

    /**
     * @dev reward for share the game
     * @param user user address
     * @param amount amount for reward
     */
    function baptise(
        address user,
        uint256 amount,
        uint256 baptiseType
    ) external;

    /**
     * @dev stake $REBORN on this tombstone
     * @param tokenId tokenId of the life to stake
     * @param amount stake amount, decimal 10^18
     */
    function infuse(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    ) external;

    /**
     * @dev stake $REBORN with permit
     * @param tokenId tokenId of the life to stake
     * @param amount amount of $REBORN to stake
     * @param permitAmount amount of $REBORN to approve
     * @param r r of signature
     * @param s v of signature
     * @param v v of signature
     */
    function infuse(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection,
        uint256 permitAmount,
        uint256 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external;

    /**
     * @dev switch stake amount from poolFrom to poolTo
     * @param fromTokenId tokenId of from pool
     * @param toTokenId tokenId of to pool
     * @param amount amount to switch
     */
    function switchPool(
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 amount,
        TributeDirection tributeDirection
    ) external;

    /**
     * @dev set new airdrop config
     */
    function setDropConf(PortalLib.AirdropConf calldata conf) external;

    /**
     * @dev set new chainlink vrf v2 config
     */
    function setVrfConf(PortalLib.VrfConf calldata conf) external;

    /**
     * @dev user claim many pools' native token airdrop
     * @param tokenIds pools' tokenId array to claim
     */
    function claimNativeDrops(uint256[] calldata tokenIds) external;

    /**
     * @dev user claim many pools' reborn token airdrop
     * @param tokenIds pools' tokenId array to claim
     */
    function claimRebornDrops(uint256[] calldata tokenIds) external;

    /**
     * @dev switch to next season, call by owner
     */
    function toNextSeason() external;
}
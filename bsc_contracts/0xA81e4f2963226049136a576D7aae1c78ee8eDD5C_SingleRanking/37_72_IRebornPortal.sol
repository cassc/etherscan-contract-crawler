// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {PortalLib} from "src/PortalLib.sol";
import {SingleRanking} from "src/lib/SingleRanking.sol";
import {BitMapsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

interface IRebornDefination {
    struct Innate {
        uint256 talentPrice;
        uint256 propertyPrice;
    }

    struct LifeDetail {
        bytes32 seed;
        address creator;
        uint16 age;
        uint32 round;
        uint48 nothing;
        uint128 cost;
        uint128 reward;
        uint256 score;
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

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        bool executed; // whether the airdrop is executed
        AirdropVrfType t;
        uint256[] randomWords;
    }

    event Incarnate(
        address indexed user,
        uint256 indexed talentPrice,
        uint256 indexed PropertyPrice,
        uint256 soupPrice
    );

    event Engrave(
        bytes32 indexed seed,
        address indexed user,
        uint256 indexed tokenId,
        uint256 score,
        uint256 reward
    );

    event Infuse(address indexed user, uint256 indexed tokenId, uint256 amount);

    event Dry(address indexed user, uint256 indexed tokenId, uint256 amount);

    event Baptise(address indexed user, uint256 amount);

    event NewSoupPrice(uint256 price);

    event Refer(address referee, address referrer);

    event DecreaseFromPool(
        address indexed account,
        uint256 tokenId,
        uint256 amount
    );

    event IncreaseToPool(
        address indexed account,
        uint256 tokenId,
        uint256 amount
    );

    event Drop(uint256[] tokenIds);

    /// @dev event about the vault address is set
    event VaultSet(address rewardVault);

    event NewSeason(uint256);

    event NewExtraReward(uint256 extraReward);

    event BetaStageSet(bool);

    event NewIncarnationLimit(uint256 limit);

    /// @dev revert when msg.value is insufficient
    error InsufficientAmount();
    /// @dev revert when to caller is not signer
    error NotSigner();

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
}

interface IRebornPortal is IRebornDefination {
    /**
     * @dev user buy the innate for the life
     * @param innate talent and property choice
     * @param referrer the referrer address
     */
    function incarnate(
        Innate memory innate,
        address referrer,
        uint256 soupPrice
    ) external payable;

    /**
     * @dev engrave the result on chain and reward
     * @param seed random seed in bytes32
     * @param user user address
     * @param reward $REBORN user earns, decimal 10^18
     * @param score life score
     * @param cost user cost for this life
     */
    function engrave(
        bytes32 seed,
        address user,
        uint256 reward,
        uint256 score,
        uint256 age,
        uint256 cost,
        string calldata creatorName
    ) external;

    /**
     * @dev reward for share the game
     * @param user user address
     * @param amount amount for reward
     */
    function baptise(address user, uint256 amount) external;

    /**
     * @dev stake $REBORN on this tombstone
     * @param tokenId tokenId of the life to stake
     * @param amount stake amount, decimal 10^18
     */
    function infuse(uint256 tokenId, uint256 amount) external;

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
        uint256 amount
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
     * @dev user claim many pools' airdrop
     * @param tokenIds pools' tokenId array to claim
     */
    function claimDrops(uint256[] calldata tokenIds) external;

    /**
     * @dev switch to next season, call by owner
     */
    function toNextSeason() external;
}
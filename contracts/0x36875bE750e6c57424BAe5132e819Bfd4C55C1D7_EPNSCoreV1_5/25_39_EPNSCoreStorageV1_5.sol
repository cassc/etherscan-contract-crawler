pragma solidity >=0.6.0 <0.7.0;

contract EPNSCoreStorageV1_5 {
    /* ***************

  DEFINE ENUMS AND CONSTANTS

 *************** */

    // For Message Type
    enum ChannelType {
        ProtocolNonInterest,
        ProtocolPromotion,
        InterestBearingOpen,
        InterestBearingMutual,
        TimeBound,
        TokenGaited
    }
    enum ChannelAction {
        ChannelRemoved,
        ChannelAdded,
        ChannelUpdated
    }

    /**
     * @notice Channel Struct that includes imperative details about a specific Channel.
     **/
    struct Channel {
        // @notice Denotes the Channel Type
        ChannelType channelType;
        /** @notice Symbolizes Channel's State:
         * 0 -> INACTIVE,
         * 1 -> ACTIVATED
         * 2 -> DeActivated By Channel Owner,
         * 3 -> BLOCKED by pushChannelAdmin/Governance
         **/
        uint8 channelState;
        // @notice denotes the address of the verifier of the Channel
        address verifiedBy;
        // @notice Total Amount of Dai deposited during Channel Creation
        uint256 poolContribution;
        // @notice Represents the Historical Constant
        uint256 channelHistoricalZ;
        // @notice Represents the FS Count
        uint256 channelFairShareCount;
        // @notice The last update block number, used to calculate fair share
        uint256 channelLastUpdate;
        // @notice Helps in defining when channel started for pool and profit calculation
        uint256 channelStartBlock;
        // @notice Helps in outlining when channel was updated
        uint256 channelUpdateBlock;
        // @notice The individual weight to be applied as per pool contribution
        uint256 channelWeight;
        // @notice The Expiry TimeStamp in case of TimeBound Channel Types
        uint256 expiryTime;
    }

    /* ***************
    MAPPINGS
 *************** */

    mapping(address => Channel) public channels;
    mapping(uint256 => address) public channelById;
    mapping(address => string) public channelNotifSettings;

    /* ***************
    STATE VARIABLES
 *************** */
    string public constant name = "EPNS_CORE_V2";
    bool oneTimeCheck;
    bool public isMigrationComplete;

    address public pushChannelAdmin;
    address public governance;
    address public daiAddress;
    address public aDaiAddress;
    address public WETH_ADDRESS;
    address public epnsCommunicator;
    address public UNISWAP_V2_ROUTER;
    address public PUSH_TOKEN_ADDRESS;
    address public lendingPoolProviderAddress;

    uint256 public REFERRAL_CODE;
    uint256 ADJUST_FOR_FLOAT;
    uint256 public channelsCount;

    //  @notice Helper Variables for FSRatio Calculation | GROUPS = CHANNELS
    uint256 public groupNormalizedWeight;
    uint256 public groupHistoricalZ;
    uint256 public groupLastUpdate;
    uint256 public groupFairShareCount;

    // @notice Necessary variables for Keeping track of Funds and Fees
    uint256 public CHANNEL_POOL_FUNDS;
    uint256 public PROTOCOL_POOL_FEES;
    uint256 public ADD_CHANNEL_MIN_FEES;
    uint256 public FEE_AMOUNT;
    uint256 public MIN_POOL_CONTRIBUTION;
}
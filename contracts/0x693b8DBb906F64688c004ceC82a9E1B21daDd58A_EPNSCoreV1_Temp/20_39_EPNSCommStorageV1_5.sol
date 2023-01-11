pragma solidity >=0.6.0 <0.7.0;

contract EPNSCommStorageV1_5 {
    /**
     * @notice User Struct that involves imperative details about
     * a specific User.
     **/
    struct User {
        // @notice Depicts whether or not a user is ACTIVE
        bool userActivated;
        // @notice Will be false until public key is emitted
        bool publicKeyRegistered;
        // @notice Events should not be polled before this block as user doesn't exist
        uint256 userStartBlock;
        // @notice Keep track of subscribers
        uint256 subscribedCount;
        /**
         * Depicts if User subscribed to a Specific Channel Address
         * 1 -> User is Subscribed
         * 0 -> User is NOT SUBSCRIBED
         **/
        mapping(address => uint8) isSubscribed;
        // Keeps track of all subscribed channels
        mapping(address => uint256) subscribed;
        mapping(uint256 => address) mapAddressSubscribed;
    }

    /** MAPPINGS **/
    mapping(address => User) public users;
    mapping(address => uint256) public nonces;
    mapping(uint256 => address) public mapAddressUsers;
    mapping(address => mapping(address => string)) public userToChannelNotifs;
    mapping(address => mapping(address => bool))
        public delegatedNotificationSenders;

    /** STATE VARIABLES **/
    address public governance;
    address public pushChannelAdmin;
    uint256 public chainID;
    uint256 public usersCount;
    bool public isMigrationComplete;
    address public EPNSCoreAddress;
    string public chainName;
    string public constant name = "EPNS COMM V1";
    bytes32 public constant NAME_HASH = keccak256(bytes(name));
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant SUBSCRIBE_TYPEHASH =
        keccak256("Subscribe(address channel,address subscriber,uint256 nonce,uint256 expiry)");
    bytes32 public constant UNSUBSCRIBE_TYPEHASH =
        keccak256("Unsubscribe(address channel,address subscriber,uint256 nonce,uint256 expiry)");
    bytes32 public constant SEND_NOTIFICATION_TYPEHASH =
        keccak256(
            "SendNotification(address channel,address recipient,bytes identity,uint256 nonce,uint256 expiry)"
        );
}
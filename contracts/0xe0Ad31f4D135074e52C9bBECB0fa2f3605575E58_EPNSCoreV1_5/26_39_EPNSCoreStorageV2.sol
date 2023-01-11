pragma solidity >=0.6.0 <0.7.0;

contract EPNSCoreStorageV2 {
    /* *** V2 State variables *** */
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name, uint256 chainId, address verifyingContract)"
        );
    bytes32 public constant CREATE_CHANNEL_TYPEHASH =
        keccak256("CreateChannel(ChannelType channelType, bytes identity, uint256 amount, uint256 channelExpiryTime, uint256 nonce, uint256 expiry)");

    mapping(address => uint256) public nonces;
    mapping(address => uint256) public channelUpdateCounter;
    mapping(address => uint256) public usersRewardsClaimed;
}
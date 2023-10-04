pragma solidity ^0.8.9;

contract FukushimaFishData {

    error TokenNotInitiated();

    uint8 constant CELESTIAL_FLAG = 0x01;
    uint8 constant BONUS_FLAG = 0x02;

    enum AuraLevel {
        NONE, // 0
        LOW,   // 1
        MED, // 2
        HIGH, // 3
        OVERFLOWING // 4
    }


    address public owner;

    mapping(AuraLevel => uint256) auraDailyYields;

    // Uint256 encoded Token Metadata
    mapping(uint256 => uint256) _metadata;
    
    mapping(address => bool) _admin;

    // // 0.054 $AURA / day
    // uint256 constant NONE = 0.054 ether;

    // // 0.304 $AURA / day
    // uint256 constant LOW = 0.304 ether;

    // // 0.75 $AURA / day
    // uint256 constant MED = 0.75 ether;

    // // 3 $AURA / day
    // uint256 constant HIGH = 3 ether;

    // // 10 $AURA / day
    // uint256 constant OVERFLOWING = 10 ether;

    // // 20 $AURA / day
    uint256 public BONUS = 20 ether;

    constructor() {
        auraDailyYields[AuraLevel.NONE] = 0.054 ether;
        auraDailyYields[AuraLevel.LOW] = 0.304 ether;
        auraDailyYields[AuraLevel.MED] = 0.75 ether;
        auraDailyYields[AuraLevel.HIGH] = 3 ether;
        auraDailyYields[AuraLevel.OVERFLOWING] = 10 ether; 

        owner = msg.sender;
        _admin[msg.sender] = true;
    }

    function hasFlag(uint256 flags, uint256 flag) internal pure returns(bool) {
        return (flags & flag) != 0;
    }


    modifier onlyAdmin() {
        require(_admin[msg.sender]);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address to) external onlyOwner {
        owner = to;
    }

    function setAdmin(address addr, bool status) external onlyOwner {
        _admin[addr] = status;
    }

    function setBonus(uint256 bonusAmount) external onlyOwner {
        BONUS = bonusAmount;
    }

    /**
     * Updates a given aura level
     * 
     * @param auraLevel the level to update
     * @param amount  the amount for the given level
     */
    function updateYield(AuraLevel auraLevel, uint256 amount) external onlyOwner {
            auraDailyYields[auraLevel] = amount;
    }

    uint256 constant REACTOR_MODIFIER = 0x01;

    bytes32 public rootHash;


    function importData(bytes32 root) external onlyAdmin {
        rootHash = root;
    }


    function isCelestial(uint256 tokenId) external view returns (bool) {
        uint256 metadata = _metadata[tokenId];
         if (metadata == 0) revert TokenNotInitiated();
         (,,uint16 flags) = decode(metadata);
         return hasFlag(flags, CELESTIAL_FLAG);
    }

    function getAuraYieldForToken(uint256 tokenId) external view returns (uint256) {
        uint256 metadata = _metadata[tokenId];
        // no token will ever be encoded as 0
        if (metadata == 0) revert TokenNotInitiated();

        (, uint16 level, uint16 flags) = decode(metadata);

        uint256 baseYield = auraDailyYields[AuraLevel(level)]; 

        if (hasFlag(flags, BONUS_FLAG)) {
            baseYield += BONUS;
        }

        return baseYield;
    }


    function decode(uint256 encoded) internal pure returns(uint16 token, uint16 level, uint16 flags) {
        token = uint16(encoded);
        level = uint16(encoded >> 16);
        flags = uint16(encoded >> 32);
    }

    function isTokenInitiated(uint256 tokenId) external view returns(bool) { 
        return _metadata[tokenId] != 0;
    }  

    function initTokenData(
        uint256 encoded,
        uint256 path,
        bytes32[] calldata proof
    ) external  {
        // validates the merkle tree
        bytes32 leaf = keccak256(abi.encode(encoded));

        for (uint256 i; i < proof.length; i++) {
            // check if the path is odd and inverse the hash
            if (path & 1 == 1) {
                leaf = keccak256(abi.encodePacked(leaf, proof[i]));
            } else {
                leaf = keccak256(abi.encodePacked(proof[i], leaf));
            }

            path /= 2;
        }
        
        require(leaf == rootHash, "invalid proof.");

        // after verifying the encoded information is legit, set it
        (uint16 tokenId,,) = decode(encoded);
        _metadata[tokenId] = encoded;
    }
}
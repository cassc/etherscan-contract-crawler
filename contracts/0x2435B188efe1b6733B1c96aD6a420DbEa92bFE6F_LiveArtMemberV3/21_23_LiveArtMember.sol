pragma solidity ^0.8.2;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

//|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\//
//|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\//
//|_/\//                                                                                        //|_/\//
//|_/\//                                                                                        //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@, @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.  %@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,  &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%     /@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,   #@@@@@@@@@@@@@@@@@@@@@@@@@@@@(       [email protected]@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,    /@@@@@@@@@@@@@@@@@@@@@@@@@@*          @@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,     ,@@@@@@@@@@@@@@@@@@@@@@@@.            &@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,       &@@@@@@@@@@@@@@@@@@@@&               (@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,        #@@@@@@@@@@@@@@@@@@(                 ,@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,         /@@@@@@@@@@@@@@@@.                    &@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,          ,@@@@@@@@@@@@@@                       %@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,            @@@@@@@@@@@@                         (@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,             #@@@@@@@@#                           *@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,              *@@@@@@*                              @@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,               [email protected]@@@.                                %@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,                 @&                                   (@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//                                                                                        //|_/\//
//|_/\//                                                                                        //|_/\//
//|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\//
//|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\//

contract LiveArtMember is OwnableUpgradeable, ERC721EnumerableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using StringsUpgradeable for uint256;

    bool internal tempRecursion;

    // Base URI
    string internal baseURI;

    struct Member {
        uint256 id;
        uint256 level;
        uint256 createdTime;
        uint256 lockTime;
        uint256 amount;
        bool decompose;
    }
    uint256 public unLockTimestamp;

    mapping(uint256 => Member) public tokenExtend;
    
    bytes32 public merkleRoot;
    
    // This is a packed array of booleans.
    mapping(uint256 => uint256) internal claimedBitMap;

    // claim start time
    uint256 public claimStartTime;

    // claim count
    mapping(uint256 => uint256) public claimCount;
    
    // total number of members
    uint256 public memberID;

    uint256[] public whitelistAmount;
    uint256[] public whitelistValue;
    uint256[] public levelProbability;
    
    uint256[] public retainMemberValue;

    IERC20Upgradeable public artToken;

    // sell start time
    uint256 public sellStartTime;

    // sell count
    mapping(uint256 => uint256) public soldCount;
    
    // self bought
    mapping(address => mapping(uint256 => bool)) public userBought;

    uint256[] public sellMemberAmount;
    uint256[] public sellMemberValue;
    uint256[] public sellMemberPrice;

    event ReceiveMember(
        address indexed owner, 
        uint256 indexed tokenId, 
        uint256 indexed level,
        uint256 lockTime,
        uint256 amount
    );

    event DecomposeMember(
        address indexed owner, 
        uint256 indexed tokenId,
        uint256 receiveAmount,
        bool retain
    );

    event eveWhitelistData(uint256 indexed startTime);
    event eveUnLockTimestamp(uint256 indexed timestamp);
    event eveSellData(uint256 indexed startTime);
    event eveSetMerkleRoot(bytes32 indexed merkleRoot);
    event eveARTToken(address indexed art);
    event eveWithdraw(uint256 indexed amount, address indexed addr);
    event eveSeize(address indexed token, address indexed addr, uint256 indexed amount);
    event eveURIPrefix(string indexed baseURI);

    // --- Init ---
      function initialize(
        
        bytes32 merkleRoot_,

        IERC20Upgradeable _artToken,

        uint256 _claimStartTime,
        
        uint256 _unLockTimestamp,

        uint256[] calldata _whitelistAmount,
        uint256[] calldata _whitelistValue,
        uint256[] calldata _levelProbability,
        uint256[] calldata _retainMemberValue
        ) external initializer {
          __Ownable_init();
          __ERC721_init("LiveArt.Memberships", "LIVEART.MEMBERSHIPS");
          __ReentrancyGuard_init();
        
        merkleRoot = merkleRoot_;

        artToken = _artToken;

        claimStartTime = _claimStartTime;
        unLockTimestamp = _unLockTimestamp;

        whitelistAmount = _whitelistAmount;
        whitelistValue = _whitelistValue;
        levelProbability = _levelProbability;
        retainMemberValue = _retainMemberValue;

        baseURI = "https://api.liveartx.com/v1/magic-box/";

        emit eveUnLockTimestamp(_unLockTimestamp);
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public nonReentrant virtual returns (uint256) {
        require(!AddressUpgradeable.isContract(msg.sender), "LiveArtMember: can't call");
        require(block.timestamp >= claimStartTime, "LiveArtMember: not start");
        // Verify the merkle proof. whitelists
        address account = msg.sender;
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProofUpgradeable.verify(merkleProof, merkleRoot, node), 'LiveArtMember: not whitelist');

        require(!isClaimed(index), 'LiveArtMember: already claimed.');

        memberID++;
        
        _mint(account, memberID);
    
        _setClaimed(index);

        uint256 lockTime = getLockTime();
        
        // level
        uint256 seed = computerSeed();
        uint256 _base = 1000;
        uint256 levelRandom = seed%_base;
        uint256 level = getLevel(levelRandom);
        
        claimCount[level]++;

        Member memory member;
        member.id = memberID;
        member.level = level;
        member.createdTime =  block.timestamp;
        member.lockTime = lockTime;
        member.amount = whitelistValue[level - 1];
        member.decompose = false;

        tokenExtend[memberID] = member;

        emit ReceiveMember(account, memberID, level, lockTime, member.amount);

        return memberID;
    }

    function buy(uint256 _level) external nonReentrant payable returns (uint256){
        require(!AddressUpgradeable.isContract(msg.sender), "LiveArtMember: can't call");
        require(_level > 0 && _level < 7, "LiveArtMember: level error");
        uint256 index = _level.sub(1);
        uint256 price = sellMemberPrice[index];
        address addr = msg.sender;
        require(block.timestamp >= sellStartTime, "LiveArtMember: not start");
        require(soldCount[index] < sellMemberAmount[index], "LiveArtMember: sold out");
        require(msg.value == price, "LiveArtMember: value error");
        require(userBought[addr][index] == false, "LiveArtMember: have bought");
        
        soldCount[index]++;
        userBought[addr][index] = true;

        memberID++;
        
        _mint(addr, memberID);

        uint256 lockTime = getLockTime();
        Member memory member;
        member.id = memberID;
        member.level = _level;
        member.createdTime = block.timestamp;
        member.lockTime = lockTime;
        member.amount = sellMemberValue[index];
        member.decompose = false;

        tokenExtend[memberID] = member;

        emit ReceiveMember(addr, memberID, _level, lockTime, member.amount);
        return memberID;
    }
    
    // _retain: 
    //  true => Retain membership
    //  false => burn
    function decomposeMember(uint256 tokenId, bool _retain) external nonReentrant {
        require(_exists(tokenId), "LiveArtMember: operator query for nonexistent token");
        Member storage member = tokenExtend[tokenId];
        uint256 lockTime = member.lockTime;
        require(block.timestamp >= lockTime.add(unLockTimestamp), "LiveArtMember: Lock");
        require(!member.decompose, "LiveArtMember: has decompose");

        uint256 amount_ = member.amount;
        require(ownerOf(tokenId) == msg.sender, "LiveArtMember: not owner");

        if (_retain) {
            uint256 retainValue = retainMemberValue[member.level-1];    
            member.amount = retainValue;
            member.decompose = true;
            amount_ = amount_.sub(retainValue);

        } else {
            _burn(tokenId);
        }
        artToken.safeTransfer(msg.sender, amount_);

        emit DecomposeMember(
            msg.sender, 
            tokenId,
            amount_,
            _retain
        );
    }

    function getLockTime() internal view returns (uint256){
        // random
        uint256 seed = computerSeed();
        uint256 _yearTime = 365;
        uint256 lockDays = seed%_yearTime; 
        uint256 lockTime = lockDays.mul(1 days).add(1 days);

        return lockTime;
    }

    function getLevel(uint256 v) internal returns (uint256){
        
        uint256 level = 1;
        for (uint256 index = 0; index < levelProbability.length; index++) {
            if (v <= levelProbability[index]) {
                level = index + 1;
                break;
            }
        }
        tempRecursion = false;
        return getCurrentLevel(level);
    }
    
    function getCurrentLevel(uint256 level) internal returns (uint256) {
        require(level > 0, "LiveArtMember: level over");
        require(level < 7, "LiveArtMember: have over");
        uint256 currentLevel = level;
        uint256 claimCount_ = claimCount[currentLevel];
        uint256 amount_ = whitelistAmount[currentLevel-1];
        if (claimCount_ < amount_) {
            return currentLevel;
        } else {
            if (currentLevel > 1 && tempRecursion == false) {
                currentLevel--;
            } else {
                tempRecursion = true;
                currentLevel++;
            }
            return getCurrentLevel(currentLevel);
        }
    }

    function computerSeed() internal view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            (block.timestamp) +
            (block.difficulty) +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            (block.gaslimit)+
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            (block.number)
            
        )));
        return seed;
    }

    function setWhitelistData(
        uint256 _claimStartTime,
        uint256[] calldata _whitelistAmount,
        uint256[] calldata _whitelistValue,  
        uint256[] calldata _levelProbability                       
    ) external onlyOwner {
        
        claimStartTime = _claimStartTime;
        whitelistAmount = _whitelistAmount;
        whitelistValue = _whitelistValue;
        levelProbability = _levelProbability;
        emit eveWhitelistData(_claimStartTime);
    }

    function setUnLockTimestamp(
        uint256 _unLockTimestamp
    ) external onlyOwner {
        unLockTimestamp = _unLockTimestamp;

        emit eveUnLockTimestamp(_unLockTimestamp);
    }

    function setSellData(
        uint256 _sellStartTime,
        uint256[] calldata _sellMemberAmount,
        uint256[] calldata _sellMemberValue,
        uint256[] calldata _sellMemberPrice
    ) external onlyOwner {
        sellStartTime = _sellStartTime;
        sellMemberAmount = _sellMemberAmount;
        sellMemberValue = _sellMemberValue;
        sellMemberPrice = _sellMemberPrice;

        emit eveSellData(_sellStartTime);
    }
    
    function setRetainValue(
        uint256[] calldata _retainMemberValue
    ) external onlyOwner {
        retainMemberValue = _retainMemberValue;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
        emit eveSetMerkleRoot(merkleRoot_);
    }

    function setARTToken(IERC20Upgradeable _artToken) external onlyOwner {
        artToken = _artToken;

        emit eveARTToken(address(artToken));
    }
    
    function withdraw(uint256 amount, address payable addr) external onlyOwner {
        addr.transfer(amount);

        emit eveWithdraw(amount, addr);
    }

    function seize(IERC20Upgradeable token, address addr, uint256 amount) external onlyOwner {
        token.safeTransfer(addr, amount);
        emit eveSeize(address(token), addr, amount);
    }

    function setURIPrefix(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit eveURIPrefix(baseURI);
    }

    fallback() external {}
    
    receive() payable external {}
    
    function getMember(uint256 tokenId)
        external view
        returns (
            uint256 level,
            uint256 createdTime,
            uint256 lockTime,
            uint256 amount,
            bool decompose
        )
    {
        require(_exists(tokenId), "LiveArtMember: operator query for nonexistent token");
        Member memory member = tokenExtend[tokenId];
        require(member.id > 0, "LiveArtMember: nonexistent token");
        
        level = member.level;
        createdTime = member.createdTime;
        lockTime = member.lockTime;
        amount = member.amount;
        decompose = member.decompose;
    }

     /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return "LiveArt";
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return "LiveArt.Member";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "LiveArtMember: URI query for nonexistent token");
        string memory baseURI_ = _baseURI();
        
        return string(abi.encodePacked(baseURI_, tokenId.toString()));
    }
}
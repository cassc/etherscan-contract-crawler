// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256);
}

contract LancetMembership is Ownable,Pausable,ReentrancyGuard{
    using SafeMath for uint256;

    // =========================================================================
    //                               Types
    // =========================================================================
    enum Staking48HType{
        ThirtyDays,
        SixtyDays
    }

    struct MembershipType{
        uint256 membershipDays;
        bool    onSale;
        uint256 membershipPrice;
    }

    // =========================================================================
    //                               Storage
    // =========================================================================
    IERC721 public lancetPass ;

    uint256 public staking48HStartTimestamp;
    
    uint256 private constant _24H_SEC = 1 days;

    uint256[] public membershipCategory;

    bool public stakingEnabled;

    mapping(address => uint256) public ownedToken;

    mapping(uint256 => bool) public stakingAllowed;

    mapping(uint256 => uint256) public stakingEndAt;
    mapping(uint256 => uint256) public membershipEndAt;

    mapping(uint256 => MembershipType) public membershipState;

    // =========================================================================
    //                            Constructor
    // =========================================================================
    constructor(address _lancetPassAddress){
        membershipState[30] = MembershipType(30,true,0.2 ether);
        membershipState[60] = MembershipType(60,true,0.35 ether);
        membershipState[90] = MembershipType(90,true,0.5 ether);
        membershipState[180] = MembershipType(180,true,0.6 ether);
        membershipCategory.push(30);
        membershipCategory.push(60);
        membershipCategory.push(90);
        membershipCategory.push(180);

        lancetPass = IERC721(_lancetPassAddress);
    }

    // =========================================================================
    //                               Event
    // =========================================================================
    event Staking48H(address indexed owner,uint256 indexed startTimestamp,uint256 indexed endTimestamp,uint256 tokenId);
    event MembershipPurchase(address indexed owner,uint256 indexed startTimestamp,uint256 indexed endTimestamp,uint256 tokenId);
    event Staking(address indexed owner,uint256 indexed startTimestamp,uint256 indexed endTimestamp,uint256 tokenId);
    event SetMembershipPrice(uint256 indexed membershipDays,uint256 indexed price);
    event SetMembershipState(uint256 indexed membershipDays,uint256 indexed price,bool indexed onSale);
    event StakingTokenWithdraw(address indexed owner,uint256 indexed tokenId);

    // =========================================================================
    //                               Modifier
    // =========================================================================
    modifier Staking48HOpen{
        require(block.timestamp >= staking48HStartTimestamp && block.timestamp <= staking48HStartTimestamp.add(_24H_SEC.mul(2)),"48H Staking not opened");
        _;
    }
    
    modifier Staking48HClosed{
        require(block.timestamp > staking48HStartTimestamp.add(_24H_SEC.mul(2)),"48H Staking not closed");
        _;
    }

    modifier OnlyPassOwner(uint256 tokenId){
        require(tokenId != 0);
        require(ownedToken[msg.sender] == tokenId || lancetPass.ownerOf(tokenId) == msg.sender,"Not Lancet Pass Holder");
        _;
    }

    // =========================================================================
    //                               Function
    // =========================================================================
    function staking48H(Staking48HType staking48HType,uint256 tokenId) Staking48HOpen OnlyPassOwner(tokenId) external {
        require(ownedToken[msg.sender] == 0,"Already staked");
        lancetPass.transferFrom(msg.sender,address(this),tokenId);
        ownedToken[msg.sender] = tokenId;

        uint256 startTimestamp = block.timestamp;
        uint256 endTimestamp = startTimestamp.add(convertStakingTime(staking48HType));
        membershipEndAt[tokenId] = endTimestamp;
        stakingEndAt[tokenId] = endTimestamp;
        emit Staking48H(msg.sender, startTimestamp, endTimestamp, tokenId);
    }

    function membershipPurchase(uint256 membershipDays,uint256 tokenId) Staking48HClosed OnlyPassOwner(tokenId) nonReentrant payable public{
        require(msg.value == membershipState[membershipDays].membershipPrice,"Invalid Price");
        require(membershipState[membershipDays].onSale,"Not On Sale");
        uint256 startTimestamp = block.timestamp;
        uint256 membershipEndTimestamp;
        if (membershipEndAt[tokenId] > startTimestamp){
            membershipEndTimestamp = membershipEndAt[tokenId].add(_24H_SEC.mul(membershipDays));
        }else{
            membershipEndTimestamp = startTimestamp.add(_24H_SEC.mul(membershipDays));
        }        
        membershipEndAt[tokenId] = membershipEndTimestamp;
        stakingAllowed[tokenId] = true;
        emit MembershipPurchase(msg.sender,startTimestamp,membershipEndTimestamp,tokenId);
    }

    function stakingAndMembership(uint256 membershipDays,uint256 tokenId) Staking48HClosed OnlyPassOwner(tokenId) nonReentrant payable external{
        require(stakingEnabled,"Staking Not Open");
        require(msg.value == membershipState[membershipDays].membershipPrice,"Invalid Price");
        require(membershipState[membershipDays].onSale,"Not On Sale");
        uint256 startTimestamp = block.timestamp;
        uint256 endTimestamp;
        if (membershipEndAt[tokenId] > startTimestamp){
            endTimestamp = membershipEndAt[tokenId].add(_24H_SEC.mul(membershipDays));
        }else{
            endTimestamp = startTimestamp.add(_24H_SEC.mul(membershipDays));
        }        
        membershipEndAt[tokenId] = endTimestamp;
        if (ownedToken[msg.sender] == 0){
            lancetPass.transferFrom(msg.sender,address(this),tokenId);
            ownedToken[msg.sender] = tokenId;
        }
        stakingEndAt[tokenId] = endTimestamp;
        stakingAllowed[tokenId] = false;
        emit Staking(msg.sender,startTimestamp,endTimestamp,tokenId);
        emit MembershipPurchase(msg.sender,startTimestamp,endTimestamp,tokenId);
    }
    

    function staking(uint256 stakeDuration,uint256 tokenId) Staking48HClosed OnlyPassOwner(tokenId) nonReentrant public {
        require(stakingEnabled,"Staking Not Open");
        require(stakingAllowed[tokenId],"Staking not allowed");
        uint256 startTimestamp = block.timestamp;
        require(membershipEndAt[tokenId] > startTimestamp,"Only membership can staking");
        uint256 stakeEndTimestamp;
        if (ownedToken[msg.sender] == tokenId){
            if (stakingEndAt[tokenId] > startTimestamp){
                stakeEndTimestamp = stakingEndAt[tokenId].add(stakeDuration);
            }else{
                stakeEndTimestamp = startTimestamp.add(stakeDuration);
            }
        }else if (ownedToken[msg.sender] == 0){
            stakeEndTimestamp = startTimestamp.add(stakeDuration);
            lancetPass.transferFrom(msg.sender,address(this),tokenId);
            ownedToken[msg.sender] = tokenId;
        }else{
            revert();
        }
        if (membershipEndAt[tokenId] < stakeEndTimestamp){
            stakeEndTimestamp = membershipEndAt[tokenId];
        }
        stakingEndAt[tokenId] = stakeEndTimestamp;
        stakingAllowed[tokenId] = false;
        emit Staking(msg.sender,startTimestamp,stakeEndTimestamp,tokenId);
    }


    function stakingWithEndtime(uint256 stakeEndTimestamp,uint256 tokenId) Staking48HClosed OnlyPassOwner(tokenId) nonReentrant public {
        require(stakingEnabled,"Staking Not Open");
        require(stakingAllowed[tokenId],"Staking not allowed");
        uint256 startTimestamp = block.timestamp;
        require(membershipEndAt[tokenId] > startTimestamp,"Only membership can staking");

        if (ownedToken[msg.sender] == 0){
            lancetPass.transferFrom(msg.sender,address(this),tokenId);
            ownedToken[msg.sender] = tokenId;
        }
        if (membershipEndAt[tokenId] < stakeEndTimestamp){
            stakingEndAt[tokenId] = membershipEndAt[tokenId];
        }else{
            stakingEndAt[tokenId] = stakeEndTimestamp;
        }
        stakingAllowed[tokenId] = false;
        emit Staking(msg.sender,startTimestamp,stakeEndTimestamp,tokenId);
    }

    function stakingTokenWithdraw() nonReentrant external{
        uint256 ownedTokenId = ownedToken[msg.sender];
        require(ownedTokenId != 0,"Have't token in staking");
        require(stakingEndAt[ownedTokenId] <= block.timestamp,"Cannot withdraw");
        lancetPass.transferFrom(address(this),msg.sender,ownedTokenId);
        ownedToken[msg.sender] = 0;
        emit StakingTokenWithdraw(msg.sender,ownedTokenId);
    }

    function convertStakingTime(Staking48HType stakeWithin48HType) pure private returns(uint256){
        if (stakeWithin48HType == Staking48HType.ThirtyDays){
            return _24H_SEC.mul(30);
        }
        if (stakeWithin48HType == Staking48HType.SixtyDays){
            return _24H_SEC.mul(60);
        }
        return 0;
    }

    function convertMembershipTime(uint256 membershipDays) pure private returns(uint256){
        return  _24H_SEC.mul(membershipDays);
    }

    function setMembershipPrice(uint256 membershipDays,uint256 price) external onlyOwner{
        membershipState[membershipDays] = MembershipType(membershipDays,false,price);
        emit SetMembershipPrice(membershipDays,price);
    }

    function setMembershipState(uint256 membershipDays,uint256 price,bool onSale) external onlyOwner{
        require(membershipState[membershipDays].membershipPrice == price);
        if (membershipState[membershipDays].membershipDays == 0 && membershipDays != 0){
            membershipCategory.push(membershipDays);
        }
        membershipState[membershipDays].onSale = onSale;

        emit SetMembershipState(membershipDays,price,onSale);
    }

    function setStakingEnabled() external onlyOwner{
        stakingEnabled = !stakingEnabled;
    }

    function setStaking48HStartTimestamp(uint256 _staking48HStartTimestamp) external onlyOwner{
        staking48HStartTimestamp = _staking48HStartTimestamp;
    }

    function getAllMembershipTypes() external view returns(MembershipType[] memory){
        MembershipType[] memory membershipTypes = new MembershipType[](membershipCategory.length);
        for (uint256 i = 0;i < membershipCategory.length ;i ++){
            membershipTypes[i] = membershipState[membershipCategory[i]];
        }
        return membershipTypes;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: (address(this).balance)}("");
        require(success, "Withdraw: Transaction Unsuccessful.");
    }
}
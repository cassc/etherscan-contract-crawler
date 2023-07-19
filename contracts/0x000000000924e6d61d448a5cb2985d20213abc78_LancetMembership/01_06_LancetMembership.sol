// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface ILancetStaking{
    function ownedToken(address owner) external view returns(uint256);
}

contract LancetMembership is Ownable,ReentrancyGuard{
    using SafeMath for uint256;

    // =========================================================================
    //                               Types
    // =========================================================================
    struct MembershipType{
        uint256 membershipDays;
        bool    onSale;
        uint256 membershipPrice;
    }

    // =========================================================================
    //                               Storage
    // =========================================================================
    IERC721 public lancetPass;
    ILancetStaking public lancetStaking1;
    ILancetStaking public lancetStaking2;

    uint8 public holderDiscount;
    bool public holderMembershipPurchaseEnable;
    bool public userMembershipPurchaseEnable;

    uint256 private constant oneDay = 1 days;

    mapping(uint256 => uint256) public passMembershipEndAt;
    mapping(address => uint256) public userMembershipEndAt;

    uint256[] public membershipCategories;
    mapping(uint256 => MembershipType) public membershipState;

    // =========================================================================
    //                            Constructor
    // =========================================================================
    constructor(IERC721 _lancetPass,ILancetStaking _lancetStaking1,ILancetStaking _lancetStaking2){
        membershipState[30] = MembershipType(30,true,0.1 ether);
        membershipCategories.push(30);
        holderDiscount = 69;
        passMembershipEndAt[514] = 1696861859;
        lancetPass = _lancetPass;
        lancetStaking1 = _lancetStaking1;
        lancetStaking2 = _lancetStaking2;
    }

    // =========================================================================
    //                               Event
    // =========================================================================
    event MembershipPurchase(address indexed owner,uint256 indexed startTimestamp,uint256 indexed endTimestamp,uint256 tokenId);
    event UserMembershipPurchase(address indexed owner,uint256 indexed startTimestamp,uint256 indexed endTimestamp);
    
    // =========================================================================
    //                               Modifier
    // =========================================================================
    modifier onlyPassOwner(uint256 tokenId){
        require(tokenId != 0);
        require(lancetPass.ownerOf(tokenId) == msg.sender || lancetStaking1.ownedToken(msg.sender) == tokenId || lancetStaking2.ownedToken(msg.sender) == tokenId,"Not Lancet Pass Holder");
        _;
    }

    // =========================================================================
    //                               Function
    // =========================================================================
    function holderMembershipPurchase(uint256 purchaseDays,uint256 tokenId) onlyPassOwner(tokenId) nonReentrant payable external{
        require(holderMembershipPurchaseEnable,"Not Enable");
        require(membershipState[purchaseDays].onSale,"Not On Sale");
        require(msg.value == membershipState[purchaseDays].membershipPrice.mul(holderDiscount).div(1e2),"Invalid Price");
        uint256 passMmebershipstartTimestamp = block.timestamp;
        uint256 passMembershipEndTimestamp;
        if (passMembershipEndAt[tokenId] > passMmebershipstartTimestamp){
            passMembershipEndTimestamp = passMembershipEndAt[tokenId].add(oneDay.mul(purchaseDays));
        }else{
            passMembershipEndTimestamp = passMmebershipstartTimestamp.add(oneDay.mul(purchaseDays));
        }        
        passMembershipEndAt[tokenId] = passMembershipEndTimestamp;
        emit MembershipPurchase(msg.sender,passMmebershipstartTimestamp,passMembershipEndTimestamp,tokenId);
    }

    function userMembershipPurchase(uint256 purchaseDays) nonReentrant payable external{
        require(userMembershipPurchaseEnable,"Not Enable");
        require(membershipState[purchaseDays].onSale,"Not On Sale");
        require(msg.value == membershipState[purchaseDays].membershipPrice,"Invalid Price");
        uint256 userMembershipStartTimestamp = block.timestamp;
        uint256 userMembershipEndTimestamp;
        if (userMembershipEndAt[msg.sender] > userMembershipStartTimestamp){
            userMembershipEndTimestamp = userMembershipEndAt[msg.sender].add(oneDay.mul(purchaseDays));
        }else{
            userMembershipEndTimestamp = userMembershipStartTimestamp.add(oneDay.mul(purchaseDays));
        }   
        userMembershipEndAt[msg.sender] = userMembershipEndTimestamp;
        emit UserMembershipPurchase(msg.sender,userMembershipStartTimestamp,userMembershipEndTimestamp);
    }

    function getAllMembershipTypes() external view returns(MembershipType[] memory){
        MembershipType[] memory membershipTypes = new MembershipType[](membershipCategories.length);
        for (uint256 i = 0;i < membershipCategories.length ;i ++){
            membershipTypes[i] = membershipState[membershipCategories[i]];
        }
        return membershipTypes;
    }

    function setHolderDiscount(uint8 discount) external onlyOwner{
        holderDiscount = discount;
    }

    function setHolderMembershipPurchaseEnable() external onlyOwner{
        holderMembershipPurchaseEnable = !holderMembershipPurchaseEnable;
    }

    function setUserMembershipPurchaseEnable() external onlyOwner{
        userMembershipPurchaseEnable = !userMembershipPurchaseEnable;
    }

    function addMembership(uint256 purchaseDays,uint256 price,bool onSale) external onlyOwner{
        for (uint256 i = 0; i < membershipCategories.length ; i ++){
            if (membershipCategories[i] == purchaseDays){
                revert("Purchase Days Already Exist");
            }
        }
        membershipState[purchaseDays] = MembershipType(purchaseDays,onSale,price);
        membershipCategories.push(purchaseDays);
    }

    function updateMembership(uint256 purchaseDays,uint256 price,bool onSale) external onlyOwner{
        bool purchaseDaysExist;
        for (uint256 i = 0; i < membershipCategories.length ; i ++){
            if (membershipCategories[i] == purchaseDays){
                purchaseDaysExist = true;
                break;
            }
        }
        require(purchaseDaysExist,"Purchase Days Not Exist");
        membershipState[purchaseDays] = MembershipType(purchaseDays,onSale,price);
    }

    function removeMembership(uint256 purchaseDays) external onlyOwner{
        for (uint256 i = 0; i < membershipCategories.length; i++){
            if (membershipCategories[i] == purchaseDays){
                membershipCategories[i] = membershipCategories[membershipCategories.length - 1];
                membershipCategories.pop();
                break;
            }
        }
        membershipState[purchaseDays] = MembershipType(0,false,0);
    }

    function setLancetPass(IERC721 _lancetPass) onlyOwner external {
        lancetPass = _lancetPass;
    }

    function setLancetStaking1(ILancetStaking _lancetStaking1) onlyOwner external{
        lancetStaking1 = _lancetStaking1;
    }

    function setLancetStaking2(ILancetStaking _lancetStaking2) onlyOwner external{
        lancetStaking2 = _lancetStaking2;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: (address(this).balance)}("");
        require(success, "Withdraw: Transaction Unsuccessful.");
    }
}
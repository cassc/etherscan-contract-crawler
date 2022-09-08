// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/*
 * BNBPower 
 * App:             https://bnbpower.io
 * Twitter:         https://twitter.com/bnbpwr
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


interface IHelp {
    function Bytecode_1_0_2() external view returns (bool);
}

interface IPackages {
    function withdraw(address _user) external;
    function infoUser(address _user) external view returns(uint256, uint256, uint256, uint256);
    function totalStaked() external view returns(uint256);
    function totalStakedProject() external view returns(uint256);
    function totalPoolClaim() external view returns(uint256);
    function totalRecompound() external view returns(uint256);
    function totalWithdraws() external view returns(uint256);
    function pendingReward(address _user) external view returns (uint256);
    function getPackage() external view returns(uint, uint, uint, uint, uint);
    function getRefPercent() external view returns(uint, uint, uint, uint, uint);
    function getBalance() external view returns(uint256);
    function devFee() external view returns(uint256);
}

contract Referrals is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Info of each members.
    struct MemberStruct {
        bool isExist;
        uint256 id;
        uint256 referrerID;
        uint256 referredUsers;
        uint256 earn;
        uint256 time;
    }
    // Membership structure
    mapping(address => MemberStruct) public members;
    // Member listing by id
    mapping(uint256 => address) public membersList;
    // List of referrals by user
    mapping(uint256 => mapping(uint256 => address)) public memberChild;
    // Moderators list
    mapping(address => bool) public moderators;
    // ID of the last registered member
    uint256 public lastMember;
    // Total earn referrals
    uint256 public totalEarnReferrals;
    // Total moderators
    uint256 public totalModerators;
    // Status moderators
    bool public statusModerators;
    

    constructor(address _dev) {
        addMember(_dev, address(this));
    }

    receive() external payable {}

    // Add or remove moderator
    function actionModerator(address _mod, bool _check) external onlyOwner {
        require(!statusModerators, "!statusModerators");
        moderators[_mod] = _check;
        totalModerators = totalModerators.add(1);
        if(totalModerators == 3) {
            statusModerators = true;
        }
    }

    modifier isModOrOwner() {
        require(owner() == msg.sender || moderators[msg.sender] , "!isModOrOwner");
        _;
    }

    modifier isModerator() {
        require(moderators[msg.sender] , "!isModOrOwner");
        _;
    }  
    
    // Only owner can register new users
    function addMember(address _member, address _parent) public isModOrOwner {
        if (lastMember > 0) {
            require(members[_parent].isExist, "Sponsor not exist");
        }
        MemberStruct memory memberStruct;
        memberStruct = MemberStruct({
            isExist: true,
            id: lastMember,
            referrerID: members[_parent].id,
            referredUsers: 0,
            earn: 0,
            time: block.timestamp
        });
        members[_member] = memberStruct;
        membersList[lastMember] = _member;
        memberChild[members[_parent].id][members[_parent].referredUsers] = _member;
        members[_parent].referredUsers++;
        lastMember++;
        emit eventNewUser(msg.sender, _member, _parent);
    }

    // Only owner can update the balance of referrals
    function updateEarn(address _member, uint256 _amount) public isModOrOwner {
        require(isMember(_member), "!member");
        members[_member].earn = members[_member].earn.add(_amount);
        totalEarnReferrals = totalEarnReferrals.add(_amount);
    }

    // function that registers members
    function registerUser(address _member, address _sponsor) public isModOrOwner {
        if(isMember(_member) == false){
            if(isMember(_sponsor) == false){
                _sponsor = this.membersList(0);
            }
            addMember(_member, _sponsor);
        }
    }

    // Returns the total number of referrals in the levels
    function countReferrals(address _member) public view returns (uint256[] memory){
        uint256[] memory counts = new uint256[](5);
       
        counts[0] = members[_member].referredUsers;

        address[] memory r_1 = getListReferrals(_member);

        for (uint256 i_1 = 0; i_1 < r_1.length; i_1++) {
            counts[1] += members[r_1[i_1]].referredUsers;

            address[] memory r_2 = getListReferrals(r_1[i_1]);
            for (uint256 i_2 = 0; i_2 < r_2.length; i_2++) {
                counts[2] += members[r_2[i_2]].referredUsers;

                address[] memory r_3 = getListReferrals(r_2[i_2]);
                for (uint256 i_3 = 0; i_3 < r_3.length; i_3++) {
                    counts[3] += members[r_3[i_3]].referredUsers;

                    address[] memory r_4 = getListReferrals(r_3[i_3]);
                    for (uint256 i_4 = 0; i_4 < r_4.length; i_4++) {
                        counts[4] += members[r_4[i_4]].referredUsers;
                    }

                }

            }

        }

        return counts;
    }

    // Returns the list of referrals
    function getListReferrals(address _member) public view returns (address[] memory){
        address[] memory referrals = new address[](members[_member].referredUsers);
        if(members[_member].referredUsers > 0){
            for (uint256 i = 0; i < members[_member].referredUsers; i++) {
                if(memberChild[members[_member].id][i] != address(0)){
                    if(memberChild[members[_member].id][i] != _member){
                        referrals[i] = memberChild[members[_member].id][i];
                    }
                } else {
                    break;
                }
            }
        }
        return referrals;
    }

    // Returns the address of the sponsor of an account
    function getSponsor(address account) public view returns (address) {
        return membersList[members[account].referrerID];
    }

    // Check if an address is registered
    function isMember(address _user) public view returns (bool) {
        return members[_user].isExist;
    }

    // Harvest all packages
    function harvest(address _user, address _p_1, address _p_2, address _p_3) external nonReentrant {
        if( _p_1 != address(0) ) {
            IPackages(_p_1).withdraw(_user);
        }
        if( _p_2 != address(0) ) {
            IPackages(_p_2).withdraw(_user);
        }
        if( _p_3 != address(0) ) {
            IPackages(_p_3).withdraw(_user);
        }
    }

    // transfer the ether to the user
    function transfer(address _user, uint256 _amount) external isModerator {
        if(_amount > 0 && address(this).balance > 0){
            payable(_user).transfer(_amount);
        }
    }

    // Returns value staked packages
    function stakeds(address _user, address _p_1, address _p_2, address _p_3) external view returns(uint256[] memory) {
        uint256[] memory values = new uint256[](4);

        if( _p_1 != address(0) ) {
            (values[0],,,) = IPackages(_p_1).infoUser(_user);
        }
        if( _p_2 != address(0) ) {
            (values[1],,,) = IPackages(_p_2).infoUser(_user);
        }
        if( _p_3 != address(0) ) {
            (values[2],,,) = IPackages(_p_3).infoUser(_user);
        }
        values[3] = values[0].add(values[1]).add(values[2]);

        return values;
    }

    // Returns value profits packages
    function profits(address _user, address _p_1, address _p_2, address _p_3) external view returns(uint256[] memory) {
        uint256[] memory values = new uint256[](4);

        if( _p_1 != address(0) ) {
            (,,values[0],) = IPackages(_p_1).infoUser(_user);
        }
        if( _p_2 != address(0) ) {
            (,,values[1],) = IPackages(_p_2).infoUser(_user);
        }
        if( _p_3 != address(0) ) {
            (,,values[2],) = IPackages(_p_3).infoUser(_user);
        }
        values[3] = values[0].add(values[1]).add(values[2]);

        return values;
    }

    // Returns value withdraws packages
    function withdraws(address _user, address _p_1, address _p_2, address _p_3) external view returns(uint256[] memory) {
        uint256[] memory values = new uint256[](4);

        if( _p_1 != address(0) ) {
            (,,,values[0]) = IPackages(_p_1).infoUser(_user);
        }
        if( _p_2 != address(0) ) {
            (,,,values[1]) = IPackages(_p_2).infoUser(_user);
        }
        if( _p_3 != address(0) ) {
            (,,,values[2]) = IPackages(_p_3).infoUser(_user);
        }
        values[3] = values[0].add(values[1]).add(values[2]);

        return values;
    }

    // Returns value totalStaked packages
    function totalStaked(address _p_1, address _p_2, address _p_3) external view returns(uint256[] memory) {
        uint256[] memory values = new uint256[](4);

        if( _p_1 != address(0) ) {
            values[0] = IPackages(_p_1).totalStaked();
        }
        if( _p_2 != address(0) ) {
            values[1] = IPackages(_p_2).totalStaked();
        }
        if( _p_3 != address(0) ) {
            values[2] = IPackages(_p_3).totalStaked();
        }

        values[3] = values[0].add(values[1]).add(values[2]);

        return values;
    }

    // Returns value totalStakedProject packages
    function totalStakedProject(address _p_1, address _p_2, address _p_3) external view returns(uint256[] memory) {
        uint256[] memory values = new uint256[](4);

        if( _p_1 != address(0) ) {
            values[0] = IPackages(_p_1).totalStakedProject();
        }
        if( _p_2 != address(0) ) {
            values[1] = IPackages(_p_2).totalStakedProject();
        }
        if( _p_3 != address(0) ) {
            values[2] = IPackages(_p_3).totalStakedProject();
        }

        values[3] = values[0].add(values[1]).add(values[2]);

        return values;
    }

    // Returns value totalPoolClaim packages
    function totalPoolClaim(address _p_1, address _p_2, address _p_3) external view returns(uint256[] memory) {
        uint256[] memory values = new uint256[](4);

        if( _p_1 != address(0) ) {
            values[0] = IPackages(_p_1).totalPoolClaim();
        }
        if( _p_2 != address(0) ) {
            values[1] = IPackages(_p_2).totalPoolClaim();
        }
        if( _p_3 != address(0) ) {
            values[2] = IPackages(_p_3).totalPoolClaim();
        }

        values[3] = values[0].add(values[1]).add(values[2]);

        return values;
    }

    // Returns value totalRecompound packages
    function totalRecompound(address _p_1, address _p_2, address _p_3) external view returns(uint256[] memory) {
        uint256[] memory values = new uint256[](4);

        if( _p_1 != address(0) ) {
            values[0] = IPackages(_p_1).totalRecompound();
        }
        if( _p_2 != address(0) ) {
            values[1] = IPackages(_p_2).totalRecompound();
        }
        if( _p_3 != address(0) ) {
            values[2] = IPackages(_p_3).totalRecompound();
        }

        values[3] = values[0].add(values[1]).add(values[2]);

        return values;
    }

    // Returns value totalWithdraws packages
    function totalWithdraws(address _p_1, address _p_2, address _p_3) external view returns(uint256[] memory) {
        uint256[] memory values = new uint256[](4);

        if( _p_1 != address(0) ) {
            values[0] = IPackages(_p_1).totalWithdraws();
        }
        if( _p_2 != address(0) ) {
            values[1] = IPackages(_p_2).totalWithdraws();
        }
        if( _p_3 != address(0) ) {
            values[2] = IPackages(_p_3).totalWithdraws();
        }

        values[3] = values[0].add(values[1]).add(values[2]);

        return values;
    }

    // Returns value pendingReward packages
    function pendingReward(address _user, address _p_1, address _p_2, address _p_3) external view returns(uint256[] memory) {
        uint256[] memory values = new uint256[](4);

        if( _p_1 != address(0) ) {
            values[0] = IPackages(_p_1).pendingReward(_user);
        }
        if( _p_2 != address(0) ) {
            values[1] = IPackages(_p_2).pendingReward(_user);
        }
        if( _p_3 != address(0) ) {
            values[2] = IPackages(_p_3).pendingReward(_user);
        }

        values[3] = values[0].add(values[1]).add(values[2]);

        return values;
    }

    // Returns value getPackage packages
    function getPackage(address _p_1) external view returns(uint256[] memory) {
        uint256[] memory _d = new uint256[](5);

        if( _p_1 != address(0) ) {
            (_d[0],_d[1],_d[2],_d[3],_d[4]) = IPackages(_p_1).getPackage();
        }

        return _d;
    }

    // Returns value getRefPercent packages
    function getRefPercent(address _p_1) external view returns(uint256[] memory) {
        uint256[] memory _d = new uint256[](5);

        if( _p_1 != address(0) ) {
            (_d[0],_d[1],_d[2],_d[3],_d[4]) = IPackages(_p_1).getRefPercent();
        }

        return _d;
    }

    // Helper functions
    function getEthBalance(address addr) external view returns (uint256 balance) {
        balance = addr.balance;
    }

    // returns balance contract
    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

    // returns balance contract package
    function getBalance(address _p_1) external view returns(uint256) {
        return IPackages(_p_1).getBalance();
    }

    // block mining for platform development
    function minningBlocks() external {}

    
    event eventNewUser(address _mod, address _member, address _parent);

}
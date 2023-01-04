// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../NFT/DualXNFT.sol";
import "./EnumerableArrays.sol";

abstract contract DataStorage is EnumerableArrays {
    
    struct NodeData {
        uint24 allLeftDirect;
        uint24 allRightDirect;
        uint16 leftVariance;
        uint16 rightVariance;
        uint16 depth;
        uint8 childs;
        uint8 isLeftOrRightChild;
    }

    struct NodeInfo {
        address uplineAddress;
        address leftDirectAddress;
        address rightDirectAddress;
    }
    
    mapping(address => NodeData) _userData;
    mapping(address => NodeInfo) _userInfo;
    mapping(uint256 => address) public idToAddr;
    mapping(address => uint256) public addrToId;
    mapping(address => bool) public registered;

    DualXNFT public DUX;
    IERC20 public DPT;

    uint256 public allPayments;
    uint256 public enterPrice;
    uint256 public maxPoint;
    uint256 public userCount;
    uint256 public todayTotalPoint;
    uint256 public lastRun;
    uint256 public maxDualXmembers;

    address public lastRewardWriter;
    address owner;

    function userData(address userAddr) public view returns(NodeData memory) {
        return _userData[userAddr];
    }

    function userInfo(address userAddr) public view returns(NodeInfo memory) {
        return _userInfo[userAddr];
    }

    function balanceDPT() public view returns(uint256) {
        return DPT.balanceOf(address(this));
    }
    
    function userDUXBalance(address userAddr) public view returns(uint256) {
        return DUX.balanceOf(userAddr);
    }

    function todayAllRewardValue() public view returns(uint256) {
        return balanceDPT() * 90/100;
    }

    function todayEveryPointValue() public view returns(uint256) {
        uint256 denom = todayTotalPoint != 0 ? todayTotalPoint : 1;
        return todayAllRewardValue() / denom;
    }

    function todayLotteryValue() public view returns(uint256) {
        return balanceDPT() * 9/100;
    }

    function todayWriterReward() public view returns(uint256) {
        return todayLotteryValue() % (25 * 10 ** 18);
    }

    function userUpAddr(address userAddr) public view returns(address) {
        return _userInfo[userAddr].uplineAddress;
    }

    function userChilds(address userAddr)
        public
        view
        returns (address left, address right)
    {
        left = _userInfo[userAddr].leftDirectAddress;
        right = _userInfo[userAddr].rightDirectAddress;        
    } 

    function userChildsCount(address userAddr)
        public
        view
        returns (uint256)
    {
        return _userData[userAddr].childs;        
    } 

    function userDepth(address userAddr)
        public
        view
        returns (uint256)
    {
        return _userData[userAddr].depth;        
    }
    
    function userTodayDirectCount(address userAddr) public view returns (
        uint256 left,
        uint256 right
    ) {
        uint256 points = userTodayPoints(userAddr);

        left = _userData[userAddr].leftVariance + points;
        right = _userData[userAddr].rightVariance + points;
    }
    
    function userAllTimeDirectCount(address userAddr) public view returns (
        uint256 left,
        uint256 right
    ) {
        left = _userData[userAddr].allLeftDirect;
        right = _userData[userAddr].allRightDirect;
    }
    
    function lotteryWinnersCount100() public view returns (uint256) {
        return todayLotteryValue() / (100 * 10 ** 18);
    }
    
    function lotteryWinnersCount25() public view returns (uint256) {
        return (todayLotteryValue() % (100 * 10 ** 18)) / (25 * 10 ** 18);
    }
}
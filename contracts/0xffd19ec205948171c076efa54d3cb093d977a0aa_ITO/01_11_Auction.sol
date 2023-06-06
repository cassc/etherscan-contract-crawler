// SPDX-License-Identifier: MIT
//Source: https://github.com/pancakeswap/initial-farm-offering/blob/master/contracts/IFO.sol 
//A littlbe mid modified version of IFO by PancakeSwap
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract ITO is ReentrancyGuard, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        bool claimed; // default false
    }

    // admin address
    address public adminAddress;
    address public deployer;
    // The raising token
    IERC20 public lpToken;
    // The offering token
    IERC20 public offeringToken;
    // The timestamp when ITO starts
    uint256 public startTime;
    // The timestamp when ITO ends
    uint256 public endTime;
    // total amount of raising tokens need to be raised
    uint256 public raisingAmount;
    // total amount of offeringToken that will offer
    uint256 public offeringAmount;
    // total amount of raising tokens that have already raised
    uint256 public totalAmount;
    // address => amount
    mapping(address => UserInfo) public userInfo;
    // participators
    address[] public addressList;

    event Deposit(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 offeringAmount, uint256 excessAmount);

    constructor() {
        deployer = msg.sender;
    }

    function initialize(
        address _lpToken,
        address _offeringToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _offeringAmount,
        uint256 _raisingAmount,
        address _adminAddress
    ) public initializer() {
        require(msg.sender == deployer);
        require(_startTime < _endTime && block.timestamp < _startTime); // #FX: ANO-02M
        require(_lpToken != address(0) && _offeringToken != address(0) && _adminAddress != address(0), "bad init");
        lpToken = IERC20(_lpToken);
        offeringToken = IERC20(_offeringToken);
        startTime = _startTime;
        endTime = _endTime;
        offeringAmount = _offeringAmount;
        raisingAmount = _raisingAmount;
        totalAmount;
        adminAddress = _adminAddress;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }

    function setOfferingAmount(uint256 _offerAmount) public onlyAdmin {
        require(block.timestamp < startTime, "no");
        require(_offerAmount <= offeringToken.balanceOf(address(this)), "not enough funds to start auction"); // #FX: ANO-03M
        offeringAmount = _offerAmount;

    }

    function setRaisingAmount(uint256 _raisingAmount) public onlyAdmin {
        require(block.timestamp < startTime, "no");
        raisingAmount = _raisingAmount;
    }

    function deposit(uint256 _amount) public {
        require(block.timestamp > startTime && block.timestamp < endTime, "not ifo time");
        require(_amount > 0, "need _amount > 0");
        lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        if (userInfo[msg.sender].amount == 0) {
            addressList.push(address(msg.sender));
        }
        userInfo[msg.sender].amount = userInfo[msg.sender].amount.add(_amount);
        totalAmount = totalAmount.add(_amount);
        emit Deposit(msg.sender, _amount);
    }

    function harvest() public nonReentrant {
        require(block.timestamp > endTime, "not harvest time");
        require(userInfo[msg.sender].amount > 0, "have you participated?");
        require(!userInfo[msg.sender].claimed, "nothing to harvest");
        uint256 offeringTokenAmount = getOfferingAmount(msg.sender);
        uint256 refundingTokenAmount = getRefundingAmount(msg.sender);
        userInfo[msg.sender].claimed = true;
        if (offeringTokenAmount > 0) {
            offeringToken.safeTransfer(address(msg.sender), offeringTokenAmount);
        }
        if (refundingTokenAmount > 0) {
            lpToken.safeTransfer(address(msg.sender), refundingTokenAmount);
        }
        emit Harvest(msg.sender, offeringTokenAmount, refundingTokenAmount);
    }

    function hasHarvest(address _user) external view returns (bool) {
        return userInfo[_user].claimed;
    }

    // allocation 100000 means 0.1(10%), 1 means 0.000001(0.0001%), 1000000 means 1(100%)
    function getUserAllocation(address _user) public view returns (uint256) {
        return userInfo[_user].amount.mul(1e12).div(totalAmount).div(1e6);
    }

    // get the amount of ITO token you will get
    function getOfferingAmount(address _user) public view returns (uint256) {
        if (totalAmount > raisingAmount) {
            uint256 allocation = getUserAllocation(_user);
            return offeringAmount.mul(allocation).div(1e6);
        } else {
            // userInfo[_user] / (raisingAmount / offeringAmount)
            return userInfo[_user].amount.mul(offeringAmount).div(raisingAmount);
        }
    }

    // get the amount of lp token you will be refunded
    function getRefundingAmount(address _user) public view returns (uint256) {
        if (totalAmount <= raisingAmount) {
            return 0;
        }
        uint256 allocation = getUserAllocation(_user);
        uint256 payAmount = raisingAmount.mul(allocation).div(1e6);
        return userInfo[_user].amount.sub(payAmount);
    }

    function getAddressListLength() external view returns (uint256) {
        return addressList.length;
    }

    function finalWithdraw(uint256 _lpAmount, uint256 _offerAmount) public onlyAdmin {
        require(_lpAmount <= lpToken.balanceOf(address(this)), "not enough token 0");
        require(_offerAmount <= offeringToken.balanceOf(address(this)), "not enough token 1");
        require(endTime < block.timestamp, "not over yet");
        if (_offerAmount > 0) {
            offeringToken.safeTransfer(address(msg.sender), _offerAmount);
        }
        if (_lpAmount > 0) {
            lpToken.safeTransfer(address(msg.sender), _lpAmount);
        }
    }
}
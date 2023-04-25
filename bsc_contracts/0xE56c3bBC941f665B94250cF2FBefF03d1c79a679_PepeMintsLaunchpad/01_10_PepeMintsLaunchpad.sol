pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./BoringOwnable.sol";

interface IPepeMints {
    function burn(uint amounts) external;
    function LAUNCH_TIME() external returns (uint);
    function addStakesUser(address user, uint _stakeTime, uint _amount, uint _claimed, uint _lastUpdate) external;
}


contract PepeMintsLaunchpad is BoringOwnable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  receive() external payable {}

  // Info of each user.
  struct UserInfo {
      uint256 amount;   // How many tokens the user has provided.
      bool claimed;  // default false
  }

  IPepeMints public pepeMints;

  // The Time number when Launchpad starts
  uint256 public startTime;
  // The Time number when Launchpad ends
  uint256 public endTime;
  // total amount of raising tokens need to be raised
  uint256 public raisingAmount;
  // total amount of offeringToken that will offer
  uint256 public offeringAmount;
  // total amount of raising tokens that have already raised
  uint256 public totalAmount;
  // address => amount
  mapping (address => UserInfo) public userInfo;
  // participators
  address[] public addressList;
  // allow claims
  bool public allowClaim;

  event Deposit(address indexed user, uint256 amount);
  event Harvest(address indexed user, uint256 offeringAmount, uint256 excessAmount);

  function setPepeMints(IPepeMints _pepeMints) external onlyOwner {
    pepeMints = _pepeMints;
  }

  function initialize(
      IPepeMints _pepeMints, 
      uint256 _startTime,
      uint256 _endTime,
      uint256 _offeringAmount,
      uint256 _raisingAmount
  ) public {
      pepeMints = _pepeMints;
      startTime = _startTime;
      endTime = _endTime;
      offeringAmount = _offeringAmount;
      raisingAmount = _raisingAmount;
      totalAmount = 0;
  }

  function setStartEndTime(uint256 _startTime, uint256 _endTime) public onlyOwner {
    startTime = _startTime;
    endTime = _endTime;
  }

  function setOfferingAmount(uint256 _offerAmount) public onlyOwner {
    require (block.timestamp < startTime, 'no');
    offeringAmount = _offerAmount;
  }

  function setRaisingAmount(uint256 _raisingAmount) public onlyOwner {
    raisingAmount = _raisingAmount;
  }

  function deposit() public payable nonReentrant {
    uint _amount = msg.value;
    require (block.timestamp > startTime && block.timestamp < endTime, 'not launchpad time');
    require (_amount > 0, 'need _amount > 0');
    if (userInfo[msg.sender].amount == 0) {
      addressList.push(address(msg.sender));
    }
    userInfo[msg.sender].amount = userInfo[msg.sender].amount + _amount;
    totalAmount = totalAmount + _amount;
    emit Deposit(msg.sender, _amount);
  }

  function harvestAndStake() public nonReentrant {
    require (block.timestamp > endTime, 'not harvest time');
    require (userInfo[msg.sender].amount > 0, 'have you participated?');
    require (!userInfo[msg.sender].claimed, 'nothing to harvest');
    require (allowClaim, 'wait for dev to allow');
    uint256 offeringTokenAmount = getOfferingAmount(msg.sender);
    uint256 refundingTokenAmount = getRefundingAmount(msg.sender);
    if (offeringTokenAmount > 0) {
      pepeMints.addStakesUser(address(msg.sender), pepeMints.LAUNCH_TIME(), offeringTokenAmount, 0, pepeMints.LAUNCH_TIME());
    }
    if (refundingTokenAmount > 0) {
      sendETH(address(msg.sender), refundingTokenAmount);
    }
    userInfo[msg.sender].claimed = true;
    emit Harvest(msg.sender, offeringTokenAmount, refundingTokenAmount);
  }

  function hasHarvest(address _user) external view returns(bool) {
      return userInfo[_user].claimed;
  }

  // allocation 100000 means 0.1(10%), 1 means 0.000001(0.0001%), 1000000 means 1(100%)
  function getUserAllocation(address _user) public view returns(uint256) {
    return (userInfo[_user].amount * 1e24 / totalAmount) / 1e12;
  }

  // get the amount of Launchpad token you will get
  function getOfferingAmount(address _user) public view returns(uint256) {
    if (totalAmount > raisingAmount) {
      uint256 allocation = getUserAllocation(_user);
      return offeringAmount * allocation / 1e12;
    }
    else {
      // userInfo[_user] / (raisingAmount / offeringAmount)
      return userInfo[_user].amount * offeringAmount / raisingAmount;
    }
  }

  // get the amount of eth you will be refunded
  function getRefundingAmount(address _user) public view returns(uint256) {
    if (totalAmount <= raisingAmount) {
      return 0;
    }
    uint256 allocation = getUserAllocation(_user);
    uint256 payAmount = raisingAmount * allocation / 1e12;
    return userInfo[_user].amount - payAmount;
  }

  function getAddressListLength() external view returns(uint256) {
    return addressList.length;
  }

  function finalWithdraw(uint256 _ethAmount) public onlyOwner {
    require (_ethAmount <= address(this).balance, 'not enough eth');
    if(_ethAmount > 0) {
        sendETH(address(msg.sender), _ethAmount);
    }
  }

  function flipAllowClaim() external onlyOwner {
    allowClaim = !allowClaim;
  }

  function sendETH(address to, uint amount) internal {
    if (amount > 0) {
      (bool transferSuccess, ) = payable(to).call{
          value: amount
      }("");
      require(transferSuccess, "ETH transfer failed");
    }
  }
}
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import "../interfaces/IERC20Mintable.sol";
import '../core/SafeOwnable.sol';

contract FINGOIdo {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event NewReceiver(address receiver, uint sendAmount, uint totalReleaseAmount, uint lastReleaseAt);
    event ReleaseToken(address receiver, uint releaseAmount, uint nextReleaseAmount, uint nextReleaseBlockNum);

    uint256 public constant PERCENT_BASE = 1e4;
    uint256 public constant PRICE_BASE = 1e6;
    ///@notice the send token for ido
    IERC20 public immutable sendToken;
    ///@notice the sendToken will be claimed to this address
    address public immutable sendTokenReceiver;
    ///@notice the receive token to lock
    IERC20Mintable public immutable receiveToken;
    ///@notice the price of ido
    uint public immutable idoPrice;
    ///@notice first luck month
    uint256 public immutable FIRST_LOCK_SECONDS;
    ///@notice first release ratio
    uint256 public immutable FIRST_LOCK_PERCENT;
    ///@notice seconds of lock period
    uint256 public immutable LOCK_PERIOD;
    ///@notice how many period total locked
    uint256 public immutable LOCK_PERIOD_NUM;
    ///@notice the total amount in this contract for release;
    uint256 public immutable totalRelease;
    ///@notice the remain amount in this contract for release; 
    uint256 public remainRelease;
    ///@notice total received send token
    uint256 public totalEnter;
    ///@notice the info of a releaser
    struct ReleaseInfo {
        address receiver;               //who will receive the release token
        uint256 totalReleaseAmount;     //the amount of the token total released for the receiver;
        bool firstUnlock;               //first unlock already done
        uint256 lastReleaseAt;          //the last seconds the the receiver get the released token
        uint256 alreadyReleasedAmount;  //the amount the token already released for the reciever
    }
    mapping(address => ReleaseInfo) public receivers;

    constructor(
        IERC20 _sendToken, address _sendTokenReceiver, IERC20Mintable _receiveToken, uint _idoPrice, 
        uint256 _totalRelease, uint256 _firstLockSeconds, uint256 _firstLockPercent, 
        uint256 _lockPeriod, uint256 _lockPeriodNum
    ) {
        require(_sendTokenReceiver != address(0), "send token receiver is zero");
        sendTokenReceiver = _sendTokenReceiver;
        require(address(_sendToken) != address(0), "ilelgal send token");
        sendToken = _sendToken;
        require(address(_receiveToken) != address(0), "illegal token");
        receiveToken = _receiveToken;
        require(address(_sendToken) != address(_receiveToken), "sendToken and receiveToken is the same");
        require(_idoPrice > 0, "illegal idoPrice");
        idoPrice = _idoPrice;
        FIRST_LOCK_SECONDS = _firstLockSeconds;
        FIRST_LOCK_PERCENT = _firstLockPercent;
        LOCK_PERIOD = _lockPeriod;
        LOCK_PERIOD_NUM = _lockPeriodNum;
        remainRelease = totalRelease = _totalRelease;
    }

    function enter(address _receiver, uint256 _amount) external {
        require(_receiver != address(0), "receiver address is zero");
        require(_amount > 0, "release amount is zero");
        uint receiveAmount = _amount.mul(PRICE_BASE).div(idoPrice);
        require(remainRelease >= receiveAmount, "release amount is bigger than reaminRelease");
        remainRelease = remainRelease.sub(receiveAmount);
        totalEnter = totalEnter.add(_amount);
        ReleaseInfo storage receiver = receivers[_receiver];
        uint totalReleaseAmount = receiver.totalReleaseAmount.sub(receiver.alreadyReleasedAmount).add(receiveAmount);
        receiver.receiver = _receiver;
        receiver.totalReleaseAmount = totalReleaseAmount;
        receiver.firstUnlock = false;
        receiver.lastReleaseAt = block.timestamp;
        receiver.alreadyReleasedAmount = 0;
        sendToken.safeTransferFrom(msg.sender, address(this), _amount);
        receiveToken.mint(address(this), receiveAmount);
        emit NewReceiver(_receiver, _amount, totalReleaseAmount, receiver.lastReleaseAt);
    }

    //response1: the timestamp for next release
    //response2: the amount for next release
    //response3: the total amount already released
    //response4: the remain amount for the receiver to release
    function getReleaseInfo(address _receiver) public view returns (uint256 nextReleaseAt, uint256 nextReleaseAmount, uint256 alreadyReleaseAmount, uint256 remainReleaseAmount) {
        ReleaseInfo storage receiver = receivers[_receiver];
        require(_receiver != address(0) && receiver.receiver == _receiver, "receiver not exist");
        if (!receiver.firstUnlock) {
            nextReleaseAt = receiver.lastReleaseAt + FIRST_LOCK_SECONDS;
            nextReleaseAmount = receiver.totalReleaseAmount.mul(FIRST_LOCK_PERCENT).div(PERCENT_BASE);
        } else {
            nextReleaseAt = receiver.lastReleaseAt + LOCK_PERIOD;
            nextReleaseAmount = receiver.totalReleaseAmount.sub(receiver.totalReleaseAmount.mul(FIRST_LOCK_PERCENT).div(PERCENT_BASE)).div(LOCK_PERIOD_NUM);
        }
        alreadyReleaseAmount = receiver.alreadyReleasedAmount;
        remainReleaseAmount = receiver.totalReleaseAmount.sub(receiver.alreadyReleasedAmount);
        if (nextReleaseAmount > remainReleaseAmount) {
            nextReleaseAmount = remainReleaseAmount;
        }
    }

    function claim(address _receiver) external {
        (uint nextReleaseSeconds, uint nextReleaseAmount, , ) = getReleaseInfo(_receiver);
        require(block.timestamp >= nextReleaseSeconds, "not the right time");
        require(nextReleaseAmount > 0, "already released all");
        ReleaseInfo storage receiver = receivers[_receiver];
        if (!receiver.firstUnlock) {
            receiver.firstUnlock = true; 
        }
        receiver.lastReleaseAt = nextReleaseSeconds;
        receiver.alreadyReleasedAmount = receiver.alreadyReleasedAmount.add(nextReleaseAmount);
        uint balance = receiveToken.balanceOf(address(this));
        /*
        if (balance < nextReleaseAmount) {
            receiveToken.mint(address(this), nextReleaseAmount.sub(balance));
            balance = receiveToken.balanceOf(address(this));
        }
        */
        require(balance >= nextReleaseAmount, "contract balance not enough");
        SafeERC20.safeTransfer(receiveToken, receiver.receiver, nextReleaseAmount);
        (uint nextNextReleaseSeconds, uint nextNextReleaseAmount, , ) = getReleaseInfo(_receiver);
        emit ReleaseToken(_receiver, nextReleaseAmount, nextNextReleaseSeconds, nextNextReleaseAmount);
    }

    function leave(uint amount) external {
        uint balance = sendToken.balanceOf(address(this));
        if (amount > balance) {
            amount = balance;
        }
        if (amount > 0) {
            sendToken.safeTransfer(sendTokenReceiver, amount);
        }
    }
}
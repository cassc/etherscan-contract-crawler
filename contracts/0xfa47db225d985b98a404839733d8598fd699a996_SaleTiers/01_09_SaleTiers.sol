//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC677Receiver } from "./interfaces/IERC677Receiver.sol";

contract SaleTiers is IERC677Receiver, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint amount;
        uint claimed;
    }

    IERC20 public paymentToken;
    IERC20 public offeringToken;
    bytes32 public merkleRoot;
    uint public startTime;
    uint public endTime;
    uint public offeringAmount;
    uint public raisingAmount;
    uint public vestingInitial; // 1e12 = 100%
    uint public vestingDuration;
    bool public paused;
    bool public finalized;
    bool public fcfsOpen;
    uint public fcfsAllocation;
    uint public totalAmount;
    uint public totalUsers;
    mapping(address => UserInfo) public userInfos;

    event SetTokens(address payment, address offering);
    event SetAmounts(uint offering, uint raising);
    event SetVesting(uint initial, uint duration);
    event SetTimes(uint start, uint end);
    event SetMerkleRoot(bytes32 merkleRoot);
    event SetPaused(bool paused);
    event SetFinalized();
    event SetFcfsOpen(bool open);
    event SetFcfsAllocation(uint amount);
    event Deposit(address indexed user, uint amount);
    event Harvest(address indexed user, uint amount);

    constructor(
        address _paymentToken,
        address _offeringToken,
        bytes32 _merkleRoot,
        uint _startTime,
        uint _endTime,
        uint _offeringAmount,
        uint _raisingAmount,
        uint _vestingInitial,
        uint _vestingDuration
    ) Ownable() {
        paymentToken = IERC20(_paymentToken);
        offeringToken = IERC20(_offeringToken);
        merkleRoot = _merkleRoot;
        startTime = _startTime;
        endTime = _endTime;
        offeringAmount = _offeringAmount;
        raisingAmount = _raisingAmount;
        vestingInitial = _vestingInitial;
        vestingDuration = _vestingDuration;
        fcfsAllocation = (raisingAmount * 1000 / 1000000);
        require(_offeringAmount > 0, "offering > 0");
        require(_raisingAmount > 0, "raising > 0");
        require(_startTime < _endTime, "start < end");
        require(_startTime < 1e10, "start time not unix");
        require(_endTime < 1e10, "start time not unix");
        require(_vestingInitial <= 1e12/2, "vesting initial < 50%");
        require(_vestingDuration < 365 days, "vesting duration < 1 year");
        emit SetTokens(_paymentToken, _offeringToken);
        emit SetAmounts(_offeringAmount, _raisingAmount);
        emit SetVesting(_vestingInitial, _vestingDuration);
    }

    function setTokens(address payment, address offering) external onlyOwner {
        paymentToken = IERC20(payment);
        offeringToken = IERC20(offering);
        emit SetTokens(payment, offering);
    }

    function setAmounts(uint offering, uint raising) external onlyOwner {
        offeringAmount = offering;
        raisingAmount = raising;
        emit SetAmounts(offering, raising);
    }

    function setVesting(uint initial, uint duration) external onlyOwner {
        vestingInitial = initial;
        vestingDuration = duration;
        emit SetVesting(initial, duration);
    }

    function setTimes(uint _startTime, uint _endTime) external onlyOwner {
        startTime = _startTime;
        endTime = _endTime;
        emit SetTimes(_startTime, _endTime);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit SetMerkleRoot(_merkleRoot);
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit SetPaused(_paused);
    }

    function setFinalized() external onlyOwner {
        finalized = true;
        emit SetFinalized();
    }

    function setFcfsAllocation(bool open) external onlyOwner {
        fcfsOpen = open;
        emit SetFcfsOpen(open);
    }

    function setFcfsAllocation(uint amount) external onlyOwner {
        fcfsAllocation = amount;
        emit SetFcfsAllocation(amount);
    }

    function getParams() external view returns (uint, uint, uint, uint, uint, bool, bool) {
        return (startTime, endTime, raisingAmount, offeringAmount, totalAmount, paused, finalized);
    }

    function getUserInfo(address _user) public view returns (uint, uint, uint, uint) {
        UserInfo memory userInfo = userInfos[_user];
        uint owed = (userInfo.amount * offeringAmount) / raisingAmount;
        //uint progress = _min(block.timestamp - _min(block.timestamp, endTime), vestingDuration);
        uint claimable = (owed * vestingInitial) / 1e12;
        //claimable += ((owed - claimable) * progress) / vestingDuration;
        if (block.timestamp > endTime + vestingDuration) {
            claimable = owed;
        }
        return (userInfo.amount, userInfo.claimed, owed, claimable);
    }

    function _deposit(address user, uint amount, uint allocation, bytes32[] memory merkleProof) internal nonReentrant {
        UserInfo storage userInfo = userInfos[user];
        require(!paused, "paused");
        require(amount > 0, "need amount > 0");
        bytes32 node = keccak256(abi.encodePacked(user, allocation));
        if (!fcfsOpen) {
            require(MerkleProof.verify(merkleProof, merkleRoot, node), "invalid proof");
        }

        if (block.timestamp > endTime + 30 minutes) {
            // no cap
            require(totalAmount + amount <= raisingAmount, "sold out");
        } else if (block.timestamp > endTime) {
            // add fcfs allocation to all participants
            require(totalAmount + amount <= raisingAmount, "sold out");
            require(userInfo.amount + amount <= allocation + fcfsAllocation, "over allocation");
        } else {
            require(block.timestamp >= startTime && block.timestamp <= endTime, "sale not active");
            require(userInfo.amount + amount <= allocation, "over allocation");
        }


        if (userInfo.amount == 0) {
            totalUsers += 1;
        }
        userInfo.amount = userInfo.amount + amount;
        totalAmount = totalAmount + amount;
        emit Deposit(user, amount);
    }

    function depositNative(uint allocation, bytes32[] calldata merkleProof) public payable {
        require(address(paymentToken) == address(0), "paymentToken is not native");
        _deposit(msg.sender, msg.value, allocation, merkleProof);
    }

    function deposit(uint amount, uint allocation, bytes32[] calldata merkleProof) public {
        require(address(paymentToken) != address(0), "paymentToken is native");
        paymentToken.safeTransferFrom(msg.sender, address(this), amount);
        _deposit(msg.sender, amount, allocation, merkleProof);
    }

    function onTokenTransfer(address user, uint amount, bytes calldata data) external override {
        require(msg.sender == address(paymentToken), "onTokenTransfer: not paymentToken");
        (uint allocation, bytes32[] memory merkleProof) = abi.decode(data, (uint, bytes32[]));
        _deposit(user, amount, allocation, merkleProof);
    }

    function harvest() external nonReentrant {
        (uint contributed, uint claimed, , uint claimable) = getUserInfo(msg.sender);

        require(!paused, "paused");
        require(block.timestamp > endTime, "sale not ended");
        require(finalized, "not finalized");
        require(contributed > 0, "have you participated?");

        uint amount = claimable - claimed;
        require(amount > 0, "no amount available for claiming");

        userInfos[msg.sender].claimed += amount;
        offeringToken.safeTransfer(address(msg.sender), amount);
        emit Harvest(msg.sender, amount);
    }

    function withdrawToken(address token, uint amount) external onlyOwner {
        if (token == address(0)) {
            (bool sent,) = msg.sender.call{value: amount}("");
            require(sent, "failed to send");
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
    }

    function _min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
}
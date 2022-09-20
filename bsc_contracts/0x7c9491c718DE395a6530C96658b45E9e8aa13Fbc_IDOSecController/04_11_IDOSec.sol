// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";// using SafeMath for uint256;

import "../interfaces/IDOSec/IIDOSecController.sol";



/** @title IDO contract does IDO
 * @notice
 */
contract IDOSec is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct User {
        uint256 totalFunded; // total funded amount of user
        uint256 released; // currently released token amount
    }

    uint256 public constant ROUNDS_COUNT = 2; // 1: whitelist, 2: fcfs

    IIDOSecController public controller;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimTime;

    IERC20 public saleToken;
    uint256 public saleTarget;
    uint256 public saleRaised;

    // 0x0 BNB, other: BEP20
    address public fundToken;
    uint256 public fundTarget;
    uint256 public fundRaised;
    uint256 public totalReleased;
    
    //
    uint256 public fcfsAmount; // users' fcfs allocation
    uint256 public minFundAmount;

    string public meta; // meta data json url

    // all funder Addresses
    address[] public funderAddresses; // helper for mapping
    mapping(address => User) public whitelistFunders;
    mapping(address => User) public fcfsFunders;

    // vesting info
    uint256 public cliffTime;
    // 15 = 1.5%, 1000 = 100%
    uint256 public distributePercentAtClaim; // percent of amount on each claim
    uint256 public vestingDuration;
    uint256 public vestingPeriodicity;

    // whitelist
    mapping(address => uint256) public whitelistAmount;
    // keep each round got how much funds
    mapping(uint256 => uint256) public roundsFundRaised;

    event IDOInitialized(uint256 saleTarget, address fundToken, uint256 fundTarget);
    
    event IDOBaseDataChanged(
        uint256 startTime,
        uint256 endTime,
        uint256 claimTime,
        uint256 minFundAmount,
        uint256 fcfsAmount,
        string meta
    );
    event IDOTokenInfoChanged(uint256 saleTarget, uint256 fundTarget);

    event SaleTokenAddressSet(address saleToken);

    event VestingSet(
        uint256 cliffTime,
        uint256 distributePercentAtClaim,
        uint256 vestingDuration,
        uint256 vestingPeriodicity
    );

    event IDOProgressChanged(address buyer, uint256 amount, uint256 fundRaised, uint256 saleRaised, uint256 roundId);

    event IDOClaimed(address to, uint256 amount);

    modifier canRaise(address addr, uint256 amount) {
        uint256 currentRoundId = getCurrentRoundId();

        uint256 maxAllocation = getMaxAllocation(addr);

        require(amount > 0, "0 amount");

        require(fundRaised + amount <= fundTarget, "Target hit!");

        uint256 personalTotal;
        if (currentRoundId == 1) {
            personalTotal = amount + whitelistFunders[addr].totalFunded;
        } else if (currentRoundId == 2) {
            personalTotal = amount + fcfsFunders[addr].totalFunded;
        }

        require(personalTotal >= minFundAmount, "Low amount");
        require(personalTotal <= maxAllocation, "Too much amount");

        _;
    }

    modifier isOperatorOrOwner() {
        require(controller.isOperator(msg.sender) || owner() == msg.sender, "Not owner or operator");
        _;
    }

    modifier isNotStarted() {
        require(startTime > block.timestamp, "Already started");

        _;
    }

    modifier isOngoing() {
        require(startTime <= block.timestamp && block.timestamp <= endTime, "Not onging");

        _;
    }

    modifier isEnded() {
        require(block.timestamp >= endTime, "Not ended");

        _;
    }

    modifier isNotEnded() {
        require(block.timestamp < endTime, "Ended");

        _;
    }

    modifier isClaimable() {
        require(block.timestamp >= claimTime, "Not claimable");

        _;
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "should be EOA");
        _;
    }
    /**
     * @notice constructor
     *
     * @param _controller {address} Controller address
     * @param _saleTarget {uint256} Total token amount to sell
     * @param _fundToken {address} Fund token address
     * @param _fundTarget {uint256} Total amount of fund Token
     */
    constructor(
        IIDOSecController _controller,
        uint256 _saleTarget,
        address _fundToken,
        uint256 _fundTarget
    ) {
        require(address(_controller) != address(0), "Invalid controller address");
        require(_saleTarget > 0 && _fundTarget > 0, "Invalid target value");
        fundToken = _fundToken;
        saleTarget = _saleTarget;
        fundTarget = _fundTarget;

        controller = _controller;
        emit IDOInitialized(saleTarget, fundToken, fundTarget);

    }

    /**
     * @notice setBaseData
     *
     * @param _startTime {uint256}  timestamp of IDO start time
     * @param _endTime {uint256}  timestamp of IDO end time
     * @param _claimTime {uint256}  timestamp of IDO claim time
     * @param _minFundAmount {uint256}  mimimum fund amount of users
     * @param _fcfsAmount {uint256}  fcfsAmount of buy
     * @param _meta {string}  url of meta data
     */
    function setBaseData(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _claimTime,
        uint256 _minFundAmount,
        uint256 _fcfsAmount,
        string memory _meta
    ) external isOperatorOrOwner {
        require(_minFundAmount > 0, "0 minFund");
        require(_fcfsAmount > 0, "0 base");

        require(_startTime > block.timestamp && _startTime < _endTime && _endTime < _claimTime, "Invalid times");

        startTime = _startTime;
        endTime = _endTime;
        claimTime = _claimTime;
        minFundAmount = _minFundAmount;
        meta = _meta;
        fcfsAmount = _fcfsAmount;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, fcfsAmount, meta);
    }

    function getRoundTotalAllocation(uint256 currentRoundId) public view returns (uint256) {
        if (currentRoundId == 0) {
            return 0;
        }
        if (currentRoundId == 1) {
            return fundTarget;
        }
        return fundTarget - roundsFundRaised[1];
    }

    function getFunderInfo(address funder) external view returns (User memory) {
        User memory info;

        info.totalFunded = whitelistFunders[funder].totalFunded + fcfsFunders[funder].totalFunded;

        info.released = whitelistFunders[funder].released + fcfsFunders[funder].released;

        return info;
    }

    function getFundersCount() external view returns (uint256) {
        return funderAddresses.length;
    }

    function getCurrentRoundId() public view returns (uint256) {
        if (block.timestamp < startTime || block.timestamp > endTime) {
            return 0; // not started
        }
        uint256 roundDuration = (endTime - startTime) / ROUNDS_COUNT;
        uint256 index = (block.timestamp - startTime) / roundDuration;

        // 1: white, 2: fcfs
        return index + 1;
    }

    function getMaxAllocation(address addr) public view returns (uint256) {
        uint256 currentRoundId = getCurrentRoundId();

        if (currentRoundId == 0) {
            return 0;
        }

        if (currentRoundId == 1) {
            // whitelist period
            return whitelistAmount[addr];
        }
        return fcfsAmount;
    }

    function setStartTime(uint256 _startTime) external isOperatorOrOwner isNotStarted {
        require(_startTime > block.timestamp, "Invalid");
        startTime = _startTime;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, fcfsAmount, meta);
    }

    function setEndTime(uint256 _endTime) external isOperatorOrOwner isNotEnded {
        require(_endTime > block.timestamp && _endTime > startTime, "Invalid");

        endTime = _endTime;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, fcfsAmount, meta);
    }

    function setClaimTime(uint256 _claimTime) external isOperatorOrOwner {
        require(_claimTime > block.timestamp && _claimTime > endTime, "Invalid");

        claimTime = _claimTime;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, fcfsAmount, meta);
    }

    function setFcFsAmount(uint256 _fcfsAmount) external isOperatorOrOwner {
        require(_fcfsAmount > 0, "Invalid");

        fcfsAmount = _fcfsAmount;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, fcfsAmount, meta);
    }

    function setMinFundAmount(uint256 _minFundAmount) external isOperatorOrOwner {
        require(_minFundAmount > 0, "Invalid");

        minFundAmount = _minFundAmount;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, fcfsAmount, meta);
    }

    function setMeta(string memory _meta) external isOperatorOrOwner {
        meta = _meta;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, fcfsAmount, meta);
    }

    function setSaleToken(IERC20 _saleToken) external isOperatorOrOwner {
        require(address(_saleToken) != address(0), "Invalid");

        saleToken = _saleToken;
        emit SaleTokenAddressSet(address(saleToken));
    }

    function setSaleTarget(uint256 _saleTarget) external isOperatorOrOwner {
        require(_saleTarget > 0, "Invalid");
        saleTarget = _saleTarget;
        emit IDOTokenInfoChanged(saleTarget, fundTarget);
    }

    function setFundTarget(uint256 _fundTarget) external isOperatorOrOwner {
        require(_fundTarget > 0, "Invalid");
        fundTarget = _fundTarget;
        emit IDOTokenInfoChanged(saleTarget, fundTarget);
    }

    function setVestingInfo(
        uint256 _cliffTime,
        uint256 _distributePercentAtClaim,
        uint256 _vestingDuration,
        uint256 _vestingPeriodicity
    ) external isOperatorOrOwner {
        require(_cliffTime > claimTime, "Invalid Cliff");
        require(_distributePercentAtClaim <= 1000, "Invalid tge");// Token generation event
        require(_vestingDuration > 0 && _vestingPeriodicity > 0, "0 Duration or Period");
        require(
            (_vestingDuration - (_vestingDuration / _vestingPeriodicity) * _vestingPeriodicity) == 0,
            "Not divided"
        );

        cliffTime = _cliffTime;
        distributePercentAtClaim = _distributePercentAtClaim;
        vestingDuration = _vestingDuration;
        vestingPeriodicity = _vestingPeriodicity;

        emit VestingSet(cliffTime, distributePercentAtClaim, vestingDuration, vestingPeriodicity);
    }
    function getUnlockedTokenAmount(address addr, uint256 remainFundedAmount) private view returns (uint256) {
        require(addr != address(0), "Invalid address!");
        if (block.timestamp < claimTime) return 0;

        uint256 totalRemainSaleToken = (remainFundedAmount * saleTarget) / fundTarget;

        // calculate in this time, he can get how many token
        uint256 distributeAmountAtClaim = (totalRemainSaleToken * distributePercentAtClaim) / 1000;

        if (cliffTime > block.timestamp) {
            return distributeAmountAtClaim;
        }

        if (cliffTime == 0) {
            // vesting info is not set yet
            return 0;
        }

        uint256 finalTime = cliffTime + vestingDuration - vestingPeriodicity;

        if (block.timestamp >= finalTime) {
            return totalRemainSaleToken;
        }

        uint256 lockedAmount = totalRemainSaleToken - distributeAmountAtClaim;

        uint256 totalPeriodicities = vestingDuration / vestingPeriodicity;
        uint256 periodicityAmount = lockedAmount / totalPeriodicities;
        uint256 currentperiodicityCount = (block.timestamp - cliffTime) / vestingPeriodicity + 1;
        uint256 availableAmount = periodicityAmount * currentperiodicityCount;

        return distributeAmountAtClaim + availableAmount;
    }

    function getWhitelistClaimableAmount(address addr) private view returns (uint256) {
        return getUnlockedTokenAmount(addr, whitelistFunders[addr].totalFunded) - whitelistFunders[addr].released;
    }

    function getFCFSClaimableAmount(address addr) private view returns (uint256) {
        return getUnlockedTokenAmount(addr, fcfsFunders[addr].totalFunded) - fcfsFunders[addr].released;
    }

    function getClaimableAmount(address addr) public view returns (uint256) {
        return getWhitelistClaimableAmount(addr) + getFCFSClaimableAmount(addr);
    }

    function _claimTo(address to) private {
        require(to != address(0), "Invalid address");
        uint256 claimableAmount = getClaimableAmount(to);
        if (claimableAmount > 0) {
            // .released refer to saleToken
            whitelistFunders[to].released = whitelistFunders[to].released + getWhitelistClaimableAmount(to);
            fcfsFunders[to].released = fcfsFunders[to].released + getFCFSClaimableAmount(to);
            saleToken.safeTransfer(to, claimableAmount);
            totalReleased = totalReleased + claimableAmount; // saleToken
            emit IDOClaimed(to, claimableAmount);
        }
    }

    function claim() external isClaimable nonReentrant onlyEOA {
        uint256 claimableAmount = getClaimableAmount(msg.sender);
        require(claimableAmount > 0, "Nothing to claim");
        _claimTo(msg.sender);
    }

    function batchClaim(address[] calldata addrs) external isClaimable nonReentrant onlyEOA {
        for (uint256 index = 0; index < addrs.length; index++) {
            _claimTo(addrs[index]);
        }
    }

    function withdrawRemainingSaleToken() external isOperatorOrOwner {
        require(block.timestamp > endTime, "IDO has not yet ended");
        saleToken.safeTransfer(msg.sender, saleToken.balanceOf(address(this)) + totalReleased - saleRaised);
    }

    function withdrawFundedBNB() external isOperatorOrOwner isEnded {
        require(fundToken == address(0), "It's not BNB-buy pool!");

        uint256 balance = address(this).balance;

        (address feeRecipient, uint256 feePercent) = controller.getFeeInfo();

        uint256 fee = (balance * (feePercent)) / (1000);
        uint256 restAmount = balance - (fee);

        (bool success, ) = payable(feeRecipient).call{ value: fee }("");
        require(success, "BNB fee pay failed");
        (bool success1, ) = payable(msg.sender).call{ value: restAmount }("");
        require(success1, "BNB withdraw failed");
    }

    function withdrawFundedToken() external isOperatorOrOwner isEnded {
        require(fundToken != address(0), "It's not token-buy pool!");

        uint256 balance = IERC20(fundToken).balanceOf(address(this));

        (address feeRecipient, uint256 feePercent) = controller.getFeeInfo();
        uint256 fee = (balance * feePercent) / 1000;
        uint256 restAmount = balance - fee;

        IERC20(fundToken).safeTransfer(feeRecipient, fee);
        IERC20(fundToken).safeTransfer(msg.sender, restAmount);
    }

    function _processBuy(address buyer, uint256 amount) private {
        uint256 saleTokenAmount = (amount * saleTarget) / fundTarget;
        uint256 currentRoundId = getCurrentRoundId();

        fundRaised = fundRaised + amount;
        saleRaised = saleRaised + saleTokenAmount;

        uint256 roundId = currentRoundId;

        if (currentRoundId == 1) {
            // whitelist
            if (whitelistFunders[buyer].totalFunded == 0) {
                funderAddresses.push(buyer);
            }

            whitelistFunders[buyer].totalFunded = whitelistFunders[buyer].totalFunded + amount;
        } else if (currentRoundId == 2) {
            // fcfs
            if (whitelistFunders[buyer].totalFunded == 0 && fcfsFunders[buyer].totalFunded == 0) {
                funderAddresses.push(buyer);
            }

            fcfsFunders[buyer].totalFunded = fcfsFunders[buyer].totalFunded + amount;
        }

        roundsFundRaised[roundId] = roundsFundRaised[roundId] + amount;

        emit IDOProgressChanged(buyer, amount, fundRaised, saleRaised, currentRoundId);
    }

    function buyWithBNB() public payable isOngoing canRaise(msg.sender, msg.value) onlyEOA {
        // No set fundToken, then we accept user buy token by BNB
        require(fundToken == address(0), "It's not BNB-buy pool!");
        // Check msg.value == 

        _processBuy(msg.sender, msg.value);
    }

    function buy(uint256 amount) public isOngoing canRaise(msg.sender, amount) onlyEOA {
        require(fundToken != address(0), "It's not token-buy pool!");

        _processBuy(msg.sender, amount);

        IERC20(fundToken).safeTransferFrom(msg.sender, address(this), amount);
    }

    function setWhitelist(address[] calldata addrs, uint256[] calldata amounts) external isOperatorOrOwner {
        require(addrs.length == amounts.length, "Invalid params");

        for (uint256 index = 0; index < addrs.length; index++) {
            whitelistAmount[addrs[index]] = amounts[index];
        }
    }

    receive() external payable {
        revert("Something went wrong!");
    }
}
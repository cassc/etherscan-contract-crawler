// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (finance/VestingWallet.sol)
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/governance/utils/Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TSVesting is EIP712,Votes,Ownable,ReentrancyGuard {
    event TokenReleased(address indexed vestingContract, address indexed user, uint256 amount);

    mapping(address => uint256) private _released;
    mapping(address =>uint256 ) private _balances;
    address private immutable _tokenAdd;
    uint64 private immutable _start;
    uint64 private immutable _duration;
    address public tsSaleFactory;
    address private tokenRefund;
    uint256 public total;
    uint256 public totalUserInvest;
    mapping (address => bool) private isRefund;
    bool private refund = false;
    uint256 public rate = 0;
    uint256 public constant BPS = 1000000;
    
    address private governor;
    uint256 public totalBalanceRefund;
    uint256 public feeRefund;
    address private startup;

    constructor(
        address tokenAdd,
        uint64 startTimestamp,
        uint64 durationSeconds,
        address _tsSaleFactory
    )EIP712("TSVote", "1") {
        require(tokenAdd != address(0), "TSVesting: tokenAddress is zero address");
        require(_tsSaleFactory != address(0), "TSVesting: saleContract is zero address");
        _tokenAdd = tokenAdd;
        _start = startTimestamp;
        _duration = durationSeconds;
        tsSaleFactory = _tsSaleFactory;
    }
    modifier onlyGovernor(){
        require(msg.sender == governor,"TSVesting: only governor execute");
        _;
    }

    function setRefundInfo(uint256 _totalBalanceRefund, uint256 _feeRefund) public onlyGovernor {
        refund = true;
        totalBalanceRefund = _totalBalanceRefund;
        feeRefund = _feeRefund;
    }
    function addRate(uint256 _rate) external onlyGovernor{
        require(rate + _rate <= BPS, "TSVesting: rate invalid");
        rate += _rate;
    }
    function _getVotingUnits(address account) internal view virtual override returns (uint256) {
        return _balances[account];
    }

    function initValue(address _startup, address _governor, address _tokenRefund, uint256 _totalTokenSellActual, uint256 _totalUserInvest)  external{
        require(msg.sender == tsSaleFactory,"TSVesting: only tsSaleFactory call");
        total = _totalTokenSellActual;
        startup = _startup; 
        governor = _governor;
        tokenRefund = _tokenRefund;
        totalUserInvest = _totalUserInvest;
    }

    function deposit(address user, uint256 amount)  external{
        require(msg.sender == tsSaleFactory,"TSVesting: only tsSaleFactory deposit");
        _balances[user]+=amount;
        SafeERC20.safeTransferFrom(IERC20(_tokenAdd), _msgSender(), address(this), amount);
    }

    function tokenAddress() public view virtual returns (address) {
        return _tokenAdd;
    }

    function start() public view virtual returns (uint256) {
        return _start;
    }

    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    function governorAddress() public view virtual returns (address) {
        return governor;
    }

    function startupAddress() public view virtual returns (address) {
        return startup;
    }

    function tokenAddressRefund() public view virtual returns (address) {
        return tokenRefund;
    }

    function released(address user) public view virtual returns (uint256) {
        return _released[user];
    }
    function getBalanceVesting(address account) external view returns (uint256) {
        return _balances[account];
    }
    /**
    * Refund for vc
    */
    function getBalanceRefund(address account) external view returns (uint256 amountRemaining, uint256 amountClaimed, uint256 fee){
        amountRemaining = isRefund[account] ? 0 :totalBalanceRefund * _balances[account] / total;
        amountClaimed = isRefund[account] ? totalBalanceRefund *_balances[account] / total: 0;
        fee = feeRefund * _balances[account] / total;
    }
    function claimRefund(address user) external  nonReentrant{
        require(refund,"TSVesting: not refund");
        require(isRefund[user]==false, "TSVesting: user claimed");
        isRefund[user] = true;
        uint256 amountRefund = totalBalanceRefund * _balances[user] / total;
        SafeERC20.safeTransfer(IERC20(tokenRefund),user, amountRefund);
    }
    /**
     * Refund for startup
     */
    function getTokenRefund() external view returns (uint256 amountRemaining, uint256 amountClaimed){
        amountRemaining = isRefund[startup] ? 0 : total * (BPS - rate) / BPS;
        amountClaimed = isRefund[startup] ? total * (BPS - rate) / BPS : 0;
    }
    function claimTokenRefund() external nonReentrant{
        require(refund,"TSVesting: not refund");
        require(msg.sender==startup,"TSVesting: only startup call");
        require(isRefund[_msgSender()]==false, "TSVesting: user claimed");
        isRefund[_msgSender()] = true;
        uint256 amountRemaining = total * (BPS - rate) / BPS;
        SafeERC20.safeTransfer(IERC20(_tokenAdd), startup, amountRemaining);
    }
    /**
     * Vesting token by schedule
     */
    function release(address user) public virtual {
        uint256 releasable = vestedAmount(user, uint64(block.timestamp)) - released(user);
        _released[user] += releasable;
        emit TokenReleased(address(this), user, releasable);
        SafeERC20.safeTransfer(IERC20(_tokenAdd),user, releasable);
    }
  
    function vestedAmount(address user, uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(_balances[user]*rate/BPS, timestamp);
    }
   
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view virtual returns (uint256) {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp > start() + duration()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start())) / duration();
        }
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IClaimable {
    function claim() external returns (uint amount);

    event Claim(address indexed account, uint amount);
}

interface IVester {
    function getUnlockedAmount() external view returns (uint256 amount, uint256 currentPoint);
}

contract LiqBootstrap is Ownable, ReentrancyGuard, IClaimable {
    using SafeERC20 for IERC20;

    address public immutable MON = 0x1EA48B9965bb5086F3b468E50ED93888a661fc17; // MON (Ethereum)
    address public vestingContract; // Vester Contract

    uint256 public periodBegin;
    uint256 public periodEnd;
    bool public ended = false;

    uint256 public totalShares;
    uint256 public shareIndex;

    uint256 public MAX_AMOUNT = 20 ether;
    uint256 public MIN_AMOUNT = 0.2 ether;
    uint256 public TVL_CAP = 750 ether;

    struct Recipient {
        uint256 shares;
        uint256 lastShareIndex;
        uint256 credit;
    }

    mapping(address => Recipient) public recipients;

    event Deposit(address indexed sender, uint256 amount, uint256 totalShares, uint256 newShares);
    event Delivered(uint256 balance, address recipient);
    event DelayEndPeriod(uint256 prevPeriodEnd, uint256 periodEnd);
    event Ended(uint256 balanceETH);

    event UpdateShareIndex(uint256 shareIndex);
    event UpdateCredit(address indexed account, uint256 lastShareIndex, uint256 credit);
    event EditRecipient(address indexed account, uint256 shares, uint256 totalShares);

    constructor(address _vestingContract) {
        vestingContract = _vestingContract;
    }

    function startEvent(uint256 _hours) public onlyOwner {
        require(periodBegin == 0, "Already started");
        require(_hours > 0 && _hours < 100, "Invalid period duration");
        periodBegin = getBlockTimestamp();
        periodEnd = periodBegin + _hours * 1 hours;
    }

    function delayEndPeriod(uint256 _hours) public onlyOwner {
        require(_hours > 0 && _hours < 100, "Invalid period duration");
        uint256 prevPeriodEnd = periodEnd;
        periodEnd = periodEnd + _hours * 1 hours;
        emit DelayEndPeriod(prevPeriodEnd, periodEnd);
    }

    function deliverEtherToProtocol() public onlyOwner {
        require(ended, "Not ended yet");
        require(getBlockTimestamp() >= periodEnd, "Before release time");

        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Sending ETH failed");

        emit Delivered(balance, msg.sender);
    }

    function endEvent() public onlyOwner {
        require(!ended, "Already ended");
        uint256 blockTimestamp = getBlockTimestamp();
        require(blockTimestamp >= periodEnd, "Too early to end");

        uint256 balanceETH = address(this).balance;

        ended = true;
        emit Ended(balanceETH);
    }

    function deposit() external payable nonReentrant {
        require(!ended, "Event has already ended");
        uint256 blockTimestamp = getBlockTimestamp();
        require(blockTimestamp >= periodBegin, "Too early for making a deposit");
        require(blockTimestamp < periodEnd, "Too late for making a deposit");
        require(msg.value >= MIN_AMOUNT, "Min deposit is required");
        require(address(this).balance + msg.value <= TVL_CAP, "Tvl limit reached");

        // User shares update according to the deposited amount
        uint256 prevShares = recipients[msg.sender].shares;
        uint256 newShares = prevShares + msg.value;
        require(newShares <= MAX_AMOUNT, "Max deposit limit is reached");
        _editRecipient(msg.sender, newShares);

        emit Deposit(msg.sender, msg.value, totalShares, newShares);
    }

    function claim() external override returns (uint256 amount) {
        return _claimInternal(msg.sender);
    }

    function _claimInternal(address account) internal returns (uint256 amount) {
        amount = _updateCredit(account);
        if (amount > 0) {
            recipients[account].credit = 0;
            IERC20(MON).safeTransfer(account, amount);
            emit Claim(account, amount);
        }
    }

    function _editRecipient(address account, uint256 shares) internal {
        Recipient storage recipient = recipients[account];
        uint256 prevShares = recipient.shares;
        uint256 _totalShares = shares > prevShares
            ? totalShares + (shares - prevShares)
            : totalShares - (prevShares - shares);
        totalShares = _totalShares;
        recipient.shares = shares;
        emit EditRecipient(account, shares, _totalShares);
    }

    function _updateCredit(address account) internal returns (uint256 credit) {
        uint256 _shareIndex = _updateShareIndex();
        if (_shareIndex == 0) return 0;
        Recipient storage recipient = recipients[account];
        credit = recipient.credit + ((_shareIndex - recipient.lastShareIndex) * recipient.shares) / 2**160;
        recipient.lastShareIndex = _shareIndex;
        recipient.credit = credit;
        emit UpdateCredit(account, _shareIndex, credit);
    }

    function _updateShareIndex() internal returns (uint256 _shareIndex) {
        if (totalShares == 0) return shareIndex;
        uint256 amount = IClaimable(vestingContract).claim();
        if (amount == 0) return shareIndex;
        _shareIndex = ((amount * 2**160) / totalShares) + shareIndex;
        shareIndex = _shareIndex;
        emit UpdateShareIndex(_shareIndex);
    }

    function getUserClaimable(address account) public view returns (uint256 amount) {
        uint256 _shareIndex = getShareIndex();
        Recipient memory recipient = recipients[account];
        amount = recipient.credit + ((_shareIndex - recipient.lastShareIndex) * recipient.shares) / 2**160;
    }

    function getShareIndex() public view returns (uint256 _shareIndex) {
        (uint256 amount, ) = IVester(vestingContract).getUnlockedAmount();
        _shareIndex = ((amount * 2**160) / totalShares) + shareIndex;
    }

    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    // In case some other tokens get stuck in the contract (MON excluded)
    function sweep(address _token) external onlyOwner {
        require(_token != MON, "!Valid");
        IERC20(_token).safeTransfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    function setTvlCap(uint256 _tvlCap) external onlyOwner {
        TVL_CAP = _tvlCap;
    }

    function setMinAndMax(uint256 _min, uint256 _max) external onlyOwner {
        MIN_AMOUNT = _min;
        MAX_AMOUNT = _max;
    }

    // In case it is needed to redeploy the Vesting Contract
    function setVestingContract(address _vestingContract) external onlyOwner {
        vestingContract = _vestingContract;
    }

    receive() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}
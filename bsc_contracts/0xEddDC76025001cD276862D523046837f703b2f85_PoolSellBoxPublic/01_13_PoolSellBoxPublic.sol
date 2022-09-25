// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IAmetaBox.sol";

contract PoolSellBoxPublic is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    string public name;
    // The reward wallet
    address public rewardFrom;
    // token deposit
    IERC20 public tokenDeposit;
    IAmetaBox public nftClaim;

    uint256 public totalAllocation;
    uint256 public boxType;
    uint256 public price;
    uint256 public startTime;
    uint256 public endTime;

    uint256 public totalDeposit;
    uint256 public totalClaimed;
    uint256 public countQtyDeposit;

    EnumerableSet.AddressSet private usersDeposited;
    // wallet address => qty box Deposited
    mapping(address => uint256) public qtyDepositedOfUser;
    // wallet address => qty box Deposited
    mapping(address => uint256) public qtyClaimedOfUser;

    event Deposit(address indexed user, uint256 indexed qty);
    event Claim(address indexed user, uint256 indexed qty);
    event Refund(address indexed user, uint256 indexed qty, uint256 amount);

    constructor(string memory _name, address _rewardFrom) {
        name = _name;
        rewardFrom = _rewardFrom;
        totalDeposit = 0;
    }

    // Modifier time deposit
    modifier verifyTimeActive() {
        require(
            startTime >= 0 && startTime <= block.timestamp,
            "PoolSellBoxPublic: Pool not active time"
        );
        require(
            endTime >= block.timestamp,
            "PoolSellBoxPublic: Expired time deposit"
        );
        _;
    }

    function setupParams(
        address _tokenDeposit,
        address _nftClaim,
        uint256 _totalAllocation,
        uint256 _boxType,
        uint256 _price
    ) external nonReentrant onlyOwner {
        require(_tokenDeposit != address(0), "Token claim zero address");
        require(_price > 0, "Price zero");
        tokenDeposit = IERC20(_tokenDeposit);
        nftClaim = IAmetaBox(_nftClaim);
        require(nftClaim.validateBoxType(_boxType), "Invalid box type");
        totalAllocation = _totalAllocation;
        boxType = _boxType;
        price = _price;
    }

    function setRewardFrom(address _rewardFrom)
        external
        nonReentrant
        onlyOwner
    {
        require(_rewardFrom != address(0), "Address zero");
        rewardFrom = _rewardFrom;
    }

    function setTimeActive(uint256 _startTime, uint256 _endTime)
        external
        nonReentrant
        onlyOwner
    {
        require(_startTime != 0, "Start time Zero");
        require(_startTime <= _endTime, "Time deposit invalid");
        startTime = _startTime;
        endTime = _endTime;
    }

    function setPrice(uint256 _price) external nonReentrant onlyOwner {
        price = _price;
    }

    function emergencyWithdrawToken(address _tokenAddress, uint256 _amount)
        external
        nonReentrant
        onlyOwner
    {
        require(msg.sender != address(0), "Invalid address");
        require(address(_tokenAddress) != address(0), "Invalid address");
        IERC20(_tokenAddress).safeTransfer(rewardFrom, _amount);
    }

    function withdrawTokenDeposit(uint256 _amount)
        external
        nonReentrant
        onlyOwner
    {
        require(msg.sender != address(0), "Invalid address");
        require(address(tokenDeposit) != address(0), "Invalid address");
        tokenDeposit.safeTransfer(rewardFrom, _amount);
    }

    function _getGrantedDeposit() private view returns (bool) {
        if (block.timestamp < startTime) {
            return false;
        }
        if (block.timestamp > endTime) {
            return false;
        }
        if (totalAllocation <= totalDeposit) {
            return false;
        }
        return true;
    }

    function deposit(uint256 _qty) external nonReentrant verifyTimeActive {
        require(price > 0, "Price zero");
        require(_qty > 0, "Qty zero");
        require(
            totalDeposit + _qty <= totalAllocation,
            "PoolSellBoxPublic: Over pool size"
        );
        // sendtoken to pool
        tokenDeposit.safeTransferFrom(
            address(msg.sender),
            address(this),
            _qty * price
        );
        // set user deposit
        usersDeposited.add(msg.sender);
        qtyDepositedOfUser[msg.sender] += _qty;
        totalDeposit += _qty;
        countQtyDeposit += _qty;
        emit Deposit(msg.sender, _qty);
    }

    function claim(uint256 _qty) external nonReentrant {
        require(_qty > 0, "PoolSellBoxPublic:Qty zero");
        uint256 qtyDeposited = qtyDepositedOfUser[msg.sender];
        uint256 qtyClaimed = qtyClaimedOfUser[msg.sender];
        require(
            _qty + qtyClaimed <= qtyDeposited,
            "PoolSellBoxPublic: Over qty per user"
        );
        nftClaim.mintBatch(msg.sender, _qty, boxType);
        qtyClaimedOfUser[msg.sender] += _qty;
        totalClaimed += _qty;
        emit Claim(msg.sender, _qty);
    }

    function claimAll() external nonReentrant {
        uint256 qtyDeposited = qtyDepositedOfUser[msg.sender];
        uint256 qtyClaimed = qtyClaimedOfUser[msg.sender];
        uint256 qty = qtyDeposited - qtyClaimed;
        require(qty > 0, "PoolSellBoxPublic: Over qty per user");
        nftClaim.mintBatch(msg.sender, qty, boxType);
        qtyClaimedOfUser[msg.sender] += qty;
        totalClaimed += qty;
        emit Claim(msg.sender, qty);
    }

    function refund(uint256 _qty) external nonReentrant verifyTimeActive {
        require(_qty > 0, "PoolSellBoxPublic:Qty zero");
        uint256 qtyDeposited = qtyDepositedOfUser[msg.sender];
        uint256 qtyClaimed = qtyClaimedOfUser[msg.sender];
        require(
            _qty + qtyClaimed <= qtyDeposited,
            "PoolSellBoxPublic: Over qty per user"
        );

        tokenDeposit.safeTransfer(msg.sender, price * _qty);
        qtyDepositedOfUser[msg.sender] -= _qty;
        totalDeposit -= _qty;
        emit Refund(msg.sender, _qty, price * _qty);
    }

    function refundAll() external nonReentrant verifyTimeActive {
        uint256 qtyDeposited = qtyDepositedOfUser[msg.sender];
        uint256 qtyClaimed = qtyClaimedOfUser[msg.sender];
        uint256 qty = qtyDeposited - qtyClaimed;
        require(qty > 0, "PoolSellBoxPublic: Over qty per user");
        tokenDeposit.safeTransfer(msg.sender, price * qty);
        qtyDepositedOfUser[msg.sender] -= qty;
        totalDeposit -= qty;
        emit Refund(msg.sender, qty, price * qty);
    }

    function viewUsersDeposited(uint256 _pageIndex, uint256 _pageSize)
        external
        view
        returns (address[] memory data, uint256 total)
    {
        total = usersDeposited.length();
        uint256 startIndex = (_pageIndex - 1) * _pageSize;
        if (startIndex >= total) {
            return (new address[](0), total);
        }
        uint256 endIndex = _pageIndex * _pageSize > total
            ? total
            : _pageIndex * _pageSize;
        data = new address[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            data[i - startIndex] = usersDeposited.at(i);
        }
        return (data, total);
    }

    function viewPoolInfo()
        external
        view
        returns (
            uint256 totalQtyDeposit,
            uint256 totalQtyAllocation,
            uint256 totalQtyClaimed,
            uint256 priceBox
        )
    {
        return (totalDeposit, totalAllocation, totalClaimed, price);
    }

    function viewUserInfo(address _user)
        external
        view
        returns (
            uint256 qtyDeposited,
            uint256 qtyClaimed,
            bool grantedDeposit,
            bool grantedClaim,
            bool grantedRefund
        )
    {
        qtyDeposited = qtyDepositedOfUser[_user];
        qtyClaimed = qtyClaimedOfUser[_user];
        grantedDeposit = _getGrantedDeposit();
        grantedClaim = qtyDeposited > qtyClaimed;
        grantedRefund = qtyDeposited > qtyClaimed;
        return (
            qtyDeposited,
            qtyClaimed,
            grantedDeposit,
            grantedClaim,
            grantedRefund
        );
    }
}
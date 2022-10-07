// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "./interfaces/IAmetaBox.sol";

contract PoolStakingFixed is Pausable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    address private constant ZERO_ADDRESS = address(0);

    string public name;
    IERC20 public tokenStaked;
    IAmetaBox public nftReward;
    uint256 public startTime;
    uint256 public endTime;

    struct PackageInput {
        uint256 price;
        uint256 boxType;
        uint256 timeLock;
        uint256 totalAllocation;
    }

    struct PackageInfo {
        uint256 price;
        uint256 boxType;
        uint256 timeLock;
        uint256 totalAllocation;
        uint256 totalBought;
        uint256 totalValueLocked;
    }

    struct Order {
        uint256 orderId;
        uint256 amount;
        uint256 startTimeLock;
        uint256 endTimeLock;
        uint256 packageIndex;
        bool hasWithdraw;
    }

    // startIndex to 1
    EnumerableSet.UintSet private packageIndexs;

    // packageIndex => PackageInfo
    mapping(uint256 => PackageInfo) public packageInfos;

    uint256 public totalOrders;
    // user => listOrderIds
    mapping(address => EnumerableSet.UintSet) private orderIdsOfUser;
    // user => packageIndex => total amount staked
    mapping(address => mapping(uint256 => uint256)) public amountStakedOfUser;
    // orderId => Order
    mapping(uint256 => Order) public orders;

    modifier verifyActiveTime() {
        require(
            startTime != 0 && startTime <= block.timestamp,
            "StakingPoolFixed: Pool not active by time"
        );
        require(
            endTime != 0 && endTime >= block.timestamp,
            "StakingPoolFixed: Pool end time"
        );
        _;
    }

    constructor(string memory _name) {
        name = _name;
    }

    function setupParams(
        address _tokenStaked,
        address _nftReward,
        uint256 _startTime,
        uint256 _endTime
    ) public onlyOwner nonReentrant {
        tokenStaked = IERC20(_tokenStaked);
        nftReward = IAmetaBox(_nftReward);
        startTime = _startTime;
        endTime = _endTime;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateTimeActice(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
        nonReentrant
    {
        startTime = _startTime;
        endTime = _endTime;
    }

    function setPackageInfo(PackageInput[] memory _packages)
        external
        onlyOwner
        nonReentrant
    {
        while (packageIndexs.length() > 0) {
            packageIndexs.remove(packageIndexs.at(0));
        }
        for (uint256 i = 0; i < _packages.length; i++) {
            uint256 packageIndex = i + 1;
            packageIndexs.add(packageIndex);
            PackageInfo storage packageInfo = packageInfos[packageIndex];
            packageInfo.boxType = _packages[i].boxType;
            packageInfo.price = _packages[i].price;
            packageInfo.totalAllocation = _packages[i].totalAllocation;
            packageInfo.timeLock = _packages[i].timeLock;
            packageInfos[packageIndex] = packageInfo;
        }
    }

    function viewPackageIndexs() external view returns (uint256[] memory) {
        return packageIndexs.values();
    }

    function viewPackageInfos()
        external
        view
        returns (PackageInfo[] memory data)
    {
        data = new PackageInfo[](packageIndexs.length());
        for (uint256 i = 0; i < packageIndexs.length(); i++) {
            data[i] = packageInfos[packageIndexs.at(i)];
        }
        return data;
    }

    function viewPackageInfoByIndex(uint256 _packageIndex)
        external
        view
        returns (PackageInfo memory)
    {
        return packageInfos[_packageIndex];
    }

    function viewOrderIdsOfUser(
        address _user,
        uint256 _pageIndex,
        uint256 _pageSize
    ) external view returns (uint256[] memory data, uint256 total) {
        total = orderIdsOfUser[_user].length();
        uint256 startIndex = (_pageIndex - 1) * _pageSize;
        if (startIndex >= total) {
            return (new uint256[](0), total);
        }
        uint256 endIndex = _pageIndex * _pageSize > total
            ? total
            : _pageIndex * _pageSize;
        data = new uint256[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            data[i - startIndex] = orderIdsOfUser[_user].at(i);
        }
        return (data, total);
    }

    function viewOrdersOfUser(
        address _user,
        uint256 _pageIndex,
        uint256 _pageSize
    ) external view returns (Order[] memory data, uint256 total) {
        total = orderIdsOfUser[_user].length();
        uint256 startIndex = (_pageIndex - 1) * _pageSize;
        if (startIndex >= total) {
            return (new Order[](0), total);
        }
        uint256 endIndex = _pageIndex * _pageSize > total
            ? total
            : _pageIndex * _pageSize;
        data = new Order[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            data[i - startIndex] = orders[orderIdsOfUser[_user].at(i)];
        }
        return (data, total);
    }

    function stake(uint256 _packageIndex)
        external
        whenNotPaused
        nonReentrant
        verifyActiveTime
    {
        require(
            packageIndexs.contains(_packageIndex),
            "Stake: Invalid package index"
        );

        PackageInfo storage packageInfo = packageInfos[_packageIndex];
        require(packageInfo.price > 0, "Stake: Invalid price package");
        require(
            packageInfo.totalAllocation > packageInfo.totalBought,
            "Stake: Package full"
        );
        uint256 price = packageInfo.price;
        uint256 timeLock = packageInfo.timeLock;
        uint256 boxType = packageInfo.boxType;
        tokenStaked.safeTransferFrom(address(msg.sender), address(this), price);

        // Mint Box to user
        nftReward.mint(address(msg.sender), boxType);

        // count qty buy to package
        packageInfo.totalBought++;
        packageInfo.totalValueLocked += price;

        // inc orderId
        totalOrders++;

        orderIdsOfUser[msg.sender].add(totalOrders);
        amountStakedOfUser[msg.sender][_packageIndex] += price;
        orders[totalOrders] = Order({
            orderId: totalOrders,
            amount: price,
            packageIndex: _packageIndex,
            startTimeLock: block.timestamp,
            endTimeLock: block.timestamp + timeLock,
            hasWithdraw: false
        });
    }

    function withdraw(uint256 _orderId) external whenNotPaused nonReentrant {
        require(
            orderIdsOfUser[msg.sender].contains(_orderId),
            "Withdraw: orderId not existed"
        );
        Order storage order = orders[_orderId];
        require(order.amount > 0, "Withdraw: order amount invalid");
        require(
            order.endTimeLock <= block.timestamp,
            "Withdraw: It's not time to withdraw"
        );
        // send token to user
        tokenStaked.safeTransfer(msg.sender, order.amount);
        amountStakedOfUser[msg.sender][order.packageIndex] -= order.amount;
        packageInfos[order.packageIndex].totalValueLocked -= order.amount;
        order.hasWithdraw = true;
    }
}
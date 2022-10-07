// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IDexRouter {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

contract PoolIdoKol is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    // 100% by multiplier=100
    uint256 private constant MAX_PERCENT_MULTIPLIER = 10000;

    string public name;
    // The wallet reward token
    address private rewardFrom;

    IERC20 public tokenClaim;

    IDexRouter public dexRouter;

    address[] public path;

    uint256 public endTimeRefund;
    uint256 public priceRefund;

    // swap rate  (example: (rateIn =10,rateOut=50) => 10 tokenIn = 50 tokenOut )
    uint256 public rateIn;
    uint256 public rateOut;

    uint256[] public startTimes;
    uint256[] public percents;

    // wallet address => amountDeposited
    mapping(address => uint256) public mapUserDeposited;

    // wallet address => amountClaimed
    mapping(address => uint256) public mapUserClaimed;

    EnumerableSet.AddressSet private userRequestRefund;

    uint256 public totalClaimed;

    constructor(string memory _name, address _rewardFrom) {
        name = _name;
        require(_rewardFrom != address(0), "Reward wallet invalid address");
        rewardFrom = _rewardFrom;
        totalClaimed = 0;
    }

    function setRewardFrom(address _rewardFrom)
        external
        nonReentrant
        onlyOwner
    {
        require(_rewardFrom != address(0), "Address zero");
        rewardFrom = _rewardFrom;
    }

    function setupParams(
        address _tokenClaim,
        uint256 _rateIn,
        uint256 _rateOut,
        address _dexRouter,
        uint256 _endTimeRefund,
        uint256 _priceRefund,
        address[] calldata _path
    ) external nonReentrant onlyOwner {
        require(_tokenClaim != address(0), "Address tokenClaim zero");
        tokenClaim = IERC20(_tokenClaim);
        require(
            _rateIn > 0,
            "Invalid rate rateIn, rateIn must be greater than 0"
        );
        rateIn = _rateIn;
        rateOut = _rateOut;
        dexRouter = IDexRouter(_dexRouter);
        endTimeRefund = _endTimeRefund;
        priceRefund = _priceRefund;
        path = _path;
    }

    function setRuleVestings(
        uint256[] calldata _startTimes,
        uint256[] calldata _percents
    ) external nonReentrant onlyOwner {
        startTimes = _startTimes;
        percents = _percents;
    }

    function updateUserDeposit(
        address[] calldata _wallets,
        uint256[] calldata _amountDepositeds
    ) external nonReentrant onlyOwner {
        if (_wallets.length != _amountDepositeds.length) {
            require(false, "Invalid input size");
        }
        if (_wallets.length > 100) {
            require(false, "Over input data");
        }
        for (uint256 i = 0; i < _wallets.length; i++) {
            mapUserDeposited[_wallets[i]] = _amountDepositeds[i];
        }
    }

    function viewStartTimes() public view returns (uint256[] memory) {
        return startTimes;
    }

    function viewPercents() public view returns (uint256[] memory) {
        return percents;
    }

    function viewUserRequestRefund(uint256 _pageIndex, uint256 _pageSize)
        external
        view
        returns (address[] memory data, uint256 total)
    {
        total = userRequestRefund.length();
        uint256 startIndex = (_pageIndex - 1) * _pageSize;
        if (startIndex >= total) {
            return (new address[](0), total);
        }
        uint256 endIndex = _pageIndex * _pageSize > total
            ? total
            : _pageIndex * _pageSize;
        data = new address[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            data[i - startIndex] = userRequestRefund.at(i);
        }
        return (data, total);
    }

    function _getUnlockPercentAt(uint256 _timestamp)
        private
        view
        returns (uint256 unlockPercent)
    {
        for (uint256 i = 0; i < startTimes.length; i++) {
            if (unlockPercent >= MAX_PERCENT_MULTIPLIER) {
                return MAX_PERCENT_MULTIPLIER;
            }
            if (_timestamp < startTimes[i]) {
                return
                    unlockPercent >= MAX_PERCENT_MULTIPLIER
                        ? MAX_PERCENT_MULTIPLIER
                        : unlockPercent;
            } else {
                unlockPercent += percents[i];
            }
        }
        return
            unlockPercent >= MAX_PERCENT_MULTIPLIER
                ? MAX_PERCENT_MULTIPLIER
                : unlockPercent;
    }

    function getUnlockPercent() public view returns (uint256) {
        return _getUnlockPercentAt(block.timestamp);
    }

    function getAmountClaimableAt(address _user, uint256 _timestamp)
        public
        view
        returns (uint256)
    {
        if (userRequestRefund.contains(_user)) {
            return 0;
        }
        uint256 unlockPercent = _getUnlockPercentAt(_timestamp);
        if (unlockPercent <= 0) {
            return 0;
        }
        uint256 amountDeposit = mapUserDeposited[_user];
        if (amountDeposit <= 0) {
            return 0;
        }
        uint256 amountClaimed = mapUserClaimed[_user];
        uint256 amountUnlock = (amountDeposit * rateOut * unlockPercent) /
            (rateIn * MAX_PERCENT_MULTIPLIER);
        return amountUnlock - amountClaimed;
    }

    function claim() external nonReentrant {
        require(
            !userRequestRefund.contains(msg.sender),
            "The user requested a refund"
        );
        uint256 amountDeposit = mapUserDeposited[msg.sender];
        require(amountDeposit > 0, "User not join pool");
        uint256 amountClaimable = getAmountClaimableAt(
            msg.sender,
            block.timestamp
        );
        require(amountClaimable > 0, "Amount claimable zero");
        tokenClaim.safeTransferFrom(
            address(rewardFrom),
            address(msg.sender),
            amountClaimable
        );
        mapUserClaimed[msg.sender] += amountClaimable;
        totalClaimed += amountClaimable;
    }

    function isRefundByPrice() public view returns (bool) {
        uint256 price = getPriceTokenClaim();
        return price <= priceRefund;
    }

    function getPriceTokenClaim() public view returns (uint256) {
        uint256[] memory amounts = dexRouter.getAmountsOut(10**18, path);
        uint256 price = amounts[amounts.length - 1];
        return price;
    }

    function requestRefund() external nonReentrant {
        // cal price 1Ameta = USD
        require(endTimeRefund >= block.timestamp, "Request refund expired");
        uint256 price = getPriceTokenClaim();
        require(
            price <= priceRefund,
            "The price is greater than the allowable price for refund"
        );
        require(
            !userRequestRefund.contains(msg.sender),
            "The user requested a refund"
        );

        uint256 amountDeposit = mapUserDeposited[msg.sender];
        require(amountDeposit > 0, "User not join pool");
        require(mapUserClaimed[msg.sender] == 0, "User is claimed");
        userRequestRefund.add(msg.sender);
    }

    function isRequestRefund(address _user) public view returns (bool) {
        return userRequestRefund.contains(_user);
    }

    function isExpiredRequestRefund() public view returns (bool) {
        return block.timestamp > endTimeRefund;
    }

    function getGrantedRefund(address _user) public view returns (bool) {
        if (block.timestamp > endTimeRefund) {
            return false;
        }
        uint256 amountDeposit = mapUserDeposited[_user];
        if (amountDeposit <= 0) {
            return false;
        }

        uint256 amountClaimed = mapUserClaimed[_user];
        if (amountClaimed > 0) {
            return false;
        }

        if (userRequestRefund.contains(_user)) {
            return false;
        }
        return true;
    }

    function viewUserInfo(address _user)
        public
        view
        returns (
            uint256 totalAmount,
            uint256 amountDeposit,
            uint256 amountClaimed,
            uint256 amountClaimable,
            bool grantedClaim,
            bool grantedRefund
        )
    {
        amountDeposit = mapUserDeposited[_user];
        grantedRefund = getGrantedRefund(_user);
        totalAmount = (amountDeposit * rateOut) / rateIn;
        amountClaimed = mapUserClaimed[_user];
        amountClaimable = getAmountClaimableAt(_user, block.timestamp);
        grantedClaim =
            amountDeposit > 0 &&
            !userRequestRefund.contains(_user) &&
            amountClaimable > 0;

        return (
            totalAmount,
            amountDeposit,
            amountClaimed,
            amountClaimable,
            grantedClaim,
            grantedRefund
        );
    }
}
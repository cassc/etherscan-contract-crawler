// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

contract FixedMode is AccessControl {
    event Refund(address buyer, uint256 _donationId, uint256 refundNumber, address refundToken);

    event Donate(address buyer, uint256 _donationId, uint256 donateNumber, address donateToken);

    address constant TO_ADDRESS = 0xDB3e36f751471C0507F3EC3E7d28dabD10A3e311;
    address public WETH;

    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct DonationToken {
        address donationToken;
        address paymentToken;
        uint256 totalSupply;
        uint256 minimumPurchase;
        uint256 startTime;
        uint256 deadline;
        string remark;
        uint256 extractTimes;
        uint256 extractIntervalSeconds;
        uint256[] extractRatios;
        uint256 donatedAmount;
        uint256 targetAmount;
    }

    struct ExtractInfo {
        uint256 donationsNumber;
        uint256 extractNumber;
        uint256 extractTimes;
        uint256 extractTime;
        bool refundFlag;
    }

    mapping(uint256 => DonationToken) public donationTokens;
    uint256 public tokenCount;
    mapping(uint256 => mapping(address => ExtractInfo)) public extractInfos;

    constructor() {
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    receive() external payable {}

    function setWETH(address _WETH) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        WETH = _WETH;
    }

    function addToken(
        address _donationToken,
        address _paymentToken,
        uint256 _totalSupply,
        uint256 _minimumPurchase,
        uint256 _startTime,
        uint256 _deadline,
        string memory _remark,
        uint256 _extractTimes,
        uint256 _extractIntervalSeconds,
        uint256[] memory extractRatios,
        uint256 _targetAmount
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(_totalSupply > 0, "TotalSupply must be greater than zero");
        require(block.timestamp < _deadline, "deadline error");
        require(_paymentToken != address(0), "paymentToken address cannot be zero");
        require(_targetAmount > 0, "targetAmount must be greater than zero");

        uint256 length = extractRatios.length;
        require(length > 0, "Please enter a ratio");
        require(_extractTimes == length, "Please complete the extraction ratio");

        tokenCount++;

        donationTokens[tokenCount] = DonationToken({
            donationToken: _donationToken,
            paymentToken: _paymentToken,
            totalSupply: _totalSupply,
            minimumPurchase: _minimumPurchase,
            startTime: _startTime,
            deadline: _deadline,
            remark: _remark,
            extractTimes: _extractTimes,
            extractIntervalSeconds: _extractIntervalSeconds,
            extractRatios: extractRatios,
            donatedAmount: 0,
            targetAmount: _targetAmount
        });
    }

    function exist(uint256 _donationId) public view {
        require(_donationId > 0, "ID must be greater than 0");
        require(_donationId <= tokenCount, "ID does not exist");
    }

    function getToken(uint256 _donationId) external view returns (DonationToken memory) {
        exist(_donationId);
        return donationTokens[_donationId];
    }

    function getTokenRange(uint256 startId, uint256 endId) external view returns (DonationToken[] memory) {
        require(startId <= endId, "Invalid range");
        require(endId <= tokenCount, "End ID exceeds token count");

        uint256 count = endId - startId + 1;
        DonationToken[] memory result = new DonationToken[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = donationTokens[startId + i];
        }
        return result;
    }

    function setExtract(uint256 _donationId, uint256 _extractTimes, uint256 _extractIntervalSeconds, uint256[] memory extractRatios_) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        exist(_donationId);

        uint256 length = extractRatios_.length;
        require(length > 0, "Please enter a ratio");
        require(_extractTimes == length, "Please complete the extraction ratio");
        for (uint256 i = 0; i < extractRatios_.length; i++) {
            uint256 currentRatio = extractRatios_[i];
            require(currentRatio > 0 && currentRatio <= 100, "Scale must be greater than 0 and less than or equal to 100");
        }

        donationTokens[_donationId].extractTimes = _extractTimes;
        donationTokens[_donationId].extractIntervalSeconds = _extractIntervalSeconds;
        donationTokens[_donationId].extractRatios = extractRatios_;
    }

    function setTotalSupply(uint256 _donationId, uint256 _totalSupply) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        exist(_donationId);
        require(_totalSupply > 0, "TotalSupply must be greater than zero");
        donationTokens[_donationId].totalSupply = _totalSupply;
    }

    function setStartTime(uint256 _donationId, uint256 _startTime) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        exist(_donationId);
        donationTokens[_donationId].startTime = _startTime;
    }

    function setRemark(uint256 _donationId, string memory _remark) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        exist(_donationId);
        donationTokens[_donationId].remark = _remark;
    }

    function setDeadline(uint256 _donationId, uint256 _deadline) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        exist(_donationId);
        donationTokens[_donationId].deadline = _deadline;
    }

    function setDonationToken(uint256 _donationId, address _donationToken) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        exist(_donationId);
        require(_donationToken != address(0), "donationToken address cannot be zero");
        donationTokens[_donationId].donationToken = _donationToken;
    }

    function setPaymentToken(uint256 _donationId, address _paymentToken) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        exist(_donationId);
        require(_paymentToken != address(0), "paymentToken address cannot be zero");
        donationTokens[_donationId].paymentToken = _paymentToken;
    }

    function setMinimumPurchase(uint256 _donationId, uint256 _minimumPurchase) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        exist(_donationId);
        donationTokens[_donationId].minimumPurchase = _minimumPurchase;
    }

    function setTargetAmount(uint256 _donationId, uint256 _targetAmount) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        exist(_donationId);
        donationTokens[_donationId].targetAmount = _targetAmount;
    }

    function donateCondition(DonationToken memory donationToken, uint256 _amount) private view {
        require(donationToken.paymentToken != address(0), "paymentToken does not exist");
        require(block.timestamp >= donationToken.startTime, "Donation has not started");
        require(block.timestamp < donationToken.deadline, "Donation period has ended");
        require(_amount > 0, "Amount must be greater than zero");
        require(_amount >= donationToken.minimumPurchase, "Must not be less than the minimum purchase amount");
    }

    function donateAdd(uint256 _donationId, uint256 _amount) private {
        DonationToken memory donationToken = donationTokens[_donationId];
        extractInfos[_donationId][msg.sender].donationsNumber += _amount;
        donationTokens[_donationId].donatedAmount += _amount;
        emit Donate(msg.sender, _donationId, _amount, donationToken.donationToken);
    }

    function donateETH(uint256 _donationId) external payable {
        DonationToken memory donationToken = donationTokens[_donationId];
        donateCondition(donationToken, msg.value);

        require(donationToken.paymentToken == WETH, "Only ETH");
        donateAdd(_donationId, msg.value);
    }

    function donate(uint256 _donationId, uint256 _amount) public {
        DonationToken memory donationToken = donationTokens[_donationId];
        donateCondition(donationToken, _amount);
        require(donationToken.paymentToken != WETH, "Cannot be ETH");

        IERC20(donationToken.paymentToken).safeTransferFrom(msg.sender, address(this), _amount);
        donateAdd(_donationId, _amount);
    }

    function withdraw(uint256 _donationId) external {
        DonationToken memory donationTokenObj = donationTokens[_donationId];
        require(donationTokenObj.donationToken != address(0), "donationToken does not exist");
        require(block.timestamp >= donationTokenObj.deadline, "Donation period has not ended");
        ExtractInfo memory extractInfo = extractInfos[_donationId][msg.sender];
        require(extractInfo.extractTimes < donationTokenObj.extractTimes, "Fetch times exceeded");
        uint256 availableTime = extractInfo.extractTime + donationTokenObj.extractIntervalSeconds;
        require(block.timestamp >= availableTime, "Not yet pickup time");
        uint256 rate = (extractInfo.donationsNumber * 100) / donationTokenObj.donatedAmount;
        uint256 allNumber = (donationTokenObj.totalSupply * rate) / 100;
        require(allNumber > 0, "Insufficient balance");
        uint256 extractNumber = allNumber - extractInfo.extractNumber;
        uint256 amountPer = (allNumber * donationTokenObj.extractRatios[extractInfo.extractTimes]) / 100;
        require(extractNumber > 0, "Insufficient quantity available");

        if (amountPer >= extractNumber) {
            _payment(extractNumber, donationTokenObj.donationToken, _donationId);
        } else {
            _payment(amountPer, donationTokenObj.donationToken, _donationId);
        }

        uint256 refundAmount = donationTokenObj.donatedAmount - donationTokenObj.targetAmount;
        if (refundAmount > 0 && !extractInfos[_donationId][msg.sender].refundFlag) {
            uint256 addressRefundAmount = (refundAmount * rate) / 100;
            if (addressRefundAmount > 0) {
                extractInfos[_donationId][msg.sender].refundFlag = true;
                if (donationTokenObj.paymentToken == WETH) {
                    payable(msg.sender).transfer(addressRefundAmount);
                } else {
                    IERC20(donationTokenObj.paymentToken).safeTransfer(msg.sender, addressRefundAmount);
                }
                emit Refund(msg.sender, _donationId, addressRefundAmount, donationTokenObj.paymentToken);
            }
        }
    }

    function _payment(uint256 extractNumber, address _donationToken0, uint256 _donationId) private {
        IERC20(_donationToken0).safeTransfer(msg.sender, extractNumber);

        extractInfos[_donationId][msg.sender].extractNumber += extractNumber;
        extractInfos[_donationId][msg.sender].extractTimes += 1;
        extractInfos[_donationId][msg.sender].extractTime = block.timestamp;
    }

    function transferTokens(address _tokenAddress, uint256 _amount) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(_tokenAddress != address(0), "Token address cannot be zero");
        require(_amount > 0, "Amount must be greater than zero");
        IERC20(_tokenAddress).safeTransfer(TO_ADDRESS, _amount);
    }

    function transferETH(uint256 _amount) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        payable(TO_ADDRESS).transfer(_amount);
    }
}
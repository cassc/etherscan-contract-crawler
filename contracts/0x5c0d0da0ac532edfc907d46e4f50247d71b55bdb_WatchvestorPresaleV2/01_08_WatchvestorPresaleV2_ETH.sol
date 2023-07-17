//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

interface Aggregator {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract WatchvestorPresaleV2 is
    Initializable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    uint256 public totalTokensSold;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimStart;
    address public saleToken;
    uint256 public baseDecimals;
    uint256 public maxTokensToBuy;
    uint256 public currentStep;
    uint256 public checkPoint;
    uint256 public usdRaised;
    uint256[] public prevCheckpoints;
    uint256[] public remainingTokensTracker;
    uint256 public timeConstant;
    address public paymentWallet;
    bool public dynamicTimeFlag;
    bool public whitelistClaimOnly;
    uint256[][3] public rounds;

    IERC20Upgradeable public USDTInterface;
    Aggregator public aggregatorInterface;
    mapping(address => uint256) public userDeposits;
    mapping(address => bool) public hasClaimed;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isWhitelisted;

    struct PromoCodeDetails {
        uint256 expiryDate;
        uint256 usageLimit;
        uint256 usageCount;
        uint256 discountPercentage;
        bool isValid;
    }

    mapping(string => PromoCodeDetails) private promoCodes;
    string[] private promoCodeKeys;

    event SaleTimeSet(uint256 _start, uint256 _end, uint256 timestamp);
    event SaleTimeUpdated(
        bytes32 indexed key,
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );
    event TokensBought(
        address indexed user,
        uint256 indexed tokensBought,
        address indexed purchaseToken,
        uint256 amountPaid,
        uint256 usdEq,
        uint256 timestamp
    );
    event TokensAdded(
        address indexed token,
        uint256 noOfTokens,
        uint256 timestamp
    );
    event TokensClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event ClaimStartUpdated(
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );
    event MaxTokensUpdated(
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );
    event PromoCodeCreated(
        string code,
        uint256 expiryDate,
        uint256 usageLimit,
        uint256 discountPercentage
    );
    event PromoCodeDisabled(string code);

    function initialize(
        address _oracle,
        address _usdt,
        uint256 _startTime,
        uint256 _endTime,
        uint256[][3] memory _rounds,
        uint256 _maxTokensToBuy,
        address _paymentWallet
    ) external initializer {
        require(_usdt != address(0), "0x123 USDT address");
        require(_oracle != address(0), "0x123 aggregator address");
        require(_endTime > _startTime, "Invalid time");
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        baseDecimals = 10 ** 18;
        aggregatorInterface = Aggregator(_oracle);
        USDTInterface = IERC20Upgradeable(_usdt);
        startTime = _startTime;
        endTime = _endTime;
        rounds = _rounds;
        maxTokensToBuy = _maxTokensToBuy;
        paymentWallet = _paymentWallet;
        timeConstant = 172800;
        emit SaleTimeSet(startTime, endTime, block.timestamp);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function calculatePrice(uint256 _amount) public view returns (uint256) {
        uint256 USDTAmount;
        uint256 total = checkPoint == 0 ? totalTokensSold : checkPoint;
        require(_amount <= maxTokensToBuy, "Amount exceeds max tokens to buy");
        if (_amount + total > rounds[0][currentStep]) {
            require(currentStep < (rounds[0].length - 1), "Wrong params");
            uint256 tokenAmountForCurrentPrice = rounds[0][currentStep] - total;
            USDTAmount =
                tokenAmountForCurrentPrice *
                rounds[1][currentStep] +
                (_amount - tokenAmountForCurrentPrice) *
                rounds[1][currentStep + 1];
        } else {
            USDTAmount = _amount * rounds[1][currentStep];
        }
        return USDTAmount;
    }

    function changeSaleTimes(
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        require(_startTime > 0 || _endTime > 0, "Invalid parameters");
        if (_startTime > 0) {
            uint256 prevValue = startTime;
            startTime = _startTime;
            emit SaleTimeUpdated(
                bytes32("START"),
                prevValue,
                _startTime,
                block.timestamp
            );
        }
        if (_endTime > 0) {
            uint256 prevValue = endTime;
            endTime = _endTime;
            emit SaleTimeUpdated(
                bytes32("END"),
                prevValue,
                _endTime,
                block.timestamp
            );
        }
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterface.latestRoundData();
        price = (price * (10 ** 10));
        return uint256(price);
    }

    modifier checkSaleState(uint256 amount) {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Invalid time for buying"
        );
        require(amount > 0, "Invalid sale amount");
        _;
    }

    function buyWithUSDT(
        uint256 amount,
        string memory promoCode
    ) external checkSaleState(amount) whenNotPaused returns (bool) {
        uint256 usdPrice = calculatePrice(amount);

        // Check if a promo code is provided and apply discount
        if (bytes(promoCode).length > 0) {
            require(promoCodes[promoCode].isValid, "Invalid promo code");
            require(
                promoCodes[promoCode].expiryDate >= block.timestamp,
                "Expired promo code"
            );
            require(
                promoCodes[promoCode].usageCount <
                    promoCodes[promoCode].usageLimit,
                "Promo code usage limit reached"
            );

            uint256 discountedAmount = amount;
            // Apply discount from the promo code
            discountedAmount +=
                (amount * promoCodes[promoCode].discountPercentage) /
                100;

            amount = discountedAmount;
        }

        totalTokensSold += amount;
        if (checkPoint != 0) checkPoint += amount;
        uint256 total = totalTokensSold > checkPoint
            ? totalTokensSold
            : checkPoint;
        if (total > rounds[0][currentStep]) {
            uint256 unsoldTokens = total > rounds[0][currentStep]
                ? 0
                : rounds[0][currentStep] - total;
            remainingTokensTracker.push(unsoldTokens);
            currentStep += 1;
        }

        userDeposits[_msgSender()] += (amount * baseDecimals);
        usdRaised += usdPrice;
        uint256 ourAllowance = USDTInterface.allowance(
            _msgSender(),
            address(this)
        );
        uint256 price = usdPrice / (10 ** 12);
        require(price <= ourAllowance, "Make sure to add enough allowance");
        (bool success, ) = address(USDTInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                paymentWallet,
                price
            )
        );
        require(success, "Token payment failed");
        emit TokensBought(
            _msgSender(),
            amount,
            address(USDTInterface),
            price,
            usdPrice,
            block.timestamp
        );
        return true;
    }

    function buyWithEth(
        uint256 amount,
        string memory promoCode
    )
        external
        payable
        checkSaleState(amount)
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        uint256 usdPrice = calculatePrice(amount);

        // Check if a promo code is provided and apply discount
        if (bytes(promoCode).length > 0) {
            require(promoCodes[promoCode].isValid, "Invalid promo code");
            require(
                promoCodes[promoCode].expiryDate >= block.timestamp,
                "Expired promo code"
            );
            require(
                promoCodes[promoCode].usageCount <
                    promoCodes[promoCode].usageLimit,
                "Promo code usage limit reached"
            );

            uint256 discountedAmount = amount;
            // Apply discount from the promo code
            discountedAmount +=
                (amount * promoCodes[promoCode].discountPercentage) /
                100;

            amount = discountedAmount;
        }

        uint256 ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
        require(msg.value >= ethAmount, "Less payment");
        uint256 excess = msg.value - ethAmount;
        totalTokensSold += amount;
        if (checkPoint != 0) checkPoint += amount;
        uint256 total = totalTokensSold > checkPoint
            ? totalTokensSold
            : checkPoint;
        if (total > rounds[0][currentStep]) {
            uint256 unsoldTokens = total > rounds[0][currentStep]
                ? 0
                : rounds[0][currentStep] - total;
            remainingTokensTracker.push(unsoldTokens);
            currentStep += 1;
        }
        userDeposits[_msgSender()] += (amount * baseDecimals);
        usdRaised += usdPrice;
        sendValue(payable(paymentWallet), ethAmount);
        if (excess > 0) sendValue(payable(_msgSender()), excess);
        emit TokensBought(
            _msgSender(),
            amount,
            address(0),
            ethAmount,
            usdPrice,
            block.timestamp
        );
        return true;
    }

    function ethBuyHelper(
        uint256 amount
    ) external view returns (uint256 ethAmount) {
        uint256 usdPrice = calculatePrice(amount);
        ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
    }

    function usdtBuyHelper(
        uint256 amount
    ) external view returns (uint256 usdPrice) {
        usdPrice = calculatePrice(amount);
        usdPrice = usdPrice / (10 ** 12);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    function startClaim(
        uint256 _claimStart,
        uint256 noOfTokens,
        address _saleToken
    ) external onlyOwner returns (bool) {
        require(
            _claimStart > endTime && _claimStart > block.timestamp,
            "Invalid claim start time"
        );
        require(
            noOfTokens >= (totalTokensSold * baseDecimals),
            "Tokens less than sold"
        );
        require(_saleToken != address(0), "0x000 token address");
        require(claimStart == 0, "Claim already set");
        claimStart = _claimStart;
        saleToken = _saleToken;
        bool success = IERC20Upgradeable(_saleToken).transferFrom(
            _msgSender(),
            address(this),
            noOfTokens
        );
        require(success, "Token transfer failed");
        emit TokensAdded(saleToken, noOfTokens, block.timestamp);
        return true;
    }

    function changeClaimStart(
        uint256 _claimStart
    ) external onlyOwner returns (bool) {
        require(claimStart > 0, "Initial claim data not set");
        require(_claimStart > endTime, "Sale in progress");
        require(_claimStart > block.timestamp, "Claim start in past");
        uint256 prevValue = claimStart;
        claimStart = _claimStart;
        emit ClaimStartUpdated(prevValue, _claimStart, block.timestamp);
        return true;
    }

    function claim() external whenNotPaused returns (bool) {
        require(saleToken != address(0), "Sale token not added");
        require(!isBlacklisted[_msgSender()], "This Address is Blacklisted");
        if (whitelistClaimOnly) {
            require(
                isWhitelisted[_msgSender()],
                "User not whitelisted for claim"
            );
        }
        require(block.timestamp >= claimStart, "Claim has not started yet");
        require(!hasClaimed[_msgSender()], "Already claimed");
        hasClaimed[_msgSender()] = true;
        uint256 amount = userDeposits[_msgSender()];
        require(amount > 0, "Nothing to claim");
        delete userDeposits[_msgSender()];
        bool success = IERC20Upgradeable(saleToken).transfer(
            _msgSender(),
            amount
        );
        require(success, "Token transfer failed");
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
        return true;
    }

    function changeMaxTokensToBuy(uint256 _maxTokensToBuy) external onlyOwner {
        require(_maxTokensToBuy > 0, "0 max tokens to buy value");
        uint256 prevValue = maxTokensToBuy;
        maxTokensToBuy = _maxTokensToBuy;
        emit MaxTokensUpdated(prevValue, _maxTokensToBuy, block.timestamp);
    }

    function changeRoundsData(uint256[][3] memory _rounds) external onlyOwner {
        rounds = _rounds;
    }

    function changeRoundsSaleTokens(
        uint256[] memory _rounds
    ) external onlyOwner {
        rounds[0] = _rounds;
    }

    function changeRoundsSalePrices(
        uint256[] memory _rounds
    ) external onlyOwner {
        rounds[1] = _rounds;
    }

    function blacklistUsers(
        address[] calldata _usersToBlacklist
    ) external onlyOwner {
        for (uint256 i = 0; i < _usersToBlacklist.length; i++) {
            isBlacklisted[_usersToBlacklist[i]] = true;
        }
    }

    function removeFromBlacklist(
        address[] calldata _userToRemoveFromBlacklist
    ) external onlyOwner {
        for (uint256 i = 0; i < _userToRemoveFromBlacklist.length; i++) {
            isBlacklisted[_userToRemoveFromBlacklist[i]] = false;
        }
    }

    function whitelistUsers(
        address[] calldata _usersToWhitelist
    ) external onlyOwner {
        for (uint256 i = 0; i < _usersToWhitelist.length; i++) {
            isWhitelisted[_usersToWhitelist[i]] = true;
        }
    }

    function removeFromWhitelist(
        address[] calldata _userToRemoveFromWhitelist
    ) external onlyOwner {
        for (uint256 i = 0; i < _userToRemoveFromWhitelist.length; i++) {
            isWhitelisted[_userToRemoveFromWhitelist[i]] = false;
        }
    }

    function setClaimWhitelistStatus(bool _status) external onlyOwner {
        whitelistClaimOnly = _status;
    }

    function changePaymentWallet(address _newPaymentWallet) external onlyOwner {
        require(_newPaymentWallet != address(0), "address cannot be zero");
        paymentWallet = _newPaymentWallet;
    }

    function roundDetails(
        uint256 _no
    ) external view returns (uint256[] memory) {
        return rounds[_no];
    }

    function updateFromBSC(
        address[] calldata _users,
        uint256[] calldata _userDeposits
    ) external onlyOwner {
        require(_users.length == _userDeposits.length, "Length mismatch");
        for (uint256 i = 0; i < _users.length; i++) {
            userDeposits[_users[i]] += _userDeposits[i];
        }
    }

    function incrementCurrentStep() external onlyOwner {
        prevCheckpoints.push(checkPoint);
        if (checkPoint < rounds[0][currentStep]) {
            remainingTokensTracker.push(rounds[0][currentStep] - checkPoint);
            checkPoint = rounds[0][currentStep];
        }
        currentStep++;
    }

    function setCurrentStep(
        uint256 _step,
        uint256 _checkpoint
    ) external onlyOwner {
        currentStep = _step;
        checkPoint = _checkpoint;
    }

    function trackRemainingTokens() external view returns (uint256[] memory) {
        return remainingTokensTracker;
    }

    function updatePromoCode(
        string calldata code,
        uint256 expiryDate,
        uint256 usageLimit,
        uint256 discountPercentage
    ) external onlyOwner {
        promoCodes[code] = PromoCodeDetails({
            expiryDate: expiryDate,
            usageLimit: usageLimit,
            usageCount: 0,
            discountPercentage: discountPercentage,
            isValid: true
        });
    }

    function createPromoCode(
        string memory code,
        uint256 expiryDate,
        uint256 usageLimit,
        uint256 discountPercentage
    ) external onlyOwner {
        require(!promoCodes[code].isValid, "Promo code already exists");

        PromoCodeDetails memory promoCode = PromoCodeDetails({
            expiryDate: expiryDate,
            usageLimit: usageLimit,
            usageCount: 0,
            discountPercentage: discountPercentage,
            isValid: true
        });

        promoCodes[code] = promoCode;
        promoCodeKeys.push(code);
        emit PromoCodeCreated(code, expiryDate, usageLimit, discountPercentage);
    }

    function disablePromoCode(string memory code) external onlyOwner {
        require(promoCodes[code].isValid, "Promo code does not exist");
        promoCodes[code].isValid = false;

        // Remove the promo code key from promoCodeKeys array
        for (uint256 i = 0; i < promoCodeKeys.length; i++) {
            if (keccak256(bytes(promoCodeKeys[i])) == keccak256(bytes(code))) {
                // Shift elements to the left to remove the key
                for (uint256 j = i; j < promoCodeKeys.length - 1; j++) {
                    promoCodeKeys[j] = promoCodeKeys[j + 1];
                }
                promoCodeKeys.pop();
                break;
            }
        }

        emit PromoCodeDisabled(code);
    }

    function validatePromoCode(
        string memory code
    ) external view returns (bool) {
        return (promoCodes[code].isValid &&
            promoCodes[code].expiryDate >= block.timestamp &&
            promoCodes[code].usageCount < promoCodes[code].usageLimit);
    }

    function getPromoCode(
        string memory code
    ) public view returns (uint256, uint256, uint256, uint256, bool) {
        PromoCodeDetails storage details = promoCodes[code];
        return (
            details.expiryDate,
            details.usageLimit,
            details.usageCount,
            details.discountPercentage,
            details.isValid
        );
    }

    function getPromoCodes() public view returns (string[] memory) {
        return promoCodeKeys;
    }
}
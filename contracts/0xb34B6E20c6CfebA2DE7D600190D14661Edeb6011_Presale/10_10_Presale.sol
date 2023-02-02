//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
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

contract Presale is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    uint256 public totalTokensSold;
    uint256 public totalTokensToSale;
    uint256 public currentStep;
    uint8 constant maxStepIndex = 4;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimStart;
    address public saleToken;
    uint256 public baseDecimals;

    IERC20Upgradeable public USDTInterface;
    Aggregator public aggregatorInterface;
    // https://docs.chain.link/docs/ethereum-addresses/ => (ETH / USD)

    uint256[5] public token_amount;
    uint256[5] public token_price;

    mapping(address => uint256) public userDeposits;
    mapping(address => bool) public hasClaimed;

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
        uint256 amountPaid,
        uint256 timestamp
    );

    event TokensAdded(
        address indexed token,
        uint256 tokenAmount,
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

    function initialize(
        address _oracle,
        address _usdt,
        address _saleToken,
        uint256 _startTime,
        uint256 _endTime
    ) external initializer {
        require(_oracle != address(0), "Zero aggregator address");
        require(_saleToken != address(0), "Zero Sale Token address");
        require(_usdt != address(0), "Zero USDT address");
        require(
            _startTime > block.timestamp && _endTime > _startTime,
            "Invalid time"
        );
        __Context_init_unchained();
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        totalTokensSold = 0;
        totalTokensToSale = 250_000_000;
        currentStep = 0;
        baseDecimals = (10**18);
        token_amount = [
            30_000_000,
            55_000_000,
            55_000_000,
            55_000_000,
            55_000_000
        ];
        token_price = [
            6_000_000_000_000_000,
            7_000_000_000_000_000,
            8_000_000_000_000_000,
            9_000_000_000_000_000,
            11_000_000_000_000_000
        ];
        aggregatorInterface = Aggregator(_oracle);
        USDTInterface = IERC20Upgradeable(_usdt);
        saleToken = _saleToken;
        startTime = _startTime;
        endTime = _endTime;
        emit SaleTimeSet(startTime, endTime, block.timestamp);
    }

    /**
     * @dev To pause the presale
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev To unpause the presale
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev To calculate the price in USD for given amount of tokens.
     * @param _amount No of tokens
     */
    function calculatePrice(uint256 _amount) public view returns (uint256) {
        uint256 USDTAmount;
        if (_amount + totalTokensSold > token_amount[currentStep]) {
            require(currentStep < maxStepIndex, "Insufficient token amount.");
            uint256 tokenAmountForCurrentPrice = token_amount[currentStep] -
                totalTokensSold;
            USDTAmount =
                tokenAmountForCurrentPrice *
                token_price[currentStep] +
                (_amount - tokenAmountForCurrentPrice) *
                token_price[currentStep + 1];
        } else USDTAmount = _amount * token_price[currentStep];
        return USDTAmount;
    }

    /**
     * @dev To update the sale times
     * @param _startTime New start time
     * @param _endTime New end time
     */
    function changeSaleTimes(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(_startTime > 0 || _endTime > 0, "Invalid parameters");
        if (_startTime > 0) {
            require(block.timestamp < startTime, "Sale already started");
            require(block.timestamp < _startTime, "Sale time in past");
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
            require(block.timestamp < endTime, "Sale already ended");
            require(_endTime > startTime, "Invalid endTime");
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

    /**
     * @dev To get latest ethereum price in 10**18 format
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterface.latestRoundData();
        price = (price * (10**10));
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

    /**
     * @dev Calculate current step amount from total tokens sold amount
     */
    function getStepByTotalSoldAmount() internal view returns (uint256) {
        uint8 stepIndex = maxStepIndex;
        while (stepIndex > 0) {
            if (token_amount[stepIndex - 1] < totalTokensSold) break;
            stepIndex -= 1;
        }
        return stepIndex;
    }

    /**
     * @dev Helper function to get USDT price for given amount
     * @param _amount No of tokens to buy
     */
    function usdtBuyHelper(uint256 _amount)
        public
        view
        returns (uint256 usdtPrice)
    {
        usdtPrice = calculatePrice(_amount) / 1e12;
    }

    /**
     * @dev To buy into a presale using USDT
     * @param _amount No of tokens to buy
     */
    function buyWithUSDT(uint256 _amount)
        external
        checkSaleState(_amount)
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        uint256 usdtPrice = usdtBuyHelper(_amount);
        require(
            usdtPrice <= USDTInterface.allowance(_msgSender(), address(this)),
            "Not enough allowance"
        );
        USDTInterface.safeTransferFrom(_msgSender(), owner(), usdtPrice);
        totalTokensSold += _amount;
        userDeposits[_msgSender()] += _amount * 1e18;

        uint256 stepAfterPurchase = getStepByTotalSoldAmount();
        if (stepAfterPurchase > currentStep) currentStep = stepAfterPurchase;
        emit TokensBought(_msgSender(), _amount, usdtPrice, block.timestamp);
        return true;
    }

    /**
     * @dev To buy into a presale using ETH
     * @param _amount No of tokens to buy
     */
    function buyWithEth(uint256 _amount)
        external
        payable
        checkSaleState(_amount)
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        uint256 ethAmount = ethBuyHelper(_amount);
        require(msg.value >= ethAmount, "Less payment");
        sendValue(payable(owner()), ethAmount);
        uint256 excess = msg.value - ethAmount;
        if (excess > 0) sendValue(payable(_msgSender()), excess);
        totalTokensSold += _amount;
        userDeposits[_msgSender()] += _amount * 1e18;
        uint256 stepAfterPurchase = getStepByTotalSoldAmount();
        if (stepAfterPurchase > currentStep) currentStep = stepAfterPurchase;
        emit TokensBought(_msgSender(), _amount, ethAmount, block.timestamp);
        return true;
    }

    /**
     * @dev Helper function to get ETH price for given _amount
     * @param _amount No of tokens to buy
     */
    function ethBuyHelper(uint256 _amount)
        public
        view
        returns (uint256 ethAmount)
    {
        ethAmount = (calculatePrice(_amount) * 1e18) / getLatestPrice();
    }

    function sendValue(address payable _recipient, uint256 _weiAmount)
        internal
    {
        require(address(this).balance >= _weiAmount, "Low balance");
        (bool success, ) = _recipient.call{value: _weiAmount}("");
        require(success, "ETH Payment failed");
    }

    /**
     * @dev To set the claim start time and sale token address by the owner
     * @param _claimStart claim start time
     * @param _tokenAmount no of tokens to add to the contract
     */
    function startClaim(uint256 _claimStart, uint256 _tokenAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            _claimStart > endTime && _claimStart > block.timestamp,
            "Invalid claim start time"
        );
        require(
            _tokenAmount >= (totalTokensSold * baseDecimals),
            "Tokens less than sold"
        );
        require(claimStart == 0, "Claim already set");
        claimStart = _claimStart;
        IERC20Upgradeable(saleToken).transferFrom(
            _msgSender(),
            address(this),
            _tokenAmount
        );
        emit TokensAdded(saleToken, _tokenAmount, block.timestamp);
        return true;
    }

    /**
     * @dev To change the claim start time by the owner
     * @param _claimStart new claim start time
     */
    function changeClaimStart(uint256 _claimStart)
        external
        onlyOwner
        returns (bool)
    {
        require(claimStart > 0, "Initial claim data not set");
        require(_claimStart > endTime, "Sale in progress");
        require(_claimStart > block.timestamp, "Claim start in past");
        uint256 prevValue = claimStart;
        claimStart = _claimStart;
        emit ClaimStartUpdated(prevValue, _claimStart, block.timestamp);
        return true;
    }

    /**
     * @dev To claim tokens after claiming starts
     */
    function claim() external whenNotPaused nonReentrant {
        require(
            block.timestamp >= claimStart && claimStart > 0,
            "Claim has not started yet"
        );
        require(!hasClaimed[_msgSender()], "Already claimed");
        uint256 amount = userDeposits[_msgSender()];
        require(amount > 0, "Nothing to claim");
        hasClaimed[_msgSender()] = true;
        IERC20Upgradeable(saleToken).safeTransfer(_msgSender(), amount);
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
    }

    /**
     * @dev To change endTime after sale starts
     * @param _newEndtime new sale end time
     */
    function setEndTime(uint256 _newEndtime) external onlyOwner {
        require(startTime > 0, "Sale not started yet");
        require(_newEndtime > block.timestamp, "Endtime must be in the future");
        endTime = _newEndtime;
    }
}
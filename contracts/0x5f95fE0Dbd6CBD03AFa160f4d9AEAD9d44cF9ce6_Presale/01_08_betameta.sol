//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
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
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    uint256 public totalTokensSold = 0;
    uint256 public currentStep = 0;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimStart;
    address public constant saleToken = 0xed328E9C1179a30ddC1E7595E036AEd8760C22aF;
    uint256 public baseDecimals;

    IERC20Upgradeable public USDTInterface;
    Aggregator public aggregatorInterface;
    // https://docs.chain.link/docs/ethereum-addresses/ => (ETH / USD)

    uint256 public token_price = 8_000_000_000_000_000;

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
        address indexed purchaseToken,
        uint256 amountPaid,
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

    /// @custom:oz-upgrades-unsafe-allow constructor

    /**
     * @dev Initializes the contract and sets key parameters
     * @param _oracle Oracle contract to fetch ETH/USDT price
     * @param _usdt USDT token contract address
     * @param _startTime start time of the presale
     * @param _endTime end time of the presale
     */
    function initialize(
        address _oracle,
        address _usdt,
        uint256 _startTime,
        uint256 _endTime
    ) external initializer {
        require(_oracle != address(0), "Zero aggregator address");
        require(_usdt != address(0), "Zero USDT address");
        require(
            _startTime > block.timestamp && _endTime > _startTime,
            "Invalid time"
        );
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        baseDecimals = (10**18);
               
        aggregatorInterface = Aggregator(_oracle);
        USDTInterface = IERC20Upgradeable(_usdt);
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
    function calculatePrice(uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 USDTAmount;
         USDTAmount = _amount * token_price;
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
     * @dev To buy into a presale using USDT
     * @param amount No of tokens to buy
     */
    function buyWithUSDT(uint256 amount)
        external
        checkSaleState(amount)
        whenNotPaused
        returns (bool)
    {
        require(amount + totalTokensSold <= 140_000_000, "Exceeds Beta Stage");
        uint256 usdPrice = calculatePrice(amount);
        usdPrice = usdPrice / (10**12);
        totalTokensSold += amount;

        userDeposits[_msgSender()] += (amount * baseDecimals);
        uint256 ourAllowance = USDTInterface.allowance(
            _msgSender(),
            address(this)
        );
        require(usdPrice <= ourAllowance, "Make sure to add enough allowance");
        (bool success, ) = address(USDTInterface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                owner(),
                usdPrice
            )
        );
        require(success, "Token payment failed");
        emit TokensBought(
            _msgSender(),
            amount,
            address(USDTInterface),
            usdPrice,
            block.timestamp
        );
        return true;
    }

    /**
     * @dev To buy into a presale using ETH
     * @param amount No of tokens to buy
     */
    function buyWithEth(uint256 amount)
        external
        payable
        checkSaleState(amount)
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        require(amount + totalTokensSold <= 140_000_000, "Exceeds Beta Stage");
        uint256 usdPrice = calculatePrice(amount);
        uint256 ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
        require(msg.value >= ethAmount, "Less payment");
        uint256 excess = msg.value - ethAmount;
        totalTokensSold += amount;

        userDeposits[_msgSender()] += (amount * baseDecimals);
        sendValue(payable(owner()), ethAmount);
        if (excess > 0) sendValue(payable(_msgSender()), excess);
        emit TokensBought(
            _msgSender(),
            amount,
            address(0),
            ethAmount,
            block.timestamp
        );
        return true;
    }

    /**
     * @dev Helper function to get ETH price for given amount
     * @param amount No of tokens to buy
     */
    function ethBuyHelper(uint256 amount)
        external
        view
        returns (uint256 ethAmount)
    {
        uint256 usdPrice = calculatePrice(amount);
        ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
    }

    /**
     * @dev Helper function to get USDT price for given amount
     * @param amount No of tokens to buy
     */
    function usdtBuyHelper(uint256 amount)
        external
        view
        returns (uint256 usdPrice)
    {
        usdPrice = calculatePrice(amount);
        usdPrice = usdPrice / (10**12);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    /**
     * @dev To set the claim start time and sale token address by the owner
     * @param _claimStart claim start time
     * @param noOfTokens no of tokens to add to the contract
     */
     
    function startClaim(
        uint256 _claimStart,
        uint256 noOfTokens
    ) external onlyOwner returns (bool) {
        require(
            _claimStart > endTime && _claimStart > block.timestamp,
            "Invalid claim start time"
        );
        require(
            noOfTokens >= (totalTokensSold * baseDecimals),
            "Tokens less than sold"
        );
        require(claimStart == 0, "Claim already set");
        claimStart = _claimStart;
        IERC20Upgradeable(saleToken).transferFrom(
            _msgSender(),
            address(this),
            noOfTokens
        );
        emit TokensAdded(saleToken, noOfTokens, block.timestamp);
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
    function claim() external whenNotPaused returns (bool) {
        require(saleToken != address(0), "Sale token not added");
        require(block.timestamp >= claimStart, "Claim has not started yet");
        require(!hasClaimed[_msgSender()], "Already claimed");
        hasClaimed[_msgSender()] = true;
        uint256 amount = userDeposits[_msgSender()];
        require(amount > 0, "Nothing to claim");
        delete userDeposits[_msgSender()];
        IERC20Upgradeable(saleToken).transfer(_msgSender(), amount);
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
        return true;
    }
}
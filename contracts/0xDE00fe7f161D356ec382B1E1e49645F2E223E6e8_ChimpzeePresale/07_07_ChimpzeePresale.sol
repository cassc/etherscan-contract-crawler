// SPDX-License-Identifier: MIT

/**    ______  ____  ____  _____  ____    ____  _______   ________  ________  ________  
 *   .' ___  ||_   ||   _||_   _||_   \  /   _||_   __ \ |  __   _||_   __  ||_   __  | 
 *  / .'   \_|  | |__| |    | |    |   \/   |    | |__) ||_/  / /    | |_ \_|  | |_ \_| 
 *  | |         |  __  |    | |    | |\  /| |    |  ___/    .'.' _   |  _| _   |  _| _  
 *  \ `.___.'\ _| |  | |_  _| |_  _| |_\/_| |_  _| |_     _/ /__/ | _| |__/ | _| |__/ | 
 *   `.____ .'|____||____||_____||_____||_____||_____|   |________||________||________| 
 */

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChimpzeePresale is Ownable, Pausable, ReentrancyGuard {
    uint256 public totalTokensSold = 0;
    uint256 public totalTokensSoldWithBonus = 0;
    uint256 public totalUsdRaised = 0;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimStart;
    uint256 public baseDecimals = (10**18);
    uint256 public maxTokensToBuy = 50_000_000;
    uint256 public minUsdAmountToBuy = 24900000000000000000; 
    uint256 public currentStage = 0;
    uint256 public checkPoint = 0;

    uint256[][3] public stages;
    uint256[][2] public bonuses = [[uint256(75), 150, 250, 500], [uint256(25), 50, 75, 100]];

    address public saleTokenAdress;

    IERC20 public USDTInterface = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    mapping(address => uint256) public userDeposits;
    mapping(address => bool) public hasClaimed;
    mapping(address => uint256) public userStage;

    event SaleTimeSet(uint256 _start, uint256 _end, uint256 timestamp);
    event SaleTimeUpdated(bytes32 indexed key, uint256 prevValue, uint256 newValue, uint256 timestamp);
    event TokensBought(address indexed user, uint256 indexed tokensBought, uint256 bonusTokens, uint256 totalTokens, address indexed purchaseToken, uint256 amountPaid, uint256 usdEq, uint256 timestamp);
    event TokensAdded(address indexed token, uint256 noOfTokens, uint256 timestamp);
    event TokensClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event ClaimStartUpdated(uint256 prevValue, uint256 newValue, uint256 timestamp);

     /**
     * @dev Initializes the contract and sets key parameters
     * @param _startTime start time of the presale
     * @param _endTime end time of the presale
     * @param _stages stage data
     */
    constructor (uint256 _startTime, uint256 _endTime, uint256[][3] memory _stages) {
        require(_startTime > block.timestamp && _endTime > _startTime, "Invalid time");
        startTime = _startTime;
        endTime = _endTime;
        stages = _stages;
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
     * @dev To change maxTokensToBuy amount
     * @param _maxTokensToBuy New max token amount
     */
    function changeMaxTokensToBuy(uint256 _maxTokensToBuy) external onlyOwner {
        require(_maxTokensToBuy > 0, 'Zero max tokens to buy value');
        maxTokensToBuy = _maxTokensToBuy;
    }

    /**
     * @dev To change minUsdAmountToBuy. If zero, there is no min limit.
     * @param _minUsdAmount New min USD amount
     */
    function changeMinUsdAmountToBuy(uint256 _minUsdAmount) external onlyOwner {
        minUsdAmountToBuy = _minUsdAmount;
    }

    /**
     * @dev To change stages data
     * @param _stages New stage data
     */
    function changeStages(uint256[][3] memory _stages) external onlyOwner {
        stages = _stages;
    }

    /**
     * @dev To change bonus data
     * @param _bonuses New bonus data
     */
    function changeBonuses(uint256[][2] memory _bonuses) external onlyOwner {
        bonuses = _bonuses;
    }

    /**
     * @dev To change USDT interface
     * @param _address Address of the USDT interface
     */
    function changeUSDTInterface(address _address) external onlyOwner {
        USDTInterface = IERC20(_address);
    }

    /**
     * @dev To change aggregator interface
     * @param _address Address of the aggregator interface
     */
    function changeAggregatorInterface(address _address) external onlyOwner {
        priceFeed = AggregatorV3Interface(_address);
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
     * @dev To calculate the price in USD for given amount of tokens.
     * @param _amount No of tokens
     */
    function calculatePrice(uint256 _amount) public view returns (uint256) {
        uint256 USDTAmount;
        uint256 total = checkPoint == 0 ? totalTokensSold : checkPoint;
        require(_amount <= maxTokensToBuy, 'Amount exceeds max tokens to buy');
        if (_amount + total > stages[0][currentStage] || block.timestamp >= stages[2][currentStage]) {
            require(currentStage < (stages[0].length - 1), 'Not valid');
            if (block.timestamp >= stages[2][currentStage]) {
                require(stages[0][currentStage] + _amount <= stages[0][currentStage + 1], '');
                USDTAmount = _amount * stages[1][currentStage + 1];
            } else {
                uint256 tokenAmountForCurrentPrice = stages[0][currentStage] - total;
                USDTAmount = tokenAmountForCurrentPrice * stages[1][currentStage] + (_amount - tokenAmountForCurrentPrice) * stages[1][currentStage + 1];
            }
        } else USDTAmount = _amount * stages[1][currentStage];
        return USDTAmount;
    }

    /**
     * @dev To calculate rewards in CHMPZ coin for given amount of tokens and usd price.
     * @param _amount No of tokens
     * @param _usdAmount usd price
     */
    function calculateBonus(uint256 _amount, uint256 _usdAmount) public view returns (uint256) {
        uint256 bonusCoins;
        require(_usdAmount >= minUsdAmountToBuy, 'Min usd not reached');
        for (uint i = bonuses[0].length; i > 0; i--) {
            if (_usdAmount >= (bonuses[0][i - 1] * baseDecimals)) {
                bonusCoins = ((bonuses[1][i - 1] * 100) * _amount) / 10_000;
                break;
            } else bonusCoins = 0;
        }
        return bonusCoins;
    }

    /**
     * @dev To update the sale times
     * @param _startTime New start time
     * @param _endTime New end time
     */
    function changeSaleTimes(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_startTime > 0 || _endTime > 0, 'Invalid parameters');
        if (_startTime > 0) {
            uint256 prevValue = startTime;
            startTime = _startTime;
            emit SaleTimeUpdated(bytes32('START'), prevValue, _startTime, block.timestamp);
        }

        if (_endTime > 0) {
            uint256 prevValue = endTime;
            endTime = _endTime;
            emit SaleTimeUpdated(bytes32('END'), prevValue, _endTime, block.timestamp);
        }
    }

    /**
     * @dev To get latest ETH price in 10**18 format
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        price = (price * (10**10));
        return uint256(price);
    }

    /**
     * @dev To buy into a presale using USDT
     * @param amount No of tokens to buy
     */
    function buyWithUSDT(uint256 amount) external checkSaleState(amount) whenNotPaused returns (bool) {
        uint256 usdPrice = calculatePrice(amount);
        uint256 bonusCoins = calculateBonus(amount, usdPrice);
        uint256 newAmount = amount + bonusCoins;
        totalTokensSold += amount;
        totalTokensSoldWithBonus += newAmount;
        if (usdPrice >= (bonuses[0][0] * baseDecimals) && userStage[_msgSender()] == 0) userStage[_msgSender()] = currentStage + 1;
        if (checkPoint != 0) checkPoint += amount;
        uint256 total = totalTokensSold > checkPoint ? totalTokensSold : checkPoint;
        if (total > stages[0][currentStage] || block.timestamp >= stages[2][currentStage]) {
            if (block.timestamp >= stages[2][currentStage]) {
                 checkPoint = stages[0][currentStage] + amount;
            }
            currentStage += 1;
        }
        userDeposits[_msgSender()] += (newAmount * baseDecimals);
        totalUsdRaised += usdPrice;
        uint256 ourAllowance = USDTInterface.allowance(_msgSender(), address(this));
        uint256 price = usdPrice / (10 ** 12);
        require(price <= ourAllowance, 'Not enough allowance');
        (bool success, ) = address(USDTInterface).call(abi.encodeWithSignature('transferFrom(address,address,uint256)', _msgSender(), owner(), price));
        require(success, 'Token payment failed');
        emit TokensBought(_msgSender(), amount, bonusCoins, newAmount, address(USDTInterface), usdPrice, usdPrice, block.timestamp);
        return true;
    }

    /**
     * @dev To buy into a presale using ETH
     * @param amount No of tokens to buy
     */
    function buyWithEth(uint256 amount) external payable checkSaleState(amount) whenNotPaused nonReentrant returns (bool) {
        uint256 usdPrice = calculatePrice(amount);
        uint256 ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
        require(msg.value >= ethAmount, 'Less payment');
        uint256 bonusCoins = calculateBonus(amount, usdPrice);
        uint256 newAmount = amount + bonusCoins;
        uint256 excess = msg.value - ethAmount;
        totalTokensSold += amount;
        totalTokensSoldWithBonus += newAmount;
        if (usdPrice >= (bonuses[0][0] * baseDecimals) && userStage[_msgSender()] == 0) userStage[_msgSender()] = currentStage + 1;
        if (checkPoint != 0) checkPoint += amount;
        uint256 total = totalTokensSold > checkPoint ? totalTokensSold : checkPoint;
        if (total > stages[0][currentStage] || block.timestamp >= stages[2][currentStage]) {
            if (block.timestamp >= stages[2][currentStage]) {
                checkPoint = stages[0][currentStage] + amount;
            }
            currentStage += 1;
        }
        userDeposits[_msgSender()] += (newAmount * baseDecimals);
        totalUsdRaised += usdPrice;
        sendValue(payable(owner()), ethAmount);
        if (excess > 0) sendValue(payable(_msgSender()), excess);
        emit TokensBought(_msgSender(), amount, bonusCoins, newAmount, address(0), ethAmount, usdPrice, block.timestamp);
        return true;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    /**
     * @dev To set the claim start time and sale token address by the owner
     * @param _claimStart claim start time
     * @param noOfTokens Number of tokens to add to the contract
     * @param _saleTokenAdress sale token address
     */
    function startClaim(uint256 _claimStart, uint256 noOfTokens, address _saleTokenAdress) external onlyOwner returns (bool) {
        require(_claimStart > endTime && _claimStart > block.timestamp, "Invalid claim start time");
        require(noOfTokens >= (totalTokensSoldWithBonus * baseDecimals), "Tokens less than sold");
        require(_saleTokenAdress != address(0), "Zero token address");
        require(claimStart == 0, "Claim already set");
        claimStart = _claimStart;
        saleTokenAdress = _saleTokenAdress;
        bool success = IERC20(_saleTokenAdress).transferFrom(_msgSender(), address(this), noOfTokens);
        require(success, "Token transfer failed");
        emit TokensAdded(saleTokenAdress, noOfTokens, block.timestamp);
        return true;
    }

    /**
     * @dev To change the claim start time by the owner
     * @param _claimStart new claim start time
     */
    function changeClaimStartTime(uint256 _claimStart) external onlyOwner returns (bool) {
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
        require(saleTokenAdress != address(0), "Sale token not added");
        require(block.timestamp >= claimStart, "Claim has not started yet");
        require(!hasClaimed[_msgSender()], "Already claimed");
        hasClaimed[_msgSender()] = true;
        uint256 amount = userDeposits[_msgSender()];
        require(amount > 0, "Nothing to claim");
        delete userDeposits[_msgSender()];
        bool success = IERC20(saleTokenAdress).transfer(_msgSender(), amount);
        require(success, "Token transfer failed");
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
        return true;
    }

    /**
     * @dev To manualy increment stage
     */
    function incrementCurrentStage() external onlyOwner {
        currentStage++;
        checkPoint = stages[0][currentStage];
    }

    /**
     * @dev Helper funtion to get stage information
     */
    function getStages() external view returns (uint256[][3] memory) {
        return stages;
    }
    
    /**
     * @dev Helper funtion to get bonus information
     */
    function getBonuses() external view returns (uint256[][2] memory) {
        return bonuses;
    }

    function manualBuy(address _to, uint256 amount) external onlyOwner {
        uint256 usdPrice = calculatePrice(amount);
        uint256 bonusCoins = calculateBonus(amount, usdPrice);
        uint256 newAmount = amount + bonusCoins;
        totalTokensSold += amount;
        totalTokensSoldWithBonus += newAmount;
        if (usdPrice >= (bonuses[0][0] * baseDecimals) && userStage[_to] == 0) userStage[_to] = currentStage + 1;
        userDeposits[_to] += (newAmount * baseDecimals);
        totalUsdRaised += usdPrice;
    }
}
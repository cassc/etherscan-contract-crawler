// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/v1/IMetacadePresale.v1.sol";
import "../interfaces/v2/IMetacadePresale.v2.sol";
import "../interfaces/IAggregator.sol";

contract MetacadePresaleV2 is IMetacadePresaleV2, Pausable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    address public immutable saleToken;
    IMetacadePresaleV1 public immutable previousPresale;
    IMetacadePresaleV1 public immutable betaPresale;

    uint256 public totalTokensSold;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimStart;
    uint256 public currentStep;

    uint256[9] public token_amount;
    uint256[9] public token_price;
    uint8 constant maxStepIndex = 8;
    bool isSynchronized;

    IERC20 public USDTInterface;
    IAggregator public aggregatorInterface;

    mapping(address => uint256) _userDeposits;
    mapping(address => bool) public hasClaimed;
    mapping(address => bool) public blacklist;

    modifier checkSaleState(uint256 amount) {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Invalid time for buying"
        );
        require(amount > 0, "Invalid sale amount");
        require(amount + totalTokensSold <= token_amount[maxStepIndex], "Insufficient funds");
        _;
    }

    modifier notBlacklisted() {
        require(!blacklist[_msgSender()], "You are in blacklist");
        _;
    }

    /**
     * @dev Creates the contract
     * @param _previousPresale      - Address of previous presale
     * @param _betaPresale          - Address of beta presale
     * @param _saleToken start      - Address of Metacade token
     * @param _aggregatorInterface  - Address of Chainlink ETH/USD price feed
     * @param _USDTInterface        - Address of USDT token
     * @param _token_amount         - Array of prices for each presale step
     * @param _token_price          - Array of totalTokenSold limit for each step
     * @param _startTime            - Sale start time
     * @param _endTime              - Sale end time
     */
    constructor(
        address _previousPresale,
        address _betaPresale,
        address _saleToken,
        address _aggregatorInterface,
        address _USDTInterface,
        uint256[9] memory _token_amount,
        uint256[9] memory _token_price,
        uint256 _startTime,
        uint256 _endTime
    ) {
        require(_aggregatorInterface != address(0), "Zero aggregator address");
        require(_USDTInterface != address(0), "Zero USDT address");
        require(_saleToken != address(0), "Zero sale token address");
        require(
            _endTime > _startTime,
            "Invalid time"
        );
        previousPresale = IMetacadePresaleV1(_previousPresale);
        betaPresale = IMetacadePresaleV1(_betaPresale);
        saleToken = _saleToken;
        aggregatorInterface = IAggregator(_aggregatorInterface);
        USDTInterface = IERC20(_USDTInterface);
        token_amount = _token_amount;
        token_price = _token_price;
        startTime = _startTime;
        endTime = _endTime;

        emit SaleTimeSet(_startTime, _endTime, block.timestamp);
    }


    /**
     * @dev To synchronize totalTokensSold with previous presales and calculate current step
     */
    function sync() external onlyOwner {
        require(!isSynchronized, "Already synchronized");
        totalTokensSold = previousPresale.totalTokensSold() + betaPresale.totalTokensSold();
        currentStep = _getStepByTotalSoldAmount();
        isSynchronized = true;
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
     * @dev To update the sale times
     * @param _startTime - New sales start time
     * @param _endTime   - New sales end time
     */
    function changeSaleTimes(uint256 _startTime, uint256 _endTime)
    external
    onlyOwner
    {
            if (startTime != _startTime) startTime = _startTime;
            if (endTime != _endTime) endTime = _endTime;
            emit SaleTimeSet(
                _startTime,
                _endTime,
                block.timestamp
        );
    }

    /**
     * @dev To set the claim
     * @param _claimStart - claim start time
     * @notice Function also makes sure that presale have enough sale token balance
     */
    function configureClaim(
        uint256 _claimStart
    ) external onlyOwner returns (bool) {
        require(IERC20(saleToken).balanceOf(address(this)) >= totalTokensSold * 1e18, "Not enough balance");
        claimStart = _claimStart;
        return true;
    }

    /**
     * @dev To add users to blacklist
     * @param _users - Array of addresses to add in blacklist
     */
    function addToBlacklist(address[] calldata _users) external onlyOwner {
        uint256 usersAmount = _users.length;
        uint256 i = 0;
        while(i<usersAmount) blacklist[_users[i++]] = true;
    }

    /**
     * @dev To remove users from blacklist
     * @param _users - Array of addresses to remove from blacklist
     */
    function removeFromBlacklist(address[] calldata _users) external onlyOwner {
        uint256 usersAmount = _users.length;
        uint256 i = 0;
        while(i<usersAmount) blacklist[_users[i++]] = false;
    }

    /**
     * @dev Returns price for current step
     */
    function getCurrentPrice() external view returns (uint256) {
        return token_price[currentStep];
    }

    /**
     * @dev Returns amount of tokens sold on current step
     */
    function getSoldOnCurrentStage() external view returns (uint256 soldOnCurrentStage) {
        soldOnCurrentStage = totalTokensSold - ((currentStep == 0)? 0 : token_amount[currentStep-1]);
    }

    /**
     * @dev Returns presale last stage token amount limit
     */
    function getTotalPresaleAmount() external view returns (uint256) {
        return token_amount[maxStepIndex];
    }

    /**
     * @dev Returns total price of sold tokens
     * @notice Value may be inaccurate, since not all tokens were sold on the beta presale
     */
    function totalSoldPrice() external view returns (uint256) {
        return _calculateInternalCost(totalTokensSold, 0 ,0);
    }

    /**
     * @dev Returns total price of sold tokens
     * @param _tokenAddress - Address of token to resque
     * @param _amount       - Amount of tokens to resque
     */
    function resqueERC20(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(_msgSender(), _amount);
    }

    /**
     * @dev Returns tokens purchased by the user
     * @param _user - Address of user
     * @notice Takes into account the number of tokens purchased by the user on the previous presale and beta presale
     */
    function userDeposits(address _user) public view returns(uint256) {
        if (hasClaimed[_user]) return 0;
        return _userDeposits[_user] + previousPresale.userDeposits(_user) + betaPresale.userDeposits(_user);
    }

    /**
     * @dev To buy into a presale using ETH
     * @param _amount - Amount of tokens to buy
     */
    function buyWithEth(uint256 _amount) external payable checkSaleState(_amount) notBlacklisted whenNotPaused nonReentrant returns (bool) {
        uint256 ethAmount = ethBuyHelper(_amount);
        require(msg.value >= ethAmount, "Less payment");
        _sendValue(payable(owner()), ethAmount);
        uint256 excess = msg.value - ethAmount;
        if (excess > 0) _sendValue(payable(_msgSender()), excess);
        totalTokensSold += _amount;
        _userDeposits[_msgSender()] += _amount * 1e18;
        uint8 stepAfterPurchase = _getStepByTotalSoldAmount();
        if (stepAfterPurchase>currentStep) currentStep = stepAfterPurchase;
        emit TokensBought(
            _msgSender(),
            _amount,
            ethAmount,
            block.timestamp
        );
        return true;
    }

    /**
     * @dev To buy into a presale using USDT
     * @param _amount - Amount of tokens to buy
     */
    function buyWithUSDT(uint256 _amount) external checkSaleState(_amount) notBlacklisted whenNotPaused nonReentrant returns (bool) {
        uint256 usdtPrice = usdtBuyHelper(_amount);
        require(usdtPrice <= USDTInterface.allowance(
            _msgSender(),
            address(this)
        ), "Not enough allowance");
        USDTInterface.safeTransferFrom(
                _msgSender(),
                owner(),
                usdtPrice
            );
        totalTokensSold += _amount;
        _userDeposits[_msgSender()] += _amount * 1e18;
        uint8 stepAfterPurchase = _getStepByTotalSoldAmount();
        if (stepAfterPurchase>currentStep) currentStep = stepAfterPurchase;
        emit TokensBought(
            _msgSender(),
            _amount,
            usdtPrice,
            block.timestamp
        );
        return true;
    }

    /**
     * @dev To claim tokens after claiming starts
     */
    function claim() external whenNotPaused nonReentrant {
        require(block.timestamp >= claimStart && claimStart > 0, "Claim has not started yet");
        require(!hasClaimed[_msgSender()], "Already claimed");
        uint256 amount = userDeposits(_msgSender());
        require(amount > 0, "Nothing to claim");
        hasClaimed[_msgSender()] = true;
        IERC20(saleToken).safeTransfer(_msgSender(), amount);
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
    }

    /**
     * @dev To get latest ETH/USD price
     * @notice Return result in 1e18 format
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , ,) = aggregatorInterface.latestRoundData();
        return uint256(price * 1e10);
    }

    /**
     * @dev Calculate ETH price for given amount
     * @param _amount - Amount of tokens to calculate price
     * @notice Return result in 1e18 format
     */
    function ethBuyHelper(uint256 _amount) public view returns (uint256 ethAmount) {
        ethAmount = calculatePrice(_amount) * 1e18  / getLatestPrice();
    }

    /**
     * @dev Calculate USDT price for given amount
     * @param _amount - Amount of tokens to calculate price
     * @notice Return result in 1e6 format
     */
    function usdtBuyHelper(uint256 _amount) public view returns (uint256 usdtPrice) {
        usdtPrice = calculatePrice(_amount) / 1e12;
    }

    /**
     * @dev To calculate the price in USD for given amount of tokens
     * @param _amount - Amount of tokens to calculate price
     * @notice Return result in 1e18 format
     */
    function calculatePrice(uint256 _amount) public view returns (uint256) {
        require(_amount + totalTokensSold <= token_amount[maxStepIndex], "Insufficient token amount.");
        return _calculateInternalCost(_amount, currentStep, totalTokensSold);
    }

    /**
     * @dev For sending ETH from contract
     * @param _recipient - Recipient address
     * @param _weiAmount - Amount of ETH to send in wei
     */
    function _sendValue(address payable _recipient, uint256 _weiAmount) internal {
        require(address(this).balance >= _weiAmount, "Low balance");
        (bool success,) = _recipient.call{value : _weiAmount}("");
        require(success, "ETH Payment failed");
    }

    /**
     * @dev Recursively calculate cost for specified conditions
     * @param _amount          - Amount of tokens to calculate price
     * @param _currentStep     - Starting step to calculate price
     * @param _totalTokensSold - Starting total token sold amount to calculate price
     */
    function _calculateInternalCost(uint256 _amount, uint256 _currentStep, uint256 _totalTokensSold) internal view returns (uint256 cost){
        uint256 currentPrice = token_price[_currentStep];
        uint256 currentAmount = token_amount[_currentStep];
        if (_totalTokensSold + _amount <= currentAmount) {
            cost = _amount * currentPrice;
        }
        else {
            uint256 currentStageAmount = currentAmount - _totalTokensSold;
            uint256 nextStageAmount = _amount - currentStageAmount;
            cost = currentStageAmount * currentPrice + _calculateInternalCost(nextStageAmount, _currentStep + 1, currentAmount);
        }

        return cost;
    }

    /**
     * @dev Calculate current step amount from total tokens sold amount
     */
    function _getStepByTotalSoldAmount() internal view returns (uint8) {
        uint8 stepIndex = maxStepIndex;
        while (stepIndex > 0) {
            if (token_amount[stepIndex - 1] < totalTokensSold) break;
            stepIndex -= 1;
        }
        return stepIndex;
    }
}
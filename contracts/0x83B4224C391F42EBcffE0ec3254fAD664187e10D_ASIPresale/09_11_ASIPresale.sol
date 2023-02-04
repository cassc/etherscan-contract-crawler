// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IChainlinkPriceFeed.sol";
import "./interfaces/IPresale.sol";

contract ASIPresale is IPresale, Pausable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @dev Address of token contract
     */
    address public immutable saleToken;

    /**
     * @dev Total amount of purchased tokens
     */
    uint256 public totalTokensSold;

    /**
     * @dev Timestamp when purchased tokens claim starts
     */
    uint256 public claimStartTime;

    /**
     * @dev Timestamp when presale starts
     */
    uint256 public saleStartTime;

    /**
     * @dev Timestamp when presale ends
     */
    uint256 public saleEndTime;

    /**
     * @dev Last stage index
     */
    uint8 constant MAX_STAGE_INDEX = 3;

    /**
     * @dev Amount of totalTokensSold limits for each stage
     */
    uint256[4] public limitPerStage;



    /**
     * @dev Sale prices for each stage
     */
    uint256[4] public pricePerStage;

    /**
     * @dev Index of current stage
     */
    uint8 public currentStage;

    /**
     * @dev Address of USDT token
     */
    IERC20 public USDTToken;

    /**
     * @dev Address of chainlink ETH/USD price feed
     */
    IChainlinkPriceFeed public oracle;

    /**
     * @dev Stores the number of tokens purchased by each user that have not yet been claimed
     */
    mapping(address => uint256) public purchasedTokens;

    /**
     * @dev Indicates whether the user is blacklisted or not
     */
    mapping(address => bool) public blacklist;

    /**
     * @dev Checks that it is now possible to purchase passed amount tokens
     * @param amount - the number of tokens to verify the possibility of purchase
     */
    modifier verifyPurchase(uint256 amount) {
        require(
            block.timestamp >= saleStartTime && block.timestamp <= saleEndTime,
            "Invalid time for buying"
        );
        require(amount > 0, "Incorrect token amount");
        require(amount + totalTokensSold <= limitPerStage[MAX_STAGE_INDEX], "Exceeded presale limit");
        _;
    }


    /**
     * @dev Verifies that the sender isn't blacklisted
     */
    modifier notBlacklisted() {
        require(!blacklist[_msgSender()], "You are in blacklist");
        _;
    }

    /**
     * @dev Creates the contract
     * @param _saleToken      - Address of presailing token
     * @param _oracle         - Address of Chainlink ETH/USD price feed
     * @param _usdt           - Address of USDT token
     * @param _limitPerStage  - Array of prices for each presale stage
     * @param _pricePerStage  - Array of totalTokenSold limit for each stage
     * @param _saleStartTime  - Sale start time
     * @param _saleEndTime    - Sale end time
     */
    constructor(
        address _saleToken,
        address _oracle,
        address _usdt,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint256[4] memory _limitPerStage,
        uint256[4] memory _pricePerStage
    )
    {
        require(_oracle != address(0), "Zero aggregator address");
        require(_usdt != address(0), "Zero USDT address");
        require(_saleToken != address(0), "Zero sale token address");
        require(
            _saleStartTime > block.timestamp && _saleEndTime > _saleStartTime,
            "Invalid time"
        );

        saleToken = _saleToken;
        oracle = IChainlinkPriceFeed(_oracle);
        USDTToken = IERC20(_usdt);
        limitPerStage = _limitPerStage;
        pricePerStage = _pricePerStage;
        saleStartTime = _saleStartTime;
        saleEndTime = _saleEndTime;

        emit SaleTimeUpdated(
            _saleStartTime,
            _saleEndTime,
            block.timestamp
        );
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
     * @dev To add users to blacklist
     * @param _users - Array of addresses to add in blacklist
     */
    function addToBlacklist(address[] calldata _users) external onlyOwner {
        uint256 usersAmount = _users.length;
        uint256 i = 0;
        while(i<usersAmount)
            blacklist[_users[i++]] = true;
    }

    /**
     * @dev To remove users from blacklist
     * @param _users - Array of addresses to remove from blacklist
     */
    function removeFromBlacklist(address[] calldata _users) external onlyOwner {
        uint256 usersAmount = _users.length;
        uint256 i = 0;
        while(i<usersAmount)
            blacklist[_users[i++]] = false;
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
     * @dev To update the sale start and end times
     * @param _saleStartTime - New sales start time
     * @param _saleEndTime - New sales end time
     */
    function configureSaleTimeframe(uint256 _saleStartTime, uint256 _saleEndTime) external onlyOwner {
        if(saleStartTime != _saleStartTime)
            saleStartTime = _saleStartTime;
        if(saleEndTime != _saleEndTime)
            saleEndTime = _saleEndTime;
        emit SaleTimeUpdated(
            _saleStartTime,
            _saleEndTime,
            block.timestamp
        );
    }

    /**
     * @dev To set the claim start time
     * @param _claimStartTime - claim start time
     * @notice Function also makes sure that presale have enough sale token balance
     */
    function configureClaim(uint256 _claimStartTime) external onlyOwner {
        require(IERC20(saleToken).balanceOf(address(this)) >= totalTokensSold * 1e18, "Not enough balance");
        claimStartTime = _claimStartTime;
        emit ClaimStartTimeUpdated(_claimStartTime, block.timestamp);
    }

    /**
     * @dev To buy into a presale using ETH
     * @param _amount - Amount of tokens to buy
     */
    function buyWithEth(uint256 _amount) external payable notBlacklisted verifyPurchase(_amount) whenNotPaused nonReentrant {
        uint256 priceInETH = getPriceInETH(_amount);
        require(msg.value >= priceInETH, "Not enough ETH");
        _sendValue(payable(owner()), priceInETH);
        uint256 excess = msg.value - priceInETH;
        if (excess > 0)
            _sendValue(payable(_msgSender()), excess);
        totalTokensSold += _amount;
        purchasedTokens[_msgSender()] += _amount * 1e18;
        uint8 stageAfterPurchase = _getStageByTotalSoldAmount();
        if (stageAfterPurchase>currentStage)
            currentStage = stageAfterPurchase;
        emit TokensBought(
            _msgSender(),
            "ETH",
            _amount,
            getPriceInUSDT(_amount),
            priceInETH,
            block.timestamp
        );
    }

    /**
     * @dev To buy into a presale using USDT
     * @param _amount - Amount of tokens to buy
     */
    function buyWithUSDT(uint256 _amount) external notBlacklisted verifyPurchase(_amount) whenNotPaused nonReentrant {
        uint256 priceInUsdt = getPriceInUSDT(_amount);
        uint256 allowance = USDTToken.allowance(
            _msgSender(),
            address(this)
        );
        require(priceInUsdt <= allowance, "Make sure to add enough allowance");
        USDTToken.safeTransferFrom(
                _msgSender(),
                owner(),
            priceInUsdt
        );
        totalTokensSold += _amount;
        purchasedTokens[_msgSender()] += _amount * 1e18;
        uint8 stageAfterPurchase = _getStageByTotalSoldAmount();
        if (stageAfterPurchase>currentStage)
            currentStage = stageAfterPurchase;
        emit TokensBought(
            _msgSender(),
            "USDT",
            _amount,
            getPriceInUSDT(_amount),
            priceInUsdt,
            block.timestamp
        );
    }

    /**
     * @dev To claim tokens after claiming starts
     */
    function claim() external whenNotPaused {
        require(block.timestamp >= claimStartTime && claimStartTime > 0, "Claim has not started yet");
        uint256 amount = purchasedTokens[_msgSender()];
        require(amount > 0, "Nothing to claim");
        purchasedTokens[_msgSender()] -= amount;
        IERC20(saleToken).safeTransfer(_msgSender(), amount);
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
    }

    /**
     * @dev Returns price for current stage
     */
    function getCurrentPrice() external view returns (uint256) {
        return pricePerStage[currentStage];
    }

    /**
     * @dev Returns amount of tokens sold on current stage
     */
    function getSoldOnCurrentStage() external view returns (uint256 soldOnCurrentStage) {
        soldOnCurrentStage = totalTokensSold - ((currentStage == 0)? 0 : limitPerStage[currentStage]);
    }

    /**
     * @dev Returns presale last stage token amount limit
     */
    function getTotalPresaleAmount() external view returns (uint256) {
        return limitPerStage[MAX_STAGE_INDEX];
    }

    /**
     * @dev Returns total price of sold tokens
     */
    function totalSoldPrice() external view returns (uint256) {
        return _calculatePriceInUSDTForConditions(totalTokensSold, 0, 0);
    }

    /**
     * @dev Helper function to calculate ETH price for given amount
     * @param _amount - Amount of tokens to buy
     * @notice Will return value in 1e18 format
     */
    function getPriceInETH(uint256 _amount) public view returns (uint256 ethAmount) {
        (, int256 price, , ,) = oracle.latestRoundData();//Chainlink oracle is trusted source of truth, so price will always be positive
        ethAmount = getPriceInUSDT(_amount) * 1e20  / uint256(price);//We need 1e20 to get resulting value in wei(1e18)
    }

    /**
     * @dev Calculate price in USDT
     * @param _amount - Amount of tokens to calculate price
     * @notice Will return value in 1e6 format
     */
    function getPriceInUSDT(uint256 _amount) public view returns (uint256) {
        require(_amount + totalTokensSold <= limitPerStage[MAX_STAGE_INDEX], "Insufficient funds");
        return _calculatePriceInUSDTForConditions(_amount, currentStage, totalTokensSold);
    }

    /**
     * @dev For sending ETH from contract
     * @param _recipient - Recipient address
     * @param _ethAmount - Amount of ETH to send in wei
     */
    function _sendValue(address payable _recipient, uint256 _ethAmount) internal {
        require(address(this).balance >= _ethAmount, "Low balance");
        (bool success,) = _recipient.call{value : _ethAmount}("");
        require(success, "ETH Payment failed");
    }

    /**
     * @dev Recursively calculate USDT cost for specified conditions
     * @param _amount           - Amount of tokens to calculate price
     * @param _currentStage     - Starting stage to calculate price
     * @param _totalTokensSold  - Starting total token sold amount to calculate price
     */
    function _calculatePriceInUSDTForConditions(uint256 _amount, uint256 _currentStage, uint256 _totalTokensSold) internal view returns (uint256 cost){
        if (_totalTokensSold + _amount <= limitPerStage[_currentStage]) {
            cost = _amount * pricePerStage[_currentStage];
        } else {
            uint256 currentStageAmount = limitPerStage[_currentStage] - _totalTokensSold;
            uint256 nextStageAmount = _amount - currentStageAmount;
            cost = currentStageAmount * pricePerStage[_currentStage]
                + _calculatePriceInUSDTForConditions(nextStageAmount, _currentStage + 1, limitPerStage[_currentStage]);
        }

        return cost;
    }

    /**
     * @dev Calculate current stage amount from total tokens sold amount
     */
    function _getStageByTotalSoldAmount() internal view returns (uint8) {
        uint8 stageIndex = MAX_STAGE_INDEX;
        while (stageIndex > 0) {
            if (limitPerStage[stageIndex - 1] < totalTokensSold)
                break;
            stageIndex -= 1;
        }
        return stageIndex;
    }
}
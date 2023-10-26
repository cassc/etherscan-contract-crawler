// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


import {UD60x18, intoUint256, ud} from "@prb/math/src/UD60x18.sol";

/**
 * @title Feeding Contract
 * @dev Manages the feeding of tokens and reward vesting.
 */
contract Feeding is Ownable {
    // ==================== STRUCTURE ==================== //

    struct Vesting {
        address tokenFed;
        uint256 valueFed;
        uint256 rewardMultiple;
        uint256 amount;
        uint256 start;
        uint256 vestingTime;
        bool claimed;
    }

    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 public feedPoolRewardThreshold;
    uint256 public growthRateIncrease;
    uint256 public baseGrowthRate;

    address public constant BLOB = 0x5483C2CC7ed1D2074f4AE7a34B00aB8A4c6c6b42; 
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 

    uint256 private blobSlippage = 15e4; 

    mapping(address => address[]) public tokenPath; 
    mapping(address => uint256) public totalFed;
    mapping(address => bool) public isFeedToken;
    address[] feedTokensList;
    uint256 public totalBlobGiven;

    mapping(address => Vesting[]) public vestingBalances;

    // ==================== EVENTS ==================== //

    event SetTokenPath(address _token);
    event AddFeedToken(address _token);
    event RemoveFeedToken(address _token);
    event Feed(address _token, uint256 _amount);
    event Claim(uint256 _amount);
    event SetRouterAddress(address _routerAddress);
    event SetRewardsAddress(address _rewardAddress);
    event SetRewardsThreshold(uint256 _threshold);
    event SetBlobsSlippage(uint256 _slippage);
    event SetGrowthRatesIncrease(uint256 _growthRate);
    event SetBaseGrowthRates(uint256 _baseGrowthRate);

    // ==================== MODIFIERS ==================== //

    modifier vestingExists(address account, uint256 index) {
        require(
            index < vestingBalances[account].length,
            "Vesting doesn't exist"
        );
        _;
    }

    modifier isValidAddress(address account) {
        require(account != address(0), "Invalid address");
        _;
    }

    // ==================== CONSTRUCTOR ==================== //

    constructor(
        uint256 _feedPoolRewardThreshold,
        uint256 _baseGrowthRate,
        uint256 _growthRateIncrease
    ) {
        feedPoolRewardThreshold = _feedPoolRewardThreshold;
        baseGrowthRate = _baseGrowthRate;
        growthRateIncrease = _growthRateIncrease;
        tokenPath[WETH] = [WETH, BLOB];

    }

    // ==================== FUNCTIONS ==================== //

    /**
     * @dev Returns the amount of WETH rewards in the contract.
     * @return Amount of WETH rewards
     */
    function getRewardsAmount() external view returns (uint256) {
        return IERC20(WETH).balanceOf(address(this));
    }

    /**
     * @dev Returns the list of feed tokens.
     * @return Array of feed tokens
     */
    function getFeedTokensList() external view returns (address[] memory) {
        return feedTokensList;
    }

    /**
     * @dev Returns the token path to blob for a given feed token.
     * @param token Feed token address
     * @return Array of addresses representing the token path to blob
     */
    function getPath(address token) external view returns (address[] memory) {
        return tokenPath[token];
    }

    /**
     * @dev Returns vesting data for a given user.
     * @param _user Address of the user
     * @return Array of Vesting struct representing user's vesting balances
     */
    function getVestingData(
        address _user
    ) external view returns (Vesting[] memory) {
        return vestingBalances[_user];
    }

    /**
     * @dev Sets the Uniswap router address.
     * @param _routerAddress New router address
     */
    function setRouter(
        address _routerAddress
    ) external onlyOwner isValidAddress(_routerAddress) {
        routerAddress = _routerAddress;
        emit SetRouterAddress(_routerAddress);
    }

    /**
     * @dev Sets the reward address.
     * @param _rewardAddress New reward address
     */
    function setRewardAddress(
        address _rewardAddress
    ) external onlyOwner isValidAddress(_rewardAddress) {
        WETH = _rewardAddress;
        emit SetRewardsAddress(_rewardAddress);

    }

    /**
     * @dev Sets the reward threshold for the feed pool.
     * @param _threshold New reward threshold
     */
    function setRewardThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold > 0, "Value must be greater than 0");
        feedPoolRewardThreshold = _threshold;
        emit SetRewardsThreshold(_threshold);
    }

    /**
     * @dev Sets the growth rate increase for reward calculation.
     * @param _growthRate New growth rate increase value
     */
    function setGrowthRateIncrease(uint256 _growthRate) external onlyOwner {
        require(_growthRate > 0, "Value must be greater than 0");
        growthRateIncrease = _growthRate;
        emit SetGrowthRatesIncrease(_growthRate);
    }

    /**
     * @dev Sets the base growth rate for reward calculation.
     * @param _baseGrowthRate New base growth rate value
     */
    function setBaseGrowthRate(uint256 _baseGrowthRate) external onlyOwner {
        require(_baseGrowthRate > 1e18, "Value must be greater than 1");
        baseGrowthRate = _baseGrowthRate;
        emit SetBaseGrowthRates(_baseGrowthRate);
    }

    /**
     * @dev Sets the token path to blob for a feed token.
     * @param _tokenPath New token path
     */
    function setTokenPath(address[] memory _tokenPath) external onlyOwner {
        tokenPath[_tokenPath[0]] = _tokenPath;
        emit SetTokenPath(_tokenPath[0]);
    }

    function setBlobSlippage(uint256 newSlippage) external onlyOwner {
        require(newSlippage >= 1e3 && newSlippage <= 100e4, "slippage must be between 0.1 to 100");
        blobSlippage = newSlippage;
        emit SetBlobsSlippage(newSlippage);
    }

    /**
     * @dev Adds a new feed token to the list.
     * @param _token New feed token address
     */
    function addFeedToken(address _token) external onlyOwner {
        feedTokensList.push(_token);
        isFeedToken[_token] = true;
        emit AddFeedToken(_token);
    }

    /**
     * @dev Removes a feed token from the list.
     * @param _index Index of the token to be removed
     */
    function removeFeedToken(uint256 _index) external onlyOwner {
        require(_index < feedTokensList.length, "Invalid index");
        address _token = feedTokensList[_index];
        feedTokensList[_index] = feedTokensList[feedTokensList.length - 1];
        feedTokensList.pop();
        isFeedToken[_token] = false;
        emit RemoveFeedToken(_token);
    }

    /**
     * @dev Withdraws funds from the contract to an external account.
     * @param account The recipient's address.
     * @param token The token to withdraw.
     * @param amount The amount to withdraw.
     */
    function withdrawFunds(
        address account,
        address token,
        uint256 amount
    ) external onlyOwner isValidAddress(account) {
        require(IERC20(token).balanceOf(address(this)) >= amount, "Not enough balance");
        IERC20(token).transfer(account, amount);
    }

    /**
     * @dev Feeds tokens into the contract and initiates vesting.
     * @param _tokenIn Token to be fed into the contract
     * @param _amountIn Amount of tokens to be fed
     * @param _slippage Maximum allowable slippage for token swap
     * @param _vestingTime Vesting period for the reward
     */
    function feed(
        address _tokenIn,
        uint256 _amountIn,
        uint256 _slippage,
        uint256 _vestingTime
    ) external {
        require(isFeedToken[_tokenIn], "Token is not available for feeding.");

        require(
            _vestingTime >= 1e18 && _vestingTime <= 7e18,
            "Vesting must be between 1 to 7"
        );
    

        require(
            _slippage >= 1e3 && _slippage <= 100e4,
            "slippage must be between 0.1 to 100"
        );

        uint256 _amountOutMin = _calculateAmountOutMin(
            _tokenIn,
            _amountIn,
            _slippage
        );

        uint256 blobBefore = IERC20(BLOB).balanceOf(address(this));

        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        _swap(_amountIn, tokenPath[_tokenIn], _amountOutMin);

        uint256 blobAfter = IERC20(BLOB).balanceOf(address(this));
        uint256 amount = blobAfter - blobBefore;
        uint256 rewardMultiple = calculateFeedReward(_vestingTime);
        uint256 totalAmount = _calculateReward(amount, rewardMultiple);

        totalBlobGiven += totalAmount;
        totalFed[_tokenIn] += _amountIn;

        // Store vesting balance
        vestingBalances[msg.sender].push(
            Vesting({
                tokenFed: _tokenIn,
                valueFed: _amountIn,
                rewardMultiple: rewardMultiple,
                amount: totalAmount,
                start: block.timestamp,
                vestingTime: block.timestamp + ((_vestingTime / 1e18) * 86400),
                claimed: false
            })
        );

        emit Feed(_tokenIn, _amountIn);
    }

    /**
     * @dev Claims the reward for a specific vesting entry.
     * @param _index Index of the vesting entry
     */

    function claim(
        uint256 _index
    ) external vestingExists(msg.sender, _index) {
        address account = msg.sender;
        Vesting storage info = vestingBalances[account][_index];
        require(!info.claimed, "Already claimed");
        require(
            block.timestamp >= info.vestingTime,
            "Vesting period not reached"
        );
        
        info.claimed = true;
        IERC20(BLOB).transfer(account, info.amount);

        emit Claim(info.amount);
    }

    /**
     * @dev Calculates the claimable reward for a specific vesting entry.
     * @param account Address of the account
     * @param _index Index of the vesting entry
     * @return Amount of claimable rewards
     */

    function claimable(
        address account,
        uint256 _index
    ) external view returns (uint256) {
        Vesting memory info = vestingBalances[account][_index];
        if (block.timestamp < info.vestingTime) {
            return 0;
        } else return info.amount;
    }

    /**
     * @dev Calculates the remaining time for vesting completion.
     * @param account Address of the account
     * @param _index Index of the vesting entry
     * @return Remaining time in seconds
     */
    function timeLeft(
        address account,
        uint256 _index
    ) external view returns (uint256) {
        Vesting memory info = vestingBalances[account][_index];
        if (block.timestamp < info.vestingTime) {
            return info.vestingTime - block.timestamp;
        } else return 0;
    }

    /**
     * @dev Calculates the reward multiple based on vesting time.
     * @param timeStaked Vesting time in seconds
     * @return Calculated reward multiple
     */
    function calculateFeedReward(
        uint256 timeStaked
    ) public view returns (uint256) {
        unchecked {
            uint256 feedPoolValue = IERC20(WETH).balanceOf(address(this));
            if (feedPoolValue == 0) return 1e18;

            UD60x18 term1 = (ud(feedPoolValue) / ud(feedPoolRewardThreshold)) +
                ud(1e18);

            UD60x18 term2 = (ud(growthRateIncrease) *
                ud(timeStaked) +
                ud(baseGrowthRate)).pow(ud(timeStaked));

            uint256 term3 = intoUint256(term1 * (term2 - ud(1e18)) + ud(1e18));

            return term3 > 2e18 ? 2e18 : term3;
        }
    }

    /**
     * @dev Calculates the reward to be distributed based on investment and reward multiple.
     * @param _investmentBlob Amount of BLOB tokens invested
     * @param _rewardMultiple Reward multiple based on vesting time
     * @return Total reward to be distributed
     */
    function _calculateReward(
        uint256 _investmentBlob,
        uint256 _rewardMultiple
    ) internal returns (uint256) {
        require(_rewardMultiple > 1e18, "Not enough rewards");

        uint256 totalBlob = (
            intoUint256(ud(_investmentBlob) * ud(_rewardMultiple))
        );

        uint256 rewardBlob = totalBlob - _investmentBlob;

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = BLOB;

        uint[] memory amounts = IUniswapV2Router02(routerAddress).getAmountsIn(
            rewardBlob,
            path
        );

        uint256 amount = amounts[0];
        uint256 minAmount = _calculateAmountOutMin(WETH, amount, blobSlippage);
        
        require(_hasEnoughBalance(WETH, amount), "Not enough rewards");
        require(tokenPath[WETH].length >= 2 && tokenPath[WETH][0] == WETH && tokenPath[WETH][1] == BLOB, "Invalid WETH to BLOB Path");
        _swap(amount, tokenPath[WETH], minAmount);

        return totalBlob;
    }

    /**
     * @dev Performs a token swap on Uniswap.
     * @param _amountIn Amount of tokens to be swapped
     * @param path Token path for the swap
     * @param _amountOutMin Minimum amount of tokens to receive from the swap
     */
    function _swap(
        uint256 _amountIn,
        address[] memory path,
        uint256 _amountOutMin
    ) internal {
        IERC20(path[0]).approve(routerAddress, _amountIn);
        IUniswapV2Router02(routerAddress)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amountIn,
                _amountOutMin,
                path,
                address(this), // Tokens are stored in this contract
                block.timestamp + 10 minutes
            );
    }

    /**
     * @dev Calculates the minimum amount of tokens to receive from a swap, accounting for slippage.
     * @param _tokenIn Token to be swapped
     * @param _amountIn Amount of tokens to be swapped
     * @param _slippage Maximum allowable slippage for the swap
     * @return Minimum amount of tokens to receive
     */
    function _calculateAmountOutMin(
        address _tokenIn,
        uint256 _amountIn,
        uint256 _slippage
    ) internal view returns (uint256) {
        uint256[] memory amountsOut = IUniswapV2Router02(routerAddress).getAmountsOut(_amountIn, tokenPath[_tokenIn]);


        uint256 amount = amountsOut[amountsOut.length - 1];

    

        return (amount -
            intoUint256(ud(amount) * ud((_slippage * 1e14) / 100)));
    }

    /**
     * @dev Checks if the contract has enough balance of a specific token.
     * @param _tokenAddress Address of the token to check
     * @param _amount Amount of tokens needed
     * @return Whether the contract has enough balance of the token or not
     */
    function _hasEnoughBalance(
        address _tokenAddress,
        uint256 _amount
    ) internal view returns (bool) {
        return IERC20(_tokenAddress).balanceOf(address(this)) >= _amount;
    }
}
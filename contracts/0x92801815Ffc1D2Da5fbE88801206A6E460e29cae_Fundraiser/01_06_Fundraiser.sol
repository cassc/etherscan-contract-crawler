//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Fundraiser is Ownable {
    struct FundraiserDetails {
        uint256 targetAmount;
        uint256 minContribution;
        uint256 currentAmount;
        address admin;
        uint40 targetTimestamp;
        uint8 noWhitelisted;
        bool killed;
        bool collected;
    }

    uint256 public platformFee = 499;
    uint256 public holdingFee = 499;
    uint256 public freeHoldingPeriod = 3600*24*30*6;
    uint256 public maxFundraiserDuration = 3600*24*30*12;
    
    uint256 public constant COMBINED_PERCENTAGE_PRECISION = 1000000;

    FundraiserDetails[] public fundraisers;
    mapping (address => mapping (uint256 => uint256)) public addressAndIndexToAmountFunded;
    mapping (address => mapping (uint256 => mapping(address => uint256))) public addressAndIndexToTokensFunded;
    mapping (address => mapping (uint256 => uint256)) public tokenAndIndexToValue;
    mapping (address => mapping (uint256 => uint256)) public tokenAndIndexToGoal;
    mapping (address => mapping (uint256 => bool)) public isTokenCollectedForFundraiser;

    bool public isCreateEnabled = false;

    event Create(address indexed admin, uint256 indexed index, uint256 targetTimestamp, uint256 targetAmount, uint256 minContribution, string name, string description);
    event WhitelistToken(uint256 indexed index, address indexed tokenAddress, uint256 goal, string tokenSymbol, uint256 decimals);
    event Donate(address indexed contributor, uint256 indexed index, uint256 value);
    event DonateToken(address indexed contributor, uint256 indexed index, uint256 value, address tokenAddress);
    event Refund(address indexed contributor, uint256 indexed index);
    event RefundToken(address indexed contributor, uint256 indexed index, address indexed tokenAddress);
    event Collect(uint256 indexed index);
    event CollectToken(uint256 indexed index, address indexed tokenAddress);
    event Killed(uint256 indexed index);


    // ======= Platform config =======

    /**
     * @dev Update free holding period
     */
    function updateFreeHoldingPeriod(uint256 newPeriodInSeconds) external onlyOwner {
        freeHoldingPeriod = newPeriodInSeconds;
    }

    /**
     * @dev Update max fundraiser duration
     */
    function updateMaxFundraiserDuration(uint256 newDurationInSeconds) external onlyOwner {
        maxFundraiserDuration = newDurationInSeconds;
    }

    /**
     * @dev Update holding fee
     */
    function updateHoldingFee(uint256 newHoldingFeeInPercentFractions) external onlyOwner {
        require(newHoldingFeeInPercentFractions <= 1000, "Fee too large");
        holdingFee = newHoldingFeeInPercentFractions;
    }

    /**
     * @dev Update platform fee
     */
    function updatePlatformFee(uint256 newPlatformFeeInPercentFractions) external onlyOwner {
        require(newPlatformFeeInPercentFractions <= 1000, "Fee too large");
        platformFee = newPlatformFeeInPercentFractions;
    }
    
    /**
     * @dev Toggle whether creating new fundraisers is enabled. Existing fundraisers will go on regardless.
     */
    function toggleEnabled() external onlyOwner {
        isCreateEnabled = !isCreateEnabled;
    }

    // ======= Fundraiser config =======

    /**
     * @dev Returns whether a token has been whitelisted for a fundraiser
     */
    function isTokenWhitelistedForFundraiser(address token, uint256 index) public view returns (bool) {
        return tokenAndIndexToGoal[token][index] > 0;
    }

    /**
     * @dev Create a fundraiser
     */
    function createFundraiser(uint40 targetTimestamp, uint256 targetAmount, uint256 minContribution, string calldata name, string calldata description, address[] calldata tokenAddresses, uint256[] calldata tokenGoals) external {
        require(isCreateEnabled, "Creating fundraisers is disabled");
        require(targetTimestamp > block.timestamp, "Expiration must be in the future");
        require(targetTimestamp < block.timestamp + maxFundraiserDuration, "Expiration too late");
        require(targetAmount > 0, "Amount must be non-zero");
        require(minContribution <= targetAmount, "Minimum contribution must be lower than target amount");
        require(tokenAddresses.length == tokenGoals.length && tokenAddresses.length < 256, "Wrong lengths");

        emit Create(msg.sender, fundraisers.length, targetTimestamp, targetAmount, minContribution, name, description);
        fundraisers.push(FundraiserDetails(targetAmount, minContribution, 0, msg.sender, targetTimestamp, uint8(tokenAddresses.length), false, false));

        uint256 index = fundraisers.length - 1;
        for (uint256 i=0; i<tokenAddresses.length; i++) {
            require(tokenGoals[i] > 0, "Goal can't be 0");
            emit WhitelistToken(index, tokenAddresses[i], tokenGoals[i], ERC20(tokenAddresses[i]).symbol(), ERC20(tokenAddresses[i]).decimals());
            tokenAndIndexToGoal[tokenAddresses[i]][index] = tokenGoals[i];
        }
    }

    /**
     * @dev Kill fundraiser
     */
    function killFundraiser(uint256 index) external {
        require(msg.sender == fundraisers[index].admin || msg.sender == owner(), "Not authorized");
        require(!fundraisers[index].killed, "Fundraiser killed");

        emit Killed(index);
        fundraisers[index].killed = true;
    }

    // ======= Funding =======

    /**
     * @dev Fund fundraiser
     */
    function fundFundraiser(uint256 index) external payable {
        require(block.timestamp < fundraisers[index].targetTimestamp && !fundraisers[index].killed, "Fundraiser is closed");
        require(msg.value >= fundraisers[index].minContribution && msg.value > 0, "Amount too low");

        fundraisers[index].currentAmount += msg.value;
        addressAndIndexToAmountFunded[msg.sender][index] += msg.value;
        emit Donate(msg.sender, index, msg.value);
    }

    /**
     * @dev Fund fundraiser with whitelisted token
     */
    function fundFundraiserWithToken(uint256 index, uint256 amount, address token) external {
        require(block.timestamp < fundraisers[index].targetTimestamp && !fundraisers[index].killed, "Fundraiser is closed");
        require(isTokenWhitelistedForFundraiser(token, index), "Token not whitelisted");

        addressAndIndexToTokensFunded[msg.sender][index][token] += amount;
        tokenAndIndexToValue[token][index] += amount;
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit DonateToken(msg.sender, index, amount, token);
    }

    // ======= Funds collection =======

    /**
     * @dev Returns fundraiser's percentage to goal, including ether goal and all tokens
     */
    function getCombinedPercentage(uint256 index, address[] calldata tokenAddresses) public view returns (uint256) {
        require(tokenAddresses.length == fundraisers[index].noWhitelisted, "Invalid tokens");

        uint256 percentage;
        percentage += fundraisers[index].currentAmount * COMBINED_PERCENTAGE_PRECISION / fundraisers[index].targetAmount;

        for (uint256 i=0; i<tokenAddresses.length; i++) {
            require(isTokenWhitelistedForFundraiser(tokenAddresses[i], index), "Token not whitelisted");
            percentage += tokenAndIndexToValue[tokenAddresses[i]][index] * COMBINED_PERCENTAGE_PRECISION / tokenAndIndexToGoal[tokenAddresses[i]][index];
        }

        return percentage * 100 / COMBINED_PERCENTAGE_PRECISION;
    }

    /**
     * @dev Returns fee for fundraiser - either platform fee, or platform fee + holding fee if funds have not been collected after freeHoldingPeriod
     */
    function getFeeForFundraiser(uint256 index) public view returns (uint256) {
        if (block.timestamp > fundraisers[index].targetTimestamp && block.timestamp - fundraisers[index].targetTimestamp >= freeHoldingPeriod) {
            return platformFee + holdingFee;
        } else {
            return platformFee;
        }
    }

    /**
     * @dev Collect funds from a successful fundraiser
     */
    function collectFunds(uint256 index, address[] calldata tokenAddresses) external {
        require(msg.sender == fundraisers[index].admin, "Not owner of fundraiser");
        require(block.timestamp >= fundraisers[index].targetTimestamp, "Fundraiser still in progress");
        require(getCombinedPercentage(index, tokenAddresses) >= 100, "Fundraiser could not raise enough");
        require(!fundraisers[index].collected, "Already collected");

        fundraisers[index].collected = true;
        emit Collect(index);

        uint256 fee = getFeeForFundraiser(index);
        uint256 ownerAmount = fundraisers[index].currentAmount * fee / 10000;
        payable(owner()).transfer(ownerAmount);
        payable(fundraisers[index].admin).transfer(fundraisers[index].currentAmount - ownerAmount);
    }

    /**
     * @dev Collect tokens from a successful fundraiser
     */
    function collectTokens(uint256 index, address token, address[] calldata tokenAddresses) external {
        require(msg.sender == fundraisers[index].admin, "Not owner of fundraiser");
        require(block.timestamp >= fundraisers[index].targetTimestamp, "Fundraiser still in progress");
        require(getCombinedPercentage(index, tokenAddresses) >= 100, "Fundraiser could not raise enough");
        require(isTokenWhitelistedForFundraiser(token, index), "Token not whitelisted");
        require(!isTokenCollectedForFundraiser[token][index], "Already collected");

        isTokenCollectedForFundraiser[token][index] = true;
        emit CollectToken(index, token);

        uint256 fee = getFeeForFundraiser(index);
        uint256 ownerAmount = tokenAndIndexToValue[token][index] * fee / 10000;
        IERC20(token).transfer(owner(), ownerAmount);
        IERC20(token).transfer(msg.sender, tokenAndIndexToValue[token][index] - ownerAmount);
    }

    /**
     * @dev Refund contributors for a failed fundraiser
     */
    function refundFunds(address[] calldata contributors, uint256 index, address[] calldata tokenAddresses) external {
        if (block.timestamp >= fundraisers[index].targetTimestamp) {
            require(getCombinedPercentage(index, tokenAddresses) < 100, "Fundraiser did not fail");
        } else {
            require(fundraisers[index].killed, "Fundraiser still in progress and not killed");
        }

        uint256 totalOwnerAmount = 0;
        uint256 fee = getFeeForFundraiser(index);

        for (uint256 i=0; i<contributors.length; i++) {
            uint256 amount = addressAndIndexToAmountFunded[contributors[i]][index];
            if(amount > 0) {
                addressAndIndexToAmountFunded[contributors[i]][index] = 0;

                uint256 ownerAmount = amount * fee / 10000;
                totalOwnerAmount += ownerAmount;
                payable(contributors[i]).transfer(amount - ownerAmount);
                emit Refund(contributors[i], index);
            }
        }

        payable(owner()).transfer(totalOwnerAmount);
    }

    /**
     * @dev Refund token to contributors for a failed fundraiser
     */
    function refundFundsToken(address[] calldata contributors, uint256 index, address tokenAddress, address[] calldata tokenAddresses) external {
        require(isTokenWhitelistedForFundraiser(tokenAddress, index), "Token not whitelisted");

        if (block.timestamp >= fundraisers[index].targetTimestamp) {
            require(getCombinedPercentage(index, tokenAddresses) < 100, "Fundraiser did not fail");
        } else {
            require(fundraisers[index].killed, "Fundraiser still in progress and not killed");
        }

        uint256 totalOwnerAmount = 0;
        uint256 fee = getFeeForFundraiser(index);

        for (uint256 i=0; i<contributors.length; i++) {
            uint256 amount = addressAndIndexToTokensFunded[contributors[i]][index][tokenAddress];
            if(amount > 0) {
                addressAndIndexToTokensFunded[contributors[i]][index][tokenAddress] = 0;

                uint256 ownerAmount = amount * fee / 10000;
                totalOwnerAmount += ownerAmount;
                IERC20(tokenAddress).transfer(contributors[i], amount - ownerAmount);
                emit RefundToken(contributors[i], index, tokenAddress);
            }
        }

        IERC20(tokenAddress).transfer(owner(), totalOwnerAmount);
    }
}
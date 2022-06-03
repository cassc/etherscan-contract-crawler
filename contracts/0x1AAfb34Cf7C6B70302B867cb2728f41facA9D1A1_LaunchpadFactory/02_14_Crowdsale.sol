// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../library/TransferHelper.sol";
import "../Interface/IERC20.sol";
import "../library/Ownable.sol";
import "../Metadata.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Crowdsale is ReentrancyGuard, Ownable, Metadata {
    using SafeMath for uint256;

    ///@notice TokenAddress available for purchase in this Crowdsale
    IERC20 public token;

    uint256 public tokenRemainingForSale;

    mapping(address => bool) public validInputToken;

    //@notice the amount of token investor will recieve against 1 inputToken
    mapping(address => uint256) public inputTokenRate;

    IERC20[] private inputToken;

    /// @notice start of vesting period as a timestamp
    uint256 public vestingStart;

    /// @notice start of crowdsale as a timestamp
    uint256 public crowdsaleStartTime;

    /// @notice end of crowdsale as a timestamp
    uint256 public crowdsaleEndTime;

    /// @notice end of vesting period as a timestamp
    uint256 public vestingEnd;

    /// @notice Number of Tokens Allocated for crowdsale
    uint256 public crowdsaleTokenAllocated;

    /// @notice cliff duration in seconds
    uint256 public cliffDuration;

    uint256 public maxUserAllocation;

    /// @notice amount vested for a investor.
    mapping(address => uint256) public vestedAmount;

    /// @notice cumulative total of tokens drawn down (and transferred from the deposit account) per investor
    mapping(address => uint256) public totalDrawn;

    /// @notice last drawn down time (seconds) per investor
    mapping(address => uint256) public lastDrawnAt;

    /// @notice whitelisted address those can participate in crowdsale
    mapping(address => bool) public whitelistedAddress;

    bool public whitelistingEnabled;

    bool public initialized;

    /**
     * Event for Tokens purchase logging
     * @param investor who invested & got the tokens
     * @param investedAmount of inputToken paid for purchase
     * @param tokenPurchased amount
     * @param inputToken address used to invest
     * @param tokenRemaining amount of token still remaining for sale in crowdsale
     */
    event TokenPurchase(
        address indexed investor,
        uint256 investedAmount,
        uint256 indexed tokenPurchased,
        IERC20 indexed inputToken,
        uint256 tokenRemaining
    );

    /// @notice event emitted when a successful drawn down of vesting tokens is made
    event DrawDown(
        address indexed _investor,
        uint256 _amount,
        uint256 indexed drawnTime
    );

    /// @notice event emitted when crowdsale is ended manually
    event CrowdsaleEndedManually(uint256 indexed crowdsaleEndedManuallyAt);

    /// @notice event emitted when the crowdsale raised funds are withdrawn by the owner
    event FundsWithdrawn(
        address indexed beneficiary,
        IERC20 indexed _token,
        uint256 amount
    );

    /// @notice event emitted when the owner whitelist a user
    event Whitelisted(address[] user);

    /// @notice event emitted when the owner updates max token allocation per user
    event MaxAllocationUpdated(uint256 indexed newAllocation);

    event URLUpdated(string _tokenUrl);

    event TokenRateUpdated(address inputToken, uint256 rate);

    event WhitelistingEnabled();

    constructor() {
        initialized = true;
    }

    /**
     * @notice Initializes the Crowdsale contract. This is called only once upon Crowdsale creation.
     */
    function init(bytes memory _encodedData) external {
        require(initialized == false, "Contract already initialized");
        IERC20[] memory inputTokens;
        bytes memory _crowdsaleTimings;
        bytes memory _whitelist;
        uint256[] memory _rate;
        string memory tokenURL;
        (
            token,
            crowdsaleTokenAllocated,
            inputTokens,
            _rate,
            _crowdsaleTimings
        ) = abi.decode(
            _encodedData,
            (IERC20, uint256, IERC20[], uint256[], bytes)
        );

        (, , , , , _whitelist, owner, tokenURL) = abi.decode(
            _encodedData,
            (
                IERC20,
                uint256,
                IERC20[],
                uint256[],
                bytes,
                bytes,
                address,
                string
            )
        );

        TransferHelper.safeTransferFrom(
            address(token),
            msg.sender,
            address(this),
            crowdsaleTokenAllocated
        );

        updateMeta(address(token), address(0), tokenURL);
        for (uint256 i = 0; i < inputTokens.length; i++) {
            inputToken.push(inputTokens[i]);
            validInputToken[address(inputTokens[i])] = true;
            inputTokenRate[address(inputTokens[i])] = _rate[i];
            updateMeta(address(inputTokens[i]), address(0), "");
        }
        (
            crowdsaleStartTime,
            crowdsaleEndTime,
            vestingStart,
            vestingEnd,
            cliffDuration
        ) = abi.decode(
            _crowdsaleTimings,
            (uint128, uint128, uint128, uint128, uint128)
        );

        tokenRemainingForSale = crowdsaleTokenAllocated;
        address[] memory _whitelistedAddress;
        (whitelistingEnabled, _whitelistedAddress) = abi.decode(
            _whitelist,
            (bool, address[])
        );
        if (_whitelistedAddress.length > 0 && whitelistingEnabled) {
            whitelistUsers(_whitelistedAddress);
        }

        initialized = true;
    }

    modifier isCrowdsaleOver() {
        require(
            _getNow() >= crowdsaleEndTime && crowdsaleEndTime != 0,
            "Crowdsale Not Ended Yet"
        );
        _;
    }

    function updateTokenURL(address tokenAddress, string memory _url)
        external
        onlyOwner
    {
        updateMetaURL(tokenAddress, _url);
        emit URLUpdated(_url);
    }

    function updateInputTokenRate(address _inputToken, uint256 _rate)
        external
        onlyOwner
    {
        require(
            _getNow() < crowdsaleStartTime,
            "Cannot update token rate after crowdsale is started"
        );

        inputTokenRate[_inputToken] = _rate;

        emit TokenRateUpdated(_inputToken, _rate);
    }

    function purchaseToken(IERC20 _inputToken, uint256 _inputTokenAmount)
        external
    {
        if (whitelistingEnabled) {
            require(whitelistedAddress[msg.sender], "User is not whitelisted");
        }
        require(_getNow() >= crowdsaleStartTime, "Crowdsale isnt started yet");
        require(
            validInputToken[address(_inputToken)],
            "Unsupported Input token"
        );
        if (crowdsaleEndTime != 0) {
            require(_getNow() < crowdsaleEndTime, "Crowdsale Ended");
        }

        uint8 inputTokenDecimals = _inputToken.decimals();
        uint256 tokenPurchased = inputTokenDecimals >= 18
            ? _inputTokenAmount.mul(inputTokenRate[address(_inputToken)]).mul(
                10**(inputTokenDecimals - 18)
            )
            : _inputTokenAmount.mul(inputTokenRate[address(_inputToken)]).mul(
                10**(18 - inputTokenDecimals)
            );

        uint8 tokenDecimal = token.decimals();
        tokenPurchased = tokenDecimal >= 36
            ? tokenPurchased.mul(10**(tokenDecimal - 36))
            : tokenPurchased.div(10**(36 - tokenDecimal));

        if (maxUserAllocation != 0)
            require(
                vestedAmount[msg.sender].add(tokenPurchased) <=
                    maxUserAllocation,
                "User Exceeds personal hardcap"
            );

        require(
            tokenPurchased <= tokenRemainingForSale,
            "Exceeding purchase amount"
        );

        TransferHelper.safeTransferFrom(
            address(_inputToken),
            msg.sender,
            address(this),
            _inputTokenAmount
        );

        tokenRemainingForSale = tokenRemainingForSale.sub(tokenPurchased);
        _updateVestingSchedule(msg.sender, tokenPurchased);

        emit TokenPurchase(
            msg.sender,
            _inputTokenAmount,
            tokenPurchased,
            _inputToken,
            tokenRemainingForSale
        );
    }

    function _updateVestingSchedule(address _investor, uint256 _amount)
        internal
    {
        require(_investor != address(0), "Beneficiary cannot be empty");
        require(_amount > 0, "Amount cannot be empty");

        vestedAmount[_investor] = vestedAmount[_investor].add(_amount);
    }

    /**
     * @notice Vesting schedule and associated data for an investor
     * @return _amount
     * @return _totalDrawn
     * @return _lastDrawnAt
     * @return _remainingBalance
     * @return _availableForDrawDown
     */
    function vestingScheduleForBeneficiary(address _investor)
        external
        view
        returns (
            uint256 _amount,
            uint256 _totalDrawn,
            uint256 _lastDrawnAt,
            uint256 _remainingBalance,
            uint256 _availableForDrawDown
        )
    {
        return (
            vestedAmount[_investor],
            totalDrawn[_investor],
            lastDrawnAt[_investor],
            vestedAmount[_investor].sub(totalDrawn[_investor]),
            _availableDrawDownAmount(_investor)
        );
    }

    /**
     * @notice Draw down amount currently available (based on the block timestamp)
     * @param _investor beneficiary of the vested tokens
     * @return _amount tokens due from vesting schedule
     */
    function availableDrawDownAmount(address _investor)
        external
        view
        returns (uint256 _amount)
    {
        return _availableDrawDownAmount(_investor);
    }

    function _availableDrawDownAmount(address _investor)
        internal
        view
        returns (uint256 _amount)
    {
        // Cliff Period
        if (_getNow() <= vestingStart.add(cliffDuration) || vestingStart == 0) {
            // the cliff period has not ended, no tokens to draw down
            return 0;
        }

        // Schedule complete
        if (_getNow() > vestingEnd) {
            return vestedAmount[_investor].sub(totalDrawn[_investor]);
        }

        // Schedule is active

        // Work out when the last invocation was
        uint256 timeLastDrawnOrStart = lastDrawnAt[_investor] == 0
            ? vestingStart
            : lastDrawnAt[_investor];

        // Find out how much time has past since last invocation
        uint256 timePassedSinceLastInvocation = _getNow().sub(
            timeLastDrawnOrStart
        );

        // Work out how many due tokens - time passed * rate per second
        uint256 drawDownRate = (vestedAmount[_investor].mul(1e18)).div(
            vestingEnd.sub(vestingStart)
        );
        uint256 amount = (timePassedSinceLastInvocation.mul(drawDownRate)).div(
            1e18
        );

        return amount;
    }

    /**
     * @notice Draws down any vested tokens due
     * @dev Must be called directly by the investor assigned the tokens in the schedule
     */
    function drawDown() external isCrowdsaleOver nonReentrant {
        _drawDown(msg.sender);
    }

    function _drawDown(address _investor) internal {
        require(
            vestedAmount[_investor] > 0,
            "There is no schedule currently in flight"
        );

        uint256 amount = _availableDrawDownAmount(_investor);
        require(amount > 0, "No allowance left to withdraw");

        // Update last drawn to now
        lastDrawnAt[_investor] = _getNow();

        // Increase total drawn amount
        totalDrawn[_investor] = totalDrawn[_investor].add(amount);

        // Safety measure - this should never trigger
        require(
            totalDrawn[_investor] <= vestedAmount[_investor],
            "Safety Mechanism - Drawn exceeded Amount Vested"
        );

        // Issue tokens to investor
        TransferHelper.safeTransfer(address(token), _investor, amount);

        emit DrawDown(_investor, amount, _getNow());
    }

    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }

    function getContractTokenBalance(IERC20 _token)
        public
        view
        returns (uint256)
    {
        return _token.balanceOf(address(this));
    }

    /**
     * @notice Balance remaining in vesting schedule
     * @param _investor beneficiary of the vested tokens
     * @return _remainingBalance tokens still due (and currently locked) from vesting schedule
     */
    function remainingBalance(address _investor)
        external
        view
        returns (uint256)
    {
        return vestedAmount[_investor].sub(totalDrawn[_investor]);
    }

    function endCrowdsale(
        uint256 _vestingStartTime,
        uint256 _vestingEndTime,
        uint256 _cliffDurationInSecs
    ) external onlyOwner {
        require(
            crowdsaleEndTime == 0,
            "Crowdsale would end automatically after endTime"
        );
        crowdsaleEndTime = _getNow();
        require(
            _vestingStartTime >= crowdsaleEndTime,
            "Start time should >= Crowdsale EndTime"
        );
        require(
            _vestingEndTime > _vestingStartTime.add(_cliffDurationInSecs),
            "End Time should after the cliffPeriod"
        );

        vestingStart = _vestingStartTime;
        vestingEnd = _vestingEndTime;
        cliffDuration = _cliffDurationInSecs;
        if (tokenRemainingForSale != 0) {
            withdrawFunds(token, tokenRemainingForSale); //when crowdsaleEnds withdraw unsold tokens to the owner
        }
        emit CrowdsaleEndedManually(crowdsaleEndTime);
    }

    function withdrawFunds(IERC20 _token, uint256 amount)
        public
        isCrowdsaleOver
        onlyOwner
    {
        require(
            getContractTokenBalance(_token) >= amount,
            "the contract doesnt have tokens"
        );

        TransferHelper.safeTransfer(address(_token), msg.sender, amount);

        emit FundsWithdrawn(msg.sender, _token, amount);
    }

    /**
     * @dev Enable Whitelisting such that only particular user can participate in crowdsale
     * Can only be called by the current owner.
     */
    function enableWhitelisting() external onlyOwner {
        whitelistingEnabled = true;
        emit WhitelistingEnabled();
    }

    /**
     * @dev Whitelist user address list, such that user can participate in crowdsale
     * Can only be called by the current owner.
     */
    function whitelistUsers(address[] memory users) public onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            require(whitelistingEnabled, "Whitelisting is not enabled");
            whitelistedAddress[users[i]] = true;
        }
        emit Whitelisted(users);
    }

    /**
     * @dev Update the token allocation a user can purchase
     * Can only be called by the current owner.
     */
    function updateMaxUserAllocation(uint256 _maxUserAllocation)
        external
        onlyOwner
    {
        maxUserAllocation = _maxUserAllocation;
        emit MaxAllocationUpdated(_maxUserAllocation);
    }

    function getValidInputTokens() external view returns (IERC20[] memory) {
        return inputToken;
    }
}
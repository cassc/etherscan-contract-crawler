// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

import "./utils/WhiteList.sol";

/**
 * @title IvstSale
 */
contract IvstSale is ReentrancyGuard, Whitelist {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Number of pools
    uint8 public constant NUMBER_POOLS = 8;

    // It checks if token is accepted for payment
    mapping(address => bool) public isPaymentToken;
    address[] public allPaymentTokens;

    // It maps the payment token address to price feed address
    mapping(address => address) public priceFeed;
    address public ethPriceFeed;

    // It maps the payment token address to decimal
    mapping(address => uint8) public paymentTokenDecimal;

    // It checks if token is stable coin
    mapping(address => bool) public isStableToken;
    address[] public allStableTokens;

    // The offering token
    IERC20 public offeringToken;

    // Total tokens distributed across the pools
    uint256 public totalTokensOffered;

    // Array of PoolCharacteristics of size NUMBER_POOLS
    PoolCharacteristics[NUMBER_POOLS] private _poolInformation;

    // It maps the address to pool id to UserInfo
    mapping(address => mapping(uint8 => UserInfo)) private _userInfo;

    // Struct that contains each pool characteristics
    struct PoolCharacteristics {
        uint256 startTime; // The block timestamp when pool starts
        uint256 endTime; // The block timestamp when pool ends
        uint256 raisingAmountPool; // amount of tokens raised for the pool (in USD, decimal is 18)
        uint256 offeringAmountPool; // amount of tokens offered for the pool (in offeringTokens)
        uint256 limitPerUserInLP; // limit of tokens per user (if 0, it is ignored)
        uint256 totalAmountPool; // total amount pool deposited (in USD, decimal is 18)
        uint256 vestingPercentage; // 60 means 0.6, rest part such as 100-60=40 means 0.4 is claimingPercentage
        uint256 vestingCliff; // Vesting cliff
        uint256 vestingDuration; // Vesting duration
        uint256 vestingSlicePeriodSeconds; // Vesting slice period seconds
    }

    // Struct that contains each user information for both pools
    struct UserInfo {
        uint256 amountPool; // How many tokens the user has provided for pool
        bool claimedPool; // Whether the user has claimed (default: false) for pool
    }

    // vesting startTime, everyone will be started at same timestamp
    uint256 public vestingStartTime;

    // A flag for vesting is being revoked
    bool public vestingRevoked;

    // Struct that contains vesting schedule
    struct VestingSchedule {
        bool isVestingInitialized;
        // beneficiary of tokens after they are released
        address beneficiary;
        // pool id
        uint8 pid;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens has been released
        uint256 released;
    }

    bytes32[] private vestingSchedulesIds;
    mapping(bytes32 => VestingSchedule) private vestingSchedules;
    uint256 private vestingSchedulesTotalAmount;
    mapping(address => uint256) private holdersVestingCount;

    mapping(uint8 => bool) public isWhitelistSale;

    bool public harvestAllowed;

    // Admin withdraw events
    event AdminWithdraw(uint256 amountOfferingToken, uint256 ethAmount, address[] tokens, uint256[] amounts);

    // Admin recovers token
    event AdminTokenRecovery(address tokenAddress, uint256 amountTokens);

    // Deposit event
    event Deposit(address indexed user, address token, uint256 amount, uint256 usdAmount, uint8 indexed pid);

    // Harvest event
    event Harvest(address indexed user, uint256 offeringAmount, uint8 indexed pid);

    // Create VestingSchedule event
    event CreateVestingSchedule(address indexed user, uint256 offeringAmount, uint8 indexed pid);

    // Event when parameters are set for one of the pools
    event PoolParametersSet(uint256 offeringAmountPool, uint256 raisingAmountPool, uint8 pid);

    // Event when released new amount
    event Released(address indexed beneficiary, uint256 amount);

    // Event when revoked
    event Revoked();

    // Event when payment token added
    event PaymentTokenAdded(address token, address feed, uint8 decimal);

    // Event when payment token revoked
    event PaymentTokenRevoked(address token);

    // Event when stable token added
    event StableTokenAdded(address token, uint8 decimal);

    // Event when stable token revoked
    event StableTokenRevoked(address token);

    // Event when whitelist sale status flipped
    event WhitelistSaleFlipped(uint8 pid, bool current);

    // Event when harvest enabled status flipped
    event HarvestAllowedFlipped(bool current);

    // Event when offering token is set
    event OfferingTokenSet(address tokenAddress);

    // Modifier to prevent contracts to participate
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    // Modifier to check payment method
    modifier checkPayment(address token) {
        if (token != address(0)) {
            require(
                (
                    isStableToken[token] ||
                    (isPaymentToken[token] && priceFeed[token] != address(0))
                ) &&
                paymentTokenDecimal[token] > 0,
                "invalid token"
            );
        } else {
            require(ethPriceFeed != address(0), "price feed not set");
        }
        _;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    /**
     * @notice Constructor
     */
    constructor(address _ethPriceFeed) public {
        (, int256 price, , , ) = AggregatorV3Interface(_ethPriceFeed).latestRoundData();
        require(price > 0, "invalid price feed");

        ethPriceFeed = _ethPriceFeed;
    }

    /**
     * @notice It allows users to deposit LP tokens to pool
     * @param _pid: pool id
     * @param _token: payment token
     * @param _amount: the number of payment token being deposited
     * @param _minUsdAmount: minimum USD amount that must be converted from deposit token not to revert
     * @param _deadline: unix timestamp after which the transaction will revert
     */
    function depositPool(uint8 _pid, address _token, uint256 _amount, uint256 _minUsdAmount, uint256 _deadline) external payable nonReentrant notContract ensure(_deadline) {
        // Checks whether the pool id is valid
        require(_pid < NUMBER_POOLS, "Deposit: Non valid pool id");

        // Checks that pool was set
        require(
            _poolInformation[_pid].offeringAmountPool > 0 && _poolInformation[_pid].raisingAmountPool > 0,
            "Deposit: Pool not set"
        );

        // Checks whether the block timestamp is not too early
        require(block.timestamp > _poolInformation[_pid].startTime, "Deposit: Too early");

        // Checks whether the block timestamp is not too late
        require(block.timestamp < _poolInformation[_pid].endTime, "Deposit: Too late");

        if(_token == address(0)) {
            _amount = msg.value;
        }
        // Checks that the amount deposited is not inferior to 0
        require(_amount > 0, "Deposit: Amount must be > 0");

        require(
            !isWhitelistSale[_pid] || _isQualifiedWhitelist(msg.sender),
            "Deposit: Must be whitelisted"
        );

        if (_token != address(0)) {
            // Transfers funds to this contract
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        uint256 usdAmount = computeUSDAmount(_token, _amount);
        require(usdAmount >= _minUsdAmount, 'Deposit: Insufficient USD amount');
        // Update the user status
        _userInfo[msg.sender][_pid].amountPool = _userInfo[msg.sender][_pid].amountPool.add(usdAmount);

        // Check if the pool has a limit per user
        if (_poolInformation[_pid].limitPerUserInLP > 0) {
            // Checks whether the limit has been reached
            require(
                _userInfo[msg.sender][_pid].amountPool <= _poolInformation[_pid].limitPerUserInLP,
                "Deposit: New amount above user limit"
            );
        }

        // Updates the totalAmount for pool
        _poolInformation[_pid].totalAmountPool = _poolInformation[_pid].totalAmountPool.add(usdAmount);
        require(
            _poolInformation[_pid].totalAmountPool <= _poolInformation[_pid].raisingAmountPool,
            "Deposit: Exceed pool raising amount"
        );

        emit Deposit(msg.sender, _token, _amount, usdAmount, _pid);
    }

    /**
     * @notice It allows users to harvest from pool
     * @param _pid: pool id
     */
    function harvestPool(uint8 _pid) external nonReentrant notContract {
        require(harvestAllowed, "Harvest: Not allowed");
        // Checks whether it is too early to harvest
        require(block.timestamp > _poolInformation[_pid].endTime, "Harvest: Too early");

        // Checks whether pool id is valid
        require(_pid < NUMBER_POOLS, "Harvest: Non valid pool id");

        // Checks whether the user has participated
        require(_userInfo[msg.sender][_pid].amountPool > 0, "Harvest: Did not participate");

        // Checks whether the user has already harvested
        require(!_userInfo[msg.sender][_pid].claimedPool, "Harvest: Already done");

        // Updates the harvest status
        _userInfo[msg.sender][_pid].claimedPool = true;

        // Updates the vesting startTime
        if (vestingStartTime == 0) {
            vestingStartTime = block.timestamp;
        }

        uint256 offeringTokenAmount = _calculateOfferingAmountPool(msg.sender, _pid);

        // Transfer these tokens back to the user if quantity > 0
        if (offeringTokenAmount > 0) {
            if (100 - _poolInformation[_pid].vestingPercentage > 0) {
                uint256 amount = offeringTokenAmount.mul(100 - _poolInformation[_pid].vestingPercentage).div(100);

                // Transfer the tokens at TGE
                offeringToken.safeTransfer(msg.sender, amount);

                emit Harvest(msg.sender, amount, _pid);
            }
            // If this pool is Vesting modal, create a VestingSchedule for each user
            if (_poolInformation[_pid].vestingPercentage > 0) {
                uint256 amount = offeringTokenAmount.mul(_poolInformation[_pid].vestingPercentage).div(100);

                // Create VestingSchedule object
                _createVestingSchedule(msg.sender, _pid, amount);

                emit CreateVestingSchedule(msg.sender, amount, _pid);
            }
        }
    }

    /**
     * @notice It allows the admin to withdraw funds
     * @param _tokens: payment token addresses
     * @param _offerAmount: the number of offering amount to withdraw
     * @dev This function is only callable by admin.
     */
    function finalWithdraw(address[] calldata _tokens, uint256 _offerAmount) external onlyOwner {
        if (_offerAmount > 0) {
            offeringToken.safeTransfer(msg.sender, _offerAmount);
        }

        uint256 ethBalance = address(this).balance;
        payable(msg.sender).transfer(ethBalance);

        uint256[] memory _amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _amounts[i] = IERC20(_tokens[i]).balanceOf(address(this));
            if (_amounts[i] > 0) {
                IERC20(_tokens[i]).safeTransfer(msg.sender, _amounts[i]);
            }
        }

        emit AdminWithdraw(_offerAmount, ethBalance, _tokens, _amounts);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw (18 decimals)
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(!isPaymentToken[_tokenAddress] && !isStableToken[_tokenAddress], "Recover: Cannot be payment token");
        require(_tokenAddress != address(offeringToken), "Recover: Cannot be offering token");

        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice It allows the admin to set offering token before sale start
     * @param _tokenAddress: the address of offering token
     * @dev This function is only callable by admin.
     */
    function setOfferingToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "OfferingToken: Zero address");

        offeringToken = IERC20(_tokenAddress);

        emit OfferingTokenSet(_tokenAddress);
    }

    /**
     * @notice It sets parameters for pool
     * @param _startTime: pool start time
     * @param _endTime: pool end time
     * @param _offeringAmountPool: offering amount (in tokens)
     * @param _raisingAmountPool: raising amount (in USD)
     * @param _limitPerUserInLP: limit per user (in USD)
     * @param _pid: pool id
     * @param _vestingPercentage: percentage for vesting remain tokens after end IFO
     * @param _vestingCliff: cliff of vesting
     * @param _vestingDuration: duration of vesting
     * @param _vestingSlicePeriodSeconds: slice period seconds of vesting
     * @dev This function is only callable by admin.
     */
    function setPool(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _offeringAmountPool,
        uint256 _raisingAmountPool,
        uint256 _limitPerUserInLP,
        uint8 _pid,
        uint256 _vestingPercentage,
        uint256 _vestingCliff,
        uint256 _vestingDuration,
        uint256 _vestingSlicePeriodSeconds
    ) external onlyOwner {
        require(_pid < NUMBER_POOLS, "Operations: Pool does not exist");
        require(
            _vestingPercentage >= 0 && _vestingPercentage <= 100,
            "Operations: vesting percentage should exceeds 0 and interior 100"
        );
        require(_vestingDuration > 0, "duration must exceeds 0");
        require(_vestingSlicePeriodSeconds >= 1, "slicePeriodSeconds must be exceeds 1");
        require(_vestingSlicePeriodSeconds <= _vestingDuration, "slicePeriodSeconds must be interior duration");

        _poolInformation[_pid].startTime = _startTime;
        _poolInformation[_pid].endTime = _endTime;
        _poolInformation[_pid].offeringAmountPool = _offeringAmountPool;
        _poolInformation[_pid].raisingAmountPool = _raisingAmountPool;
        _poolInformation[_pid].limitPerUserInLP = _limitPerUserInLP;
        _poolInformation[_pid].vestingPercentage = _vestingPercentage;
        _poolInformation[_pid].vestingCliff = _vestingCliff;
        _poolInformation[_pid].vestingDuration = _vestingDuration;
        _poolInformation[_pid].vestingSlicePeriodSeconds = _vestingSlicePeriodSeconds;

        uint256 tokensDistributedAcrossPools;

        for (uint8 i = 0; i < NUMBER_POOLS; i++) {
            tokensDistributedAcrossPools = tokensDistributedAcrossPools.add(_poolInformation[i].offeringAmountPool);
        }

        // Update totalTokensOffered
        totalTokensOffered = tokensDistributedAcrossPools;

        emit PoolParametersSet(_offeringAmountPool, _raisingAmountPool, _pid);
    }

    /**
     * @notice It returns the pool information
     * @param _pid: pool id
     * @return startTime: pool start time
     * @return endTime: pool end time
     * @return raisingAmountPool: amount of LP tokens raised (in LP tokens)
     * @return offeringAmountPool: amount of tokens offered for the pool (in offeringTokens)
     * @return limitPerUserInLP; // limit of tokens per user (if 0, it is ignored)
     * @return totalAmountPool: total amount pool deposited (in LP tokens)
     */
    function viewPoolInformation(uint256 _pid)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _poolInformation[_pid].startTime,
            _poolInformation[_pid].endTime,
            _poolInformation[_pid].raisingAmountPool,
            _poolInformation[_pid].offeringAmountPool,
            _poolInformation[_pid].limitPerUserInLP,
            _poolInformation[_pid].totalAmountPool
        );
    }

    /**
     * @notice It returns the pool vesting information
     * @param _pid: pool id
     * @return vestingPercentage: the percentage of vesting part, claimingPercentage + vestingPercentage should be 100
     * @return vestingCliff: the cliff of vesting
     * @return vestingDuration: the duration of vesting
     * @return vestingSlicePeriodSeconds: the slice period seconds of vesting
     */
    function viewPoolVestingInformation(uint256 _pid)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _poolInformation[_pid].vestingPercentage,
            _poolInformation[_pid].vestingCliff,
            _poolInformation[_pid].vestingDuration,
            _poolInformation[_pid].vestingSlicePeriodSeconds
        );
    }

    /**
     * @notice External view function to see user allocations for both pools
     * @param _user: user address
     * @param _pids[]: array of pids
     * @return
     */
    function viewUserAllocationPools(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory allocationPools = new uint256[](_pids.length);
        for (uint8 i = 0; i < _pids.length; i++) {
            allocationPools[i] = _getUserAllocationPool(_user, _pids[i]);
        }
        return allocationPools;
    }

    /**
     * @notice External view function to see user information
     * @param _user: user address
     * @param _pids[]: array of pids
     */
    function viewUserInfo(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[] memory, bool[] memory)
    {
        uint256[] memory amountPools = new uint256[](_pids.length);
        bool[] memory statusPools = new bool[](_pids.length);

        for (uint8 i = 0; i < _pids.length; i++) {
            amountPools[i] = _userInfo[_user][_pids[i]].amountPool;
            statusPools[i] = _userInfo[_user][_pids[i]].claimedPool;
        }
        return (amountPools, statusPools);
    }

    /**
     * @notice External view function to see user offering amounts for pools
     * @param _user: user address
     * @param _pids: array of pids
     */
    function viewUserOfferingAmountsForPools(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory amountPools = new uint256[](_pids.length);

        for (uint8 i = 0; i < _pids.length; i++) {
            uint256 userOfferingAmountPool;

            if (_poolInformation[_pids[i]].raisingAmountPool > 0) {
                userOfferingAmountPool = _calculateOfferingAmountPool(_user, _pids[i]);
            }

            amountPools[i] = userOfferingAmountPool;
        }
        return amountPools;
    }

    /**
     * @notice Returns the number of vesting schedules associated to a beneficiary
     * @return The number of vesting schedules
     */
    function getVestingSchedulesCountByBeneficiary(address _beneficiary) external view returns (uint256) {
        return holdersVestingCount[_beneficiary];
    }

    /**
     * @notice Returns the vesting schedule id at the given index
     * @return The vesting schedule id
     */
    function getVestingScheduleIdAtIndex(uint256 _index) external view returns (bytes32) {
        require(_index < getVestingSchedulesCount(), "index out of bounds");
        return vestingSchedulesIds[_index];
    }

    /**
     * @notice Returns the vesting schedule information of a given holder and index
     * @return The vesting schedule object
     */
    function getVestingScheduleByAddressAndIndex(address _holder, uint256 _index)
        external
        view
        returns (VestingSchedule memory)
    {
        return getVestingSchedule(computeVestingScheduleIdForAddressAndIndex(_holder, _index));
    }

    /**
     * @notice Returns the total amount of vesting schedules
     * @return The vesting schedule total amount
     */
    function getVestingSchedulesTotalAmount() external view returns (uint256) {
        return vestingSchedulesTotalAmount;
    }

    /**
     * @notice Release vested amount of offering tokens
     * @param _vestingScheduleId the vesting schedule identifier
     */
    function release(bytes32 _vestingScheduleId) external nonReentrant {
        require(vestingSchedules[_vestingScheduleId].isVestingInitialized == true, "vesting schedule is not exist");

        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingScheduleId];
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        bool isOwner = msg.sender == owner();
        require(isBeneficiary || isOwner, "only the beneficiary and owner can release vested tokens");
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(vestedAmount > 0, "no vested tokens to release");
        vestingSchedule.released = vestingSchedule.released.add(vestedAmount);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(vestedAmount);
        offeringToken.safeTransfer(vestingSchedule.beneficiary, vestedAmount);

        emit Released(vestingSchedule.beneficiary, vestedAmount);
    }

    /**
     * @notice Revokes all the vesting schedules
     */
    function revoke() external onlyOwner {
        require(!vestingRevoked, "vesting is revoked");

        vestingRevoked = true;

        emit Revoked();
    }

    /**
     * @notice Add payment token
     */
    function addPaymentToken(address _token, address _feed, uint8 _decimal) external onlyOwner {
        require(!isPaymentToken[_token], "already added");
        require(_feed != address(0), "invalid feed address");
        require(_decimal > 0, "no zero decimal");

        (, int256 price, , , ) = AggregatorV3Interface(_feed).latestRoundData();
        require(price > 0, "invalid price feed");

        isPaymentToken[_token] = true;
        allPaymentTokens.push(_token);
        priceFeed[_token] = _feed;
        paymentTokenDecimal[_token] = _decimal;

        emit PaymentTokenAdded(_token, _feed, _decimal);
    }

    /**
     * @notice Revoke payment token
     */
    function revokePaymentToken(address _token) external onlyOwner {
        require(isPaymentToken[_token], "not added");

        isPaymentToken[_token] = false;

        uint256 index = 0;
        for (uint256 i = 0; i < allPaymentTokens.length; i++) {
            if (allPaymentTokens[i] == _token) {
                index = i;
                break;
            }
        }
        allPaymentTokens[index] = allPaymentTokens[allPaymentTokens.length - 1];
        allPaymentTokens.pop();

        emit PaymentTokenRevoked(_token);
    }

    /**
     * @notice Add stable token
     */
    function addStableToken(address _token, uint8 _decimal) external onlyOwner {
        require(!isStableToken[_token], "already added");
        require(_decimal > 0, "no zero decimal");

        isStableToken[_token] = true;
        allStableTokens.push(_token);
        paymentTokenDecimal[_token] = _decimal;

        emit StableTokenAdded(_token, _decimal);
    }

    /**
     * @notice Revoke stable token
     */
    function revokeStableToken(address _token) external onlyOwner {
        require(isStableToken[_token], "not added");

        isStableToken[_token] = false;

        uint256 index = 0;
        for (uint256 i = 0; i < allStableTokens.length; i++) {
            if (allStableTokens[i] == _token) {
                index = i;
                break;
            }
        }
        allStableTokens[index] = allStableTokens[allStableTokens.length - 1];
        allStableTokens.pop();

        emit StableTokenRevoked(_token);
    }

    /**
     * @notice Flip whitelist sale status
     */
    function flipWhitelistSaleStatus(uint8 _pid) external onlyOwner {
        isWhitelistSale[_pid] = !isWhitelistSale[_pid];

        emit WhitelistSaleFlipped(_pid, isWhitelistSale[_pid]);
    }

    /**
     * @notice Flip harvestAllowed status
     */
    function flipHarvestAllowedStatus() external onlyOwner {
        harvestAllowed = !harvestAllowed;

        emit HarvestAllowedFlipped(harvestAllowed);
    }

    /**
     * @notice Returns the number of vesting schedules managed by the contract
     * @return The number of vesting count
     */
    function getVestingSchedulesCount() public view returns (uint256) {
        return vestingSchedulesIds.length;
    }

    /**
     * @notice Returns the vested amount of tokens for the given vesting schedule identifier
     * @return The number of vested count
     */
    function computeReleasableAmount(bytes32 _vestingScheduleId) public view returns (uint256) {
        require(vestingSchedules[_vestingScheduleId].isVestingInitialized == true, "vesting schedule is not exist");

        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleId];
        return _computeReleasableAmount(vestingSchedule);
    }

    /**
     * @notice Returns the vesting schedule information of a given identifier
     * @return The vesting schedule object
     */
    function getVestingSchedule(bytes32 _vestingScheduleId) public view returns (VestingSchedule memory) {
        return vestingSchedules[_vestingScheduleId];
    }

    /**
     * @notice Returns the amount of offering token that can be withdrawn by the owner
     * @return The amount of offering token
     */
    function getWithdrawableOfferingTokenAmount() public view returns (uint256) {
        return offeringToken.balanceOf(address(this)).sub(vestingSchedulesTotalAmount);
    }

    /**
     * @notice Computes the next vesting schedule identifier for a given holder address
     * @return The id string
     */
    function computeNextVestingScheduleIdForHolder(address _holder) public view returns (bytes32) {
        return computeVestingScheduleIdForAddressAndIndex(_holder, holdersVestingCount[_holder]);
    }

    /**
     * @notice Computes the next vesting schedule identifier for an address and an index
     * @return The id string
     */
    function computeVestingScheduleIdForAddressAndIndex(address _holder, uint256 _index) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_holder, _index));
    }

    /**
     * @notice Computes the next vesting schedule identifier for an address and an pid
     * @return The id string
     */
    function computeVestingScheduleIdForAddressAndPid(address _holder, uint256 _pid) external view returns (bytes32) {
        require(_pid < NUMBER_POOLS, "ComputeVestingScheduleId: Non valid pool id");
        bytes32 vestingScheduleId = computeVestingScheduleIdForAddressAndIndex(_holder, 0);
        VestingSchedule memory vestingSchedule = vestingSchedules[vestingScheduleId];
        if (vestingSchedule.pid == _pid) {
            return vestingScheduleId;
        } else {
            return computeVestingScheduleIdForAddressAndIndex(_holder, 1);
        }
    }

    /**
     * @notice Get current Time
     */
    function getCurrentTime() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice Computes the releasable amount of tokens for a vesting schedule
     * @return The amount of releasable tokens
     */
    function _computeReleasableAmount(VestingSchedule memory _vestingSchedule) internal view returns (uint256) {
        uint256 currentTime = getCurrentTime();
        if (currentTime < vestingStartTime + _poolInformation[_vestingSchedule.pid].vestingCliff) {
            return 0;
        } else if (
            currentTime >= vestingStartTime.add(_poolInformation[_vestingSchedule.pid].vestingDuration) ||
            vestingRevoked
        ) {
            return _vestingSchedule.amountTotal.sub(_vestingSchedule.released);
        } else {
            uint256 timeFromStart = currentTime.sub(vestingStartTime);
            uint256 secondsPerSlice = _poolInformation[_vestingSchedule.pid].vestingSlicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart.div(secondsPerSlice);
            uint256 vestedSeconds = vestedSlicePeriods.mul(secondsPerSlice);
            uint256 vestedAmount = _vestingSchedule.amountTotal.mul(vestedSeconds).div(
                _poolInformation[_vestingSchedule.pid].vestingDuration
            );
            vestedAmount = vestedAmount.sub(_vestingSchedule.released);
            return vestedAmount;
        }
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _pid the pool id
     * @param _amount total amount of tokens to be released at the end of the vesting
     */
    function _createVestingSchedule(
        address _beneficiary,
        uint8 _pid,
        uint256 _amount
    ) internal {
        require(
            getWithdrawableOfferingTokenAmount() >= _amount,
            "can not create vesting schedule with sufficient tokens"
        );

        bytes32 vestingScheduleId = computeNextVestingScheduleIdForHolder(_beneficiary);
        require(vestingSchedules[vestingScheduleId].beneficiary == address(0), "vestingScheduleId is been created");
        vestingSchedules[vestingScheduleId] = VestingSchedule(true, _beneficiary, _pid, _amount, 0);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.add(_amount);
        vestingSchedulesIds.push(vestingScheduleId);
        holdersVestingCount[_beneficiary]++;
    }

    /**
     * @notice It calculates the offering amount for a user and the number of LP tokens to transfer back.
     * @param _user: user address
     * @param _pid: pool id
     * @return It returns the offering amount
     */
    function _calculateOfferingAmountPool(address _user, uint8 _pid)
        internal
        view
        returns (uint256)
    {
        // _userInfo[_user] / (raisingAmount / offeringAmount)
        uint256 userOfferingAmount = _userInfo[_user][_pid].amountPool.mul(_poolInformation[_pid].offeringAmountPool).div(
            _poolInformation[_pid].raisingAmountPool
        );
        return userOfferingAmount;
    }

    /**
     * @notice It returns the user allocation for pool
     * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @param _user: user address
     * @param _pid: pool id
     * @return It returns the user's share of pool
     */
    function _getUserAllocationPool(address _user, uint8 _pid) internal view returns (uint256) {
        if (_poolInformation[_pid].totalAmountPool > 0) {
            return _userInfo[_user][_pid].amountPool.mul(1e18).div(_poolInformation[_pid].totalAmountPool.mul(1e6));
        } else {
            return 0;
        }
    }

    /**
     * @notice Check if an address is a contract
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function isQualifiedWhitelist(address _user) external view returns (bool) {
        return isWhitelisted(_user);
    }

    function _isQualifiedWhitelist(address _user) internal view returns (bool) {
        return isWhitelisted(_user);
    }

    /**
     * @notice Computes the USD amount from token amount
     * @return USD amount
     */
    function computeUSDAmount(address token, uint256 amount) public view checkPayment(token) returns (uint256) {
        uint256 tokenDecimal = token == address(0) ? 18 : uint256(paymentTokenDecimal[token]);

        if (isStableToken[token]) {
            return amount.mul(10 ** 18).div(10 ** tokenDecimal);    
        }

        address feed = token == address(0) ? ethPriceFeed : priceFeed[token];
        (, int256 price, , , ) = AggregatorV3Interface(feed).latestRoundData();
        require(price > 0, "ChainlinkPriceFeed: invalid price");
        uint256 priceDecimal = uint256(AggregatorV3Interface(feed).decimals());

        return amount.mul(uint256(price)).mul(10 ** 18).div(10 ** (priceDecimal + tokenDecimal));
    }
}
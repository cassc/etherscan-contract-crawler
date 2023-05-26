// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './interfaces/IStakeRegistry.sol';
import './interfaces/ISLARegistry.sol';
import './interfaces/IPeriodRegistry.sol';
import './interfaces/IMessenger.sol';
import './interfaces/IERC20Query.sol';
import './dToken.sol';

/**
 * @title Staking
 * @notice Staking of user and provider pool rewards
 */
contract Staking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Position of staking
    /// @dev OK => Provider Pool (LONG), KO => User Pool (SHORT)
    enum Position {
        OK,
        KO
    }

    /// @dev StakeRegistry contract
    IStakeRegistry private _stakeRegistry;

    /// @dev SLARegistry contract
    IPeriodRegistry internal immutable _periodRegistry;

    /// @dev DSLA token address to burn fees
    address private immutable _dslaTokenAddress;
    /// @dev messenger address
    address public immutable messengerAddress;
    /// @dev current SLA id
    uint128 public immutable slaID;

    /// @dev (tokenAddress=>uint256) total pooled token balance
    mapping(address => uint256) public providersPool;

    /// @dev (userAddress=>uint256) provider staking activity
    mapping(address => uint256) public lastProviderStake;

    /// @dev (tokenAddress=>uint256) user staking
    mapping(address => uint256) public usersPool;

    /// @dev (userAddress=>uint256) user staking activity
    mapping(address => uint256) public lastUserStake;

    ///@dev (tokenAddress=>dTokenAddress) to keep track of dToken for users
    mapping(address => dToken) public duTokenRegistry;

    ///@dev (tokenAddress=>dTokenAddress) to keep track of dToken for provider
    mapping(address => dToken) public dpTokenRegistry;

    /// @dev (slaOwner=>bool)
    mapping(address => bool) public registeredStakers;

    /// @dev number of stakers
    uint256 public stakersNum;

    /// @dev array with the allowed tokens addresses for the current SLA
    address[] public allowedTokens;

    /// @dev corresponds to the burn rate of DSLA tokens, but divided by 1000 i.e burn percentage = burnRate/1000 %
    uint256 public immutable DSLAburnRate;

    /// @dev boolean to declare if contract is whitelisted
    bool public immutable whitelistedContract;

    /// @dev (userAddress=bool) to declare whitelisted addresses
    mapping(address => bool) public whitelist;

    uint64 public immutable leverage;

    /// @dev claiming fees when a user claim tokens, base 10000
    uint16 private constant ownerRewardsRate = 30; // 0.3%, base 10000
    uint16 private constant protocolRewardsRate = 15; // 0.15%, base 10000
    uint16 private constant rewardsCapRate = 2500; // 25%, base 10000

    modifier onlyAllowedToken(address _token) {
        require(isAllowedToken(_token), 'This token is not allowed.');
        _;
    }

    modifier onlyWhitelisted() {
        if (whitelistedContract) {
            require(whitelist[msg.sender], 'not whitelisted');
        }
        _;
    }

    /// @notice An event that emitted when generating provider rewards
    event ProviderRewardGenerated(
        uint256 indexed periodId,
        address indexed tokenAddress,
        uint256 rewardPercentage,
        uint256 rewardPercentagePrecision,
        uint256 rewardAmount
    );

    /// @notice An event that emitted when generating user rewards
    event UserCompensationGenerated(
        uint256 indexed periodId,
        address indexed tokenAddress,
        uint256 userStake,
        uint256 leverage,
        uint256 compensation
    );

    /// @notice An event that emitted when owner adds new dTokens
    event DTokensCreated(
        address indexed tokenAddress,
        address indexed dpTokenAddress,
        string dpTokenName,
        string dpTokenSymbol,
        address indexed duTokenAddress,
        string duTokenName,
        string duTokenSymbol
    );

    /**
     * @notice Constructor
     * @param slaRegistry_ SLARegistry address
     * @param whitelistedContract_ Declare if contract is whitelisted
     * @param slaID_ ID of SLA
     * @param leverage_ Leverage of reward
     * @param contractOwner_ SLA Owner address
     * @param messengerAddress_ Messenger Address
     */
    constructor(
        ISLARegistry slaRegistry_,
        bool whitelistedContract_,
        uint128 slaID_,
        uint64 leverage_,
        address contractOwner_,
        address messengerAddress_
    ) {
        require(contractOwner_ != address(0x0), 'invalid owner address');
        require(messengerAddress_ != address(0x0), 'invalid messenger address');
        _stakeRegistry = IStakeRegistry(slaRegistry_.stakeRegistry());
        _periodRegistry = IPeriodRegistry(slaRegistry_.periodRegistry());
        whitelistedContract = whitelistedContract_;
        (
            uint256 _DSLAburnRate,
            ,
            ,
            ,
            ,
            ,
            ,
            uint64 _maxLeverage,

        ) = _stakeRegistry.getStakingParameters();
        _dslaTokenAddress = _stakeRegistry.DSLATokenAddress();
        DSLAburnRate = _DSLAburnRate;
        whitelist[contractOwner_] = true;
        slaID = slaID_;
        require(
            leverage_ <= _maxLeverage && leverage_ >= 1,
            'incorrect leverage'
        );
        leverage = leverage_;
        messengerAddress = messengerAddress_;
    }

    /**
     * @notice Add multiple addresses to whitelist
     * @dev only owner can call this function
     * @param _userAddresses Addresses to whitelist
     */
    function addUsersToWhitelist(address[] memory _userAddresses)
        public
        onlyOwner
    {
        for (uint256 index = 0; index < _userAddresses.length; index++) {
            if (!whitelist[_userAddresses[index]]) {
                whitelist[_userAddresses[index]] = true;
            }
        }
    }

    /**
     * @notice Remove multiple addresses from whitelist
     * @dev only owner can call this function
     * @param _userAddresses Addresses to remove
     */
    function removeUsersFromWhitelist(address[] calldata _userAddresses)
        external
        onlyOwner
    {
        for (uint256 index = 0; index < _userAddresses.length; index++) {
            if (whitelist[_userAddresses[index]]) {
                whitelist[_userAddresses[index]] = false;
            }
        }
    }

    /**
     * @notice Add token to allowedTokens list
     * @dev It creates dpToken(Provider) and duToken(User) that represents the position.
            only owner can call this function
     * @param _tokenAddress Token address to allow
     */
    function addAllowedTokens(address _tokenAddress) external onlyOwner {
        (, , , , , , uint256 maxTokenLength, , ) = _stakeRegistry
            .getStakingParameters();

        require(
            !isAllowedToken(_tokenAddress),
            'This token has been allowed already.'
        );

        require(
            _stakeRegistry.isAllowedToken(_tokenAddress),
            'This token is not allowed.'
        );
        allowedTokens.push(_tokenAddress);

        require(maxTokenLength >= allowedTokens.length, 'max token length');

        string memory duTokenName = IMessenger(messengerAddress).spName();
        string memory duTokenSymbol = IMessenger(messengerAddress)
            .spSymbolSlaId(slaID);
        string memory dpTokenName = IMessenger(messengerAddress).lpName();
        string memory dpTokenSymbol = IMessenger(messengerAddress)
            .lpSymbolSlaId(slaID);

        uint8 decimals = IERC20Query(_tokenAddress).decimals();

        dToken duToken = dToken(
            _stakeRegistry.createDToken(duTokenName, duTokenSymbol, decimals)
        );

        dToken dpToken = dToken(
            _stakeRegistry.createDToken(dpTokenName, dpTokenSymbol, decimals)
        );

        dpTokenRegistry[_tokenAddress] = dpToken;
        duTokenRegistry[_tokenAddress] = duToken;
        emit DTokensCreated(
            _tokenAddress,
            address(dpToken),
            dpTokenName,
            dpTokenSymbol,
            address(duToken),
            duTokenName,
            duTokenSymbol
        );
    }

    /**
     * @notice Stake allowed assets in User or Provider pools until next period
     * @param _tokenAddress Address of token to stake
     * @param _nextVerifiablePeriod Next verifiable PeriodId
     * @param _amount Amount of tokens to stake
     * @param _position Staking position, OK or KO
     */
    function _stake(
        address _tokenAddress,
        uint256 _nextVerifiablePeriod,
        uint256 _amount,
        Position _position
    ) internal onlyAllowedToken(_tokenAddress) onlyWhitelisted nonReentrant {
        IERC20(_tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        // DSLA-SP proofs of SLA Position
        if (_position == Position.KO) {
            require(
                (usersPool[_tokenAddress] + _amount) * leverage <=
                    providersPool[_tokenAddress],
                'Stake exceeds leveraged cap.'
            );

            dToken duToken = duTokenRegistry[_tokenAddress];
            uint256 p0 = duToken.totalSupply();

            // If there are no minted tokens, then mint them 1:1
            if (p0 == 0) {
                duToken.mint(msg.sender, _amount);
            } else {
                // mint dTokens proportionally
                duToken.mint(
                    msg.sender,
                    (_amount * p0) / usersPool[_tokenAddress]
                );
            }
            usersPool[_tokenAddress] += _amount;
            lastUserStake[msg.sender] = _nextVerifiablePeriod;
        }

        // DSLA-LP proofs of SLA Position
        if (_position == Position.OK) {
            dToken dpToken = dpTokenRegistry[_tokenAddress];
            uint256 p0 = dpToken.totalSupply();

            if (p0 == 0) {
                dpToken.mint(msg.sender, _amount);
            } else {
                // mint dTokens proportionally
                dpToken.mint(
                    msg.sender,
                    (_amount * p0) / providersPool[_tokenAddress]
                );
            }
            providersPool[_tokenAddress] += _amount;
            lastProviderStake[msg.sender] = _nextVerifiablePeriod;
        }

        if (!registeredStakers[msg.sender]) {
            registeredStakers[msg.sender] = true;
            stakersNum++;
        }
    }

    /**
     * @notice Set rewards of provider pool for specific periodId
     * @param _periodId Period ID to set rewards
     * @param _rewardPercentage Percentage to allocate for rewards, base 10000
     */
    function _setProviderReward(uint256 _periodId, uint256 _rewardPercentage)
        internal
    {
        uint256 _precision = 10000;
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            address tokenAddress = allowedTokens[index];

            uint256 reward = (providersPool[tokenAddress] * _rewardPercentage) /
                (leverage * _precision);

            // Reward must be less than 25% of usersPool to ensure payout at all time
            if (
                reward > (usersPool[tokenAddress] * rewardsCapRate) / _precision
            ) {
                reward =
                    (usersPool[tokenAddress] * _rewardPercentage) /
                    _precision;
            }

            usersPool[tokenAddress] -= reward;
            providersPool[tokenAddress] += reward;

            emit ProviderRewardGenerated(
                _periodId,
                tokenAddress,
                _rewardPercentage,
                _precision,
                reward
            );
        }
    }

    /**
     * @notice Set rewards of user pool for specific periodId
     * @param _periodId Period ID to set rewards
     * @param _rewardPercentage Percentage to allocate for rewards, base 10000
     */
    function _setUserReward(uint256 _periodId, uint256 _rewardPercentage)
        internal
    {
        uint256 _precision = 10000;
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            address tokenAddress = allowedTokens[index];

            uint256 compensation = (usersPool[tokenAddress] *
                leverage *
                _rewardPercentage) / _precision;

            // Compensation must be less than 25% of providersPool to ensure payout at all time
            if (
                compensation >
                (providersPool[tokenAddress] * rewardsCapRate) / _precision
            ) {
                compensation =
                    (providersPool[tokenAddress] * _rewardPercentage) /
                    _precision;
            }

            providersPool[tokenAddress] -= compensation;
            usersPool[tokenAddress] += compensation;

            emit UserCompensationGenerated(
                _periodId,
                tokenAddress,
                usersPool[tokenAddress],
                leverage,
                compensation
            );
        }
    }

    /**
     * @notice Withdraw staked tokens from Provider Pool
     * @param _amount Amount to withdraw
     * @param _tokenAddress Token address to withdraw
     * @param _nextVerifiablePeriod Next verifiable period id of current period
     * @param _contractFinished Present if SLA is terminated or finished
     */
    function _withdrawProviderTokens(
        uint256 _amount,
        address _tokenAddress,
        uint256 _nextVerifiablePeriod,
        bool _contractFinished
    ) internal onlyAllowedToken(_tokenAddress) nonReentrant {
        if (!_contractFinished) {
            require(
                lastProviderStake[msg.sender] < _nextVerifiablePeriod,
                'Provider lock-up until the next verification.'
            );

            // Allow provider withdrawal as long as the provider pool exceeds the leveraged user pool
            require(
                providersPool[_tokenAddress] - _amount >=
                    usersPool[_tokenAddress] * leverage,
                'Withdrawal exceeds leveraged cap.'
            );
        }

        dToken dpToken = dpTokenRegistry[_tokenAddress];
        // Burn duTokens in a way that doesn't affect the Provider Pool / DSLA-SP Pool average
        // t0/p0 = (t0-_amount)/(p0-burnedDPTokens)
        dpToken.burnFrom(
            msg.sender,
            (_amount * dpToken.totalSupply()) / providersPool[_tokenAddress]
        );
        providersPool[_tokenAddress] -= _amount;
        uint256 outstandingAmount = _distributeClaimingRewards(
            _amount,
            _tokenAddress
        );
        IERC20(_tokenAddress).safeTransfer(msg.sender, outstandingAmount);
    }

    /**
     * @notice Withdraw staked tokens from User Pool
     * @param _amount Amount to withdraw
     * @param _tokenAddress Token address to withdraw
     * @param _nextVerifiablePeriod Next verifiable period id of current period
     * @param _contractFinished Present if SLA is terminated or finished
     */
    function _withdrawUserTokens(
        uint256 _amount,
        address _tokenAddress,
        uint256 _nextVerifiablePeriod,
        bool _contractFinished
    ) internal onlyAllowedToken(_tokenAddress) nonReentrant {
        if (!_contractFinished) {
            require(
                lastUserStake[msg.sender] < _nextVerifiablePeriod,
                'User lock-up until the next verification.'
            );
        }

        dToken duToken = duTokenRegistry[_tokenAddress];
        // Burn duTokens in a way that doesn't affect the User Pool / DSLA-SP Pool average
        // t0/p0 = (t0-_amount)/(p0-burnedDUTokens)
        duToken.burnFrom(
            msg.sender,
            (_amount * duToken.totalSupply()) / usersPool[_tokenAddress]
        );
        usersPool[_tokenAddress] -= _amount;
        uint256 outstandingAmount = _distributeClaimingRewards(
            _amount,
            _tokenAddress
        );
        IERC20(_tokenAddress).safeTransfer(msg.sender, outstandingAmount);
    }

    /**
     * @notice Distribute rewards to owner and protocol when user claims
     * @param _amount Amount to withdraw
     * @param _tokenAddress Token address to withdraw
     * @return outstandingAmount
     */
    function _distributeClaimingRewards(uint256 _amount, address _tokenAddress)
        internal
        returns (uint256)
    {
        uint256 slaOwnerRewards = (_amount * ownerRewardsRate) / 10000;
        uint256 protocolRewards = (_amount * protocolRewardsRate) / 10000;
        IERC20(_tokenAddress).safeTransfer(owner(), slaOwnerRewards);
        IERC20(_tokenAddress).safeTransfer(
            _stakeRegistry.owner(),
            protocolRewards
        );
        return _amount - slaOwnerRewards - protocolRewards;
    }

    /**
     * @notice Get number of allowed tokens
     * @return Number of allowed tokens
     */
    function getAllowedTokensLength() external view returns (uint256) {
        return allowedTokens.length;
    }

    /**
     * @notice External view function that returns the number of stakers
     * @return Number of stakers
     */
    function getStakersLength() external view returns (uint256) {
        return stakersNum;
    }

    /**
     * @notice Check if the token is allowed or not
     * @param _tokenAddress Token address to check allowance
     * @return isAllowed
     */
    function isAllowedToken(address _tokenAddress) public view returns (bool) {
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            if (allowedTokens[index] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }
}
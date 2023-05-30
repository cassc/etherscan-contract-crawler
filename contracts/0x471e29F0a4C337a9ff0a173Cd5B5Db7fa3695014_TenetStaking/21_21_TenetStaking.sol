// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesCompUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TenetStaking is ERC20VotesCompUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev Max base points
    uint256 public constant MAX_BPS = 1e4;

    /// @dev Max penalty days
    uint256 private constant PENALTY_DAYS_LIMIT = 90;

    /// @dev Max penalty base points
    uint256 private constant PENALTY_BP_LIMIT = 0.5 * 1e4;

    /// @dev Staking token
    IERC20Upgradeable public stakingToken;

    /// @dev Info about each stake by user address
    mapping(address => Stake[]) public stakers;

    /// @dev Penalty days value
    uint16 public penaltyDays;

    /// @dev Penalty base points value
    uint16 public penaltyBP;

    /// @dev The address to which the penalty tokens will be transferred
    address public treasury;

    /// @dev Total shares
    uint192 public totalShares;

    /// @dev Share bonus base points value for 1M staked tokens
    uint32 public shareBonusBPPer1MTokens;

    /// @dev Minimum stake amount
    uint256 public minAmount;

    /// @dev TenetDistributor address
    address public distributor;

    /// @dev Info about each unstake by user address and stake index
    mapping(address => mapping(uint256 => Withdrawal)) public withdrawals;

    /// @dev Info about user's unstaked balance
    mapping(address => uint256) public balanceOfUnstaked;

    struct Stake {
        bool unstaked;
        uint128 amount;
        uint48 stakedTimestamp;
        uint16 penaltyDays;
        uint16 penaltyBP;
        uint192 shares;
    }

    struct Withdrawal {
        bool withdrawn;
        uint48 withdrawalTimestamp;
    }

    event Staked(
        address indexed staker,
        uint256 indexed stakeIndex,
        uint128 amount,
        uint48 stakedTimestamp,
        uint16 penaltyDays,
        uint16 penaltyBP,
        uint128 totalSupply,
        uint192 shares,
        uint192 totalShares
    );

    event Unstaked(
        address indexed staker,
        uint256 indexed stakeIndex,
        uint128 amount,
        uint16 penaltyDays,
        uint128 totalSupply,
        uint192 shares,
        uint192 totalShares
    );

    event SetPenaltyDays(uint16 penaltyDays);
    event SetPenaltyBP(uint16 penaltyBP);
    event SetTreasury(address treasury);
    event SetShareBonusBPPer1MTokens(uint32 shareBonusBPPer1MTokens);
    event SetMinAmount(uint256 minAmount);
    event SetDistributor(address distributor);
    event Withdrawn(address indexed staker, uint256 indexed stakeIndex, uint256 amount, uint256 penaltyAmount);

    /**
     * @notice Initializer
     * @param _stakingToken Staking token address
     * @param _penaltyDays Penalty days value
     * @param _penaltyBP Penalty base points value
     * @param _treasury The address to which the penalty tokens will be transferred
     * @param _shareBonusBPPer1MTokens Share bonus base points value for 1M staked tokens
     */
    function initialize(
        IERC20Upgradeable _stakingToken,
        uint16 _penaltyDays,
        uint16 _penaltyBP,
        address _treasury,
        uint32 _shareBonusBPPer1MTokens,
        uint256 _minAmount,
        address _distributor
    ) external virtual initializer {
        __ERC20_init("Staked TENET", "stTENET");
        __ERC20Permit_init("Staked TENET");
        __Ownable_init();
        __ReentrancyGuard_init();

        require(address(_stakingToken) != address(0), "TenetStaking: staking token is the zero address");
        require(_penaltyDays <= PENALTY_DAYS_LIMIT, "TenetStaking: penalty days exceeds limit");
        require(_penaltyBP <= PENALTY_BP_LIMIT, "TenetStaking: penalty BP exceeds limit");
        require(_treasury != address(0), "TenetStaking: treasury is the zero address");

        stakingToken = _stakingToken;
        penaltyDays = _penaltyDays;
        penaltyBP = _penaltyBP;
        treasury = _treasury;
        shareBonusBPPer1MTokens = _shareBonusBPPer1MTokens;
        minAmount = _minAmount;
        distributor = _distributor;
    }

    // ** EXTERNAL **

    /**
     * @notice Stake staking tokens
     * @param _amount Amount to stake
     */
    function stake(uint128 _amount) external nonReentrant {
        _stake(msg.sender, _amount);
    }

    /**
     * @notice Stake staking tokens for another user by distributor
     * @param _user Another user address
     * @param _amount Amount to stake
     */
    function stakeFor(address _user, uint128 _amount) external nonReentrant {
        require(msg.sender == distributor, "TenetStaking: only distributor can stake");
        _stake(_user, _amount);
    }

    /**
     * @notice Unstake staking tokens
     * @notice If penalty period is not over grab penalty
     * @param _stakeIndex Stake index in array of user's stakes
     */
    function unstake(uint256 _stakeIndex) external nonReentrant {
        address sender = msg.sender;
        require(_stakeIndex < stakers[sender].length, "TenetStaking: invalid index");

        Stake storage stakeRef = stakers[sender][_stakeIndex];
        require(!stakeRef.unstaked, "TenetStaking: already unstaked");

        _burn(sender, stakeRef.amount);
        totalShares -= stakeRef.shares;
        stakeRef.unstaked = true;

        Withdrawal storage withdrawalRef = withdrawals[sender][_stakeIndex];

        withdrawalRef.withdrawalTimestamp = uint48(block.timestamp + uint48(stakeRef.penaltyDays) * 1 days);
        balanceOfUnstaked[sender] += stakeRef.amount;

        emit Unstaked(sender, _stakeIndex, stakeRef.amount, stakeRef.penaltyDays, uint128(totalSupply()), stakeRef.shares, totalShares);
    }

    /**
     * @notice Withdraw unstaked native asset
     * @notice If penalty period is not over grab penalty
     * @param _stakeIndex Stake index in array of user's stakes
     * @param _force If the user wants to withdraw with a penalty
     */
    function withdraw(uint256 _stakeIndex, bool _force) external nonReentrant {
        address sender = msg.sender;
        Stake storage stakeRef = stakers[sender][_stakeIndex];
        Withdrawal storage withdrawalRef = withdrawals[sender][_stakeIndex];

        require(!withdrawalRef.withdrawn, "TenetStaking: already withdrawn");
        require(withdrawalRef.withdrawalTimestamp > 0, "TenetStaking: stake is not unstaked");

        uint256 penaltyAmount = 0;
        if (_force && block.timestamp < withdrawalRef.withdrawalTimestamp) {
            penaltyAmount = stakeRef.amount * stakeRef.penaltyBP / MAX_BPS;
            stakingToken.safeTransfer(treasury, penaltyAmount);
        } else {
            require(block.timestamp >= withdrawalRef.withdrawalTimestamp, "TenetStaking: withdrawal delay is not over");
        }

        withdrawalRef.withdrawn = true;
        balanceOfUnstaked[sender] -= stakeRef.amount;

        stakingToken.safeTransfer(sender, stakeRef.amount - penaltyAmount);

        emit Withdrawn(sender, _stakeIndex, stakeRef.amount - penaltyAmount, penaltyAmount);
    }

    /**
     * @notice Cancel withdrawal staking token
     * @param _stakeIndex Stake index in array of user's stakes
     */
    function cancelUnstake(uint256 _stakeIndex) external nonReentrant {
        address sender = msg.sender;
        Stake storage stakeRef = stakers[sender][_stakeIndex];
        Withdrawal storage withdrawalRef = withdrawals[sender][_stakeIndex];

        require(!withdrawalRef.withdrawn, "TenetStaking: already withdrawn");
        require(withdrawalRef.withdrawalTimestamp > 0, "TenetStaking: stake is not unstaked");

        withdrawalRef.withdrawalTimestamp = 0;
        balanceOfUnstaked[sender] -= stakeRef.amount;

        _mint(sender, stakeRef.amount);
        totalShares += stakeRef.shares;
        stakeRef.unstaked = false;

        emit Staked(sender, _stakeIndex, stakeRef.amount, stakeRef.stakedTimestamp, stakeRef.penaltyDays, stakeRef.penaltyBP, uint128(totalSupply()), stakeRef.shares, totalShares);
    }

    /**
     * @notice Return a length of stake's array by user address
     * @param _stakerAddress User address
     */
    function stakerStakeCount(address _stakerAddress) external view returns (uint256) {
        return stakers[_stakerAddress].length;
    }

    /**
     * @notice Return shares for the staked amount
     * @dev Share bonus percentage doubles every 1M tokens for the entire amount. Value of 18 for token decimals
     * @param _amount Amount to calculate
     * @return shares Calculated shares for this amount
     */
    function calculateShares(uint256 _amount) public view returns (uint192 shares) {
        uint256 stakingMoreBonus = _amount * _amount * shareBonusBPPer1MTokens / 1e24 / MAX_BPS;
        shares = uint192(_amount + stakingMoreBonus);
    }

    // ** ONLY OWNER **

    /**
     * @notice Set a new penalty days value
     * @param _penaltyDays New penalty days value
     */
    function setPenaltyDays(uint16 _penaltyDays) external onlyOwner {
        require(_penaltyDays <= PENALTY_DAYS_LIMIT, "TenetStaking: penalty days exceeds limit");
        penaltyDays = _penaltyDays;
        emit SetPenaltyDays(_penaltyDays);
    }

    /**
     * @notice Set a new penalty base points value
     * @param _penaltyBP New penalty base points value
     */
    function setPenaltyBP(uint16 _penaltyBP) external onlyOwner {
        require(_penaltyBP <= PENALTY_BP_LIMIT, "TenetStaking: penalty BP exceeds limit");
        penaltyBP = _penaltyBP;
        emit SetPenaltyBP(_penaltyBP);
    }

    /**
     * @notice Set a new penalty treasury
     * @param _treasury New treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "TenetStaking: treasury is the zero address");
        treasury = _treasury;
        emit SetTreasury(_treasury);
    }

    /**
     * @notice Set a share bonus base points value for 1M staked tokens
     * @param _shareBonusBPPer1MTokens New share bonus base points value for 1M staked tokens
     */
    function setShareBonusBPPer1MTokens(uint32 _shareBonusBPPer1MTokens) external onlyOwner {
        shareBonusBPPer1MTokens = _shareBonusBPPer1MTokens;
        emit SetShareBonusBPPer1MTokens(_shareBonusBPPer1MTokens);
    }

    /**
     * @notice Set a minimum amount to stake
     * @param _minAmount Minimum stake amount
     */
    function setMinAmount(uint256 _minAmount) external onlyOwner {
        minAmount = _minAmount;
        emit SetMinAmount(_minAmount);
    }

    /**
     * @notice Set a TenetDistributor address
     * @param _distributor TenetDistributor address
     */
    function setDistributor(address _distributor) external onlyOwner {
        distributor = _distributor;
        emit SetDistributor(_distributor);
    }

    // ** INTERNAL **

    /// @dev Stake staking tokens
    function _stake(address _user, uint128 _amount) internal {
        require(_amount >= minAmount, "TenetStaking: invalid amount");

        uint256 balanceBefore = stakingToken.balanceOf(address(this));
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint128 transferredAmount = uint128(stakingToken.balanceOf(address(this)) - balanceBefore);

        _mint(_user, transferredAmount);

        uint192 shares = calculateShares(transferredAmount);
        totalShares += shares;
        stakers[_user].push(
            Stake(
                false,
                transferredAmount,
                uint48(block.timestamp),
                penaltyDays,
                penaltyBP,
                shares
            )
        );

        uint256 stakeIndex = stakers[_user].length - 1;
        emit Staked(_user, stakeIndex, transferredAmount, uint48(block.timestamp), penaltyDays, penaltyBP, uint128(totalSupply()), shares, totalShares);
    }

    /// @dev Disable transfers
    function _transfer(address _from, address _to, uint256 _amount) internal override {
        revert("TenetStaking: NON_TRANSFERABLE");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesCompUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SkebStaking is
    ERC20VotesCompUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
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

    /// @dev User Address List
    address[] public stakerAddresses;

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

    /// @dev SkebDistributor address
    address public distributor;

    struct Stake {
        bool unstaked;
        uint128 amount;
        uint48 stakedTimestamp;
        uint16 penaltyDays;
        uint16 penaltyBP;
        uint192 shares;
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
        uint128 penaltyAmount,
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
        __ERC20_init("Staked Skeb", "stSKB");
        __ERC20Permit_init("Staked Skeb");
        __Ownable_init();
        __ReentrancyGuard_init();

        require(
            address(_stakingToken) != address(0),
            "SkebStaking: staking token is the zero address"
        );
        require(
            _penaltyDays <= PENALTY_DAYS_LIMIT,
            "SkebStaking: penalty days exceeds limit"
        );
        require(
            _penaltyBP <= PENALTY_BP_LIMIT,
            "SkebStaking: penalty BP exceeds limit"
        );
        require(
            _treasury != address(0),
            "SkebStaking: treasury is the zero address"
        );

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
        require(
            msg.sender == distributor,
            "SkebStaking: only distributor can stake"
        );
        _stake(_user, _amount);
    }

    /**
     * @notice Unstake staking tokens
     * @notice If penalty period is not over grab penalty
     * @param _stakeIndex Stake index in array of user's stakes
     */
    function unstake(uint256 _stakeIndex) external nonReentrant {
        require(
            _stakeIndex < stakers[msg.sender].length,
            "SkebStaking: invalid index"
        );
        Stake storage stakeRef = stakers[msg.sender][_stakeIndex];
        require(!stakeRef.unstaked, "SkebStaking: unstaked already");

        _burn(msg.sender, stakeRef.amount);
        totalShares -= stakeRef.shares;
        stakeRef.unstaked = true;

        // pays a penalty if unstakes during the penalty period
        uint256 penaltyAmount = 0;
        if (
            stakeRef.stakedTimestamp + uint48(stakeRef.penaltyDays) * 86400 >
            block.timestamp
        ) {
            penaltyAmount = (stakeRef.amount * stakeRef.penaltyBP) / MAX_BPS;
            stakingToken.safeTransfer(treasury, penaltyAmount);
        }

        stakingToken.safeTransfer(msg.sender, stakeRef.amount - penaltyAmount);

        emit Unstaked(
            msg.sender,
            _stakeIndex,
            stakeRef.amount,
            uint128(penaltyAmount),
            uint128(totalSupply()),
            stakeRef.shares,
            totalShares
        );
    }

    /**
     * @notice Return a length of stake's array by user address
     * @param _stakerAddress User address
     */
    function stakerStakeCount(address _stakerAddress)
        external
        view
        returns (uint256)
    {
        return stakers[_stakerAddress].length;
    }

    /**
     * @notice Return shares for the staked amount
     * @dev Share bonus percentage doubles every 1M tokens for the entire amount. Value of 18 for token decimals
     * @param _amount Amount to calculate
     * @return shares Calculated shares for this amount
     */
    function calculateShares(uint256 _amount)
        public
        view
        returns (uint192 shares)
    {
        uint256 stakingMoreBonus = (_amount *
            _amount *
            shareBonusBPPer1MTokens) /
            1e24 /
            MAX_BPS;
        shares = uint192(_amount + stakingMoreBonus);
    }

    /**
     * @notice Return Stake user address list
     * @return allStakerAddresses User Address List
     */
    function getAllStakerAddresses()
        external
        view
        returns (address[] memory allStakerAddresses)
    {
        return stakerAddresses;
    }

    /**
     * @notice Return stake's array by user address
     * @param _stakerAddress User address
     * @return stakeInfo Array of Stake struct for specified user address
     */
    function getStakerStakeInfo(address _stakerAddress)
        external
        view
        returns (Stake[] memory stakeInfo)
    {
        return stakers[_stakerAddress];
    }

    // ** ONLY OWNER **

    /**
     * @notice Set a new penalty days value
     * @param _penaltyDays New penalty days value
     */
    function setPenaltyDays(uint16 _penaltyDays) external onlyOwner {
        require(
            _penaltyDays <= PENALTY_DAYS_LIMIT,
            "SkebStaking: penalty days exceeds limit"
        );
        penaltyDays = _penaltyDays;
        emit SetPenaltyDays(_penaltyDays);
    }

    /**
     * @notice Set a new penalty base points value
     * @param _penaltyBP New penalty base points value
     */
    function setPenaltyBP(uint16 _penaltyBP) external onlyOwner {
        require(
            _penaltyBP <= PENALTY_BP_LIMIT,
            "SkebStaking: penalty BP exceeds limit"
        );
        penaltyBP = _penaltyBP;
        emit SetPenaltyBP(_penaltyBP);
    }

    /**
     * @notice Set a new penalty treasury
     * @param _treasury New treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(
            _treasury != address(0),
            "SkebStaking: treasury is the zero address"
        );
        treasury = _treasury;
        emit SetTreasury(_treasury);
    }

    /**
     * @notice Set a share bonus base points value for 1M staked tokens
     * @param _shareBonusBPPer1MTokens New share bonus base points value for 1M staked tokens
     */
    function setShareBonusBPPer1MTokens(uint32 _shareBonusBPPer1MTokens)
        external
        onlyOwner
    {
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
     * @notice Set a SkebDistributor address
     * @param _distributor SkebDistributor address
     */
    function setDistributor(address _distributor) external onlyOwner {
        distributor = _distributor;
        emit SetDistributor(_distributor);
    }

    // ** INTERNAL **

    /// @dev Stake staking tokens
    function _stake(address _user, uint128 _amount) internal {
        require(_amount >= minAmount, "SkebStaking: invalid amount");

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        _mint(_user, _amount);

        uint192 shares = calculateShares(_amount);
        totalShares += shares;

        if (stakers[_user].length == 0) {
            stakerAddresses.push(_user);
        }

        stakers[_user].push(
            Stake(
                false,
                _amount,
                uint48(block.timestamp),
                penaltyDays,
                penaltyBP,
                shares
            )
        );

        uint256 stakeIndex = stakers[_user].length - 1;
        emit Staked(
            _user,
            stakeIndex,
            _amount,
            uint48(block.timestamp),
            penaltyDays,
            penaltyBP,
            uint128(totalSupply()),
            shares,
            totalShares
        );
    }

    /// @dev Disable transfers
    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        revert("SkebStaking: NON_TRANSFERABLE");
    }
}
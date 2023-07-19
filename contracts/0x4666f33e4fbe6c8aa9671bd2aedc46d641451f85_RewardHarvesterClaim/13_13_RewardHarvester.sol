// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Errors} from "./libraries/Errors.sol";
import {Common} from "./libraries/Common.sol";

contract RewardHarvester is Ownable2Step {
    using SafeERC20 for IERC20;

    struct Reward {
        bytes32 merkleRoot;
        bytes32 hashedData;
        uint256 activeAt;
    }

    uint256 public constant FEE_BASIS = 1_000_000;
    uint256 public constant MAX_FEE = 100_000;
    uint256 public constant MINIMUM_ACTIVE_TIMER = 3 hours;

    // Maps members
    mapping(address => bool) public isMember;
    // Maps fees collected for each token
    mapping(address => uint256) public feesCollected;
    // Maps each of the identifier to its reward metadata
    mapping(address => Reward) public rewards;
    // Tracks the amount of claimed reward for the specified token and account
    mapping(address => mapping(address => uint256)) public claimed;
    // Harvest default token
    address public defaultToken;
    // Operator address
    address public operator;
    // Claimer address
    address public claimer;
    // Reward swapper address
    address public rewardSwapper;
    // Used for calculating the timestamp on which rewards can be claimed after an update
    uint256 public activeTimerDuration;

    //-----------------------//
    //        Events         //
    //-----------------------//
    event MemberJoined(address member);
    event MemberLeft(address member);
    event FeesCollected(address indexed token, uint256 amount);
    event BribeTransferred(address indexed token, uint256 totalAmount);
    event RewardClaimed(
        address indexed token,
        address indexed account,
        uint256 amount,
        uint256 postFeeAmount,
        address receiver
    );
    event RewardMetadataUpdated(
        address indexed token,
        bytes32 merkleRoot,
        bytes32 proof,
        uint256 activeAt
    );
    event DefaultTokenUpdated(address indexed token);
    event SetOperator(address indexed operator);
    event SetClaimer(address indexed claimer);
    event SetRewardSwapper(address indexed rewardSwapper);
    event SetActiveTimerDuration(uint256 duration);

    //-----------------------//
    //       Modifiers       //
    //-----------------------//
    /**
     * @notice Modifier to check caller is operator
     */
    modifier onlyOperatorOrOwner() {
        if (msg.sender != operator && msg.sender != owner())
            revert Errors.NotAuthorized();
        _;
    }

    /**
     * @notice Modifier to check caller is operator or reward swapper
     */
    modifier onlyOperatorOrRewardSwapper() {
        if (msg.sender != operator && msg.sender != rewardSwapper)
            revert Errors.NotAuthorized();
        _;
    }

    //-----------------------//
    //       Constructor     //
    //-----------------------//
    constructor(
        address _rewardSwapper,
        address _operator,
        address _defaultToken
    ) {
        _setDefaultToken(_defaultToken);
        _setOperator(_operator);
        _setRewardSwapper(_rewardSwapper);
        _setActiveTimerDuration(MINIMUM_ACTIVE_TIMER);
    }

    //-----------------------//
    //   External Functions  //
    //-----------------------//

    /**
        @notice Join the harvester to enable claiming rewards in default token
     */
    function join() external {
        isMember[msg.sender] = true;

        emit MemberJoined(msg.sender);
    }

    /**
        @notice Leave harvester
     */
    function leave() external {
        isMember[msg.sender] = false;

        emit MemberLeft(msg.sender);
    }

    /**
        @notice Claim rewards based on the specified metadata
        @dev    Can only be called by the claimer contract
        @param  _token        address    Token to claim rewards
        @param  _account      address    Account to claim rewards
        @param  _amount       uint256    Amount of rewards to claim
        @param  _merkleProof  bytes32[]  Merkle proof of the claim
        @param  _fee          uint256    Claim fee
        @param  _receiver     address    Receiver of the rewards
     */
    function claim(
        address _token,
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof,
        uint256 _fee,
        address _receiver
    ) external {
        if (msg.sender != claimer) revert Errors.NotAuthorized();
        if (_account == address(0)) revert Errors.InvalidClaim();
        if (_amount == 0) revert Errors.InvalidAmount();
        if (_fee > MAX_FEE) revert Errors.InvalidFee();

        // Calculate amount after any fees
        uint256 feeAmount = (_amount * _fee) / FEE_BASIS;
        uint256 postFeeAmount = _amount - feeAmount;
        feesCollected[_token] += feeAmount;

        Reward memory reward = rewards[_token];
        uint256 lifeTimeAmount = claimed[_token][_account] + _amount;

        if (reward.merkleRoot == 0) revert Errors.InvalidDistribution();
        if (reward.activeAt > block.timestamp) revert Errors.RewardInactive();

        // Verify the merkle proof
        if (
            !MerkleProof.verifyCalldata(
                _merkleProof,
                reward.merkleRoot,
                keccak256(abi.encodePacked(_account, lifeTimeAmount))
            )
        ) revert Errors.InvalidProof();

        // Update the claimed amount to the current total
        claimed[_token][_account] = lifeTimeAmount;

        IERC20(_token).safeTransfer(_receiver, postFeeAmount);

        emit RewardClaimed(_token, _account, _amount, postFeeAmount, _receiver);
    }

    /**
        @notice Deposit `defaultToken` to this contract
        @param  _amount  uint256  Amount of `defaultToken` to deposit
     */
    function depositReward(
        uint256 _amount
    ) external onlyOperatorOrRewardSwapper {
        if (_amount == 0) revert Errors.InvalidAmount();

        IERC20 token = IERC20(defaultToken);

        uint256 initialAmount = token.balanceOf(address(this));

        token.safeTransferFrom(msg.sender, address(this), _amount);

        emit BribeTransferred(
            defaultToken,
            token.balanceOf(address(this)) - initialAmount
        );
    }

    /**
        @notice Update rewards metadata
        @param  _token       address  Token to update rewards metadata
        @param  _merkleRoot  bytes32  Merkle root of the rewards
        @param  _hashedData  bytes32  Hashed data of the rewards
     */
    function updateRewardsMetadata(
        address _token,
        bytes32 _merkleRoot,
        bytes32 _hashedData
    ) external onlyOperatorOrOwner {
        if (_token == address(0)) revert Errors.InvalidToken();
        if (_merkleRoot == 0) revert Errors.InvalidMerkleRoot();

        // Update the metadata and start the timer until the rewards will be active/claimable
        uint256 activeAt = block.timestamp + activeTimerDuration;
        Reward storage reward = rewards[_token];
        reward.merkleRoot = _merkleRoot;
        reward.hashedData = _hashedData;
        reward.activeAt = activeAt;

        emit RewardMetadataUpdated(_token, _merkleRoot, _hashedData, activeAt);
    }

    /**
        @notice Collect fees
        @param  _token  address  Token to collect fees
     */
    function collectFees(address _token) external onlyOwner {
        uint256 amount = feesCollected[_token];
        if (amount == 0) revert Errors.InvalidAmount();

        feesCollected[_token] = 0;
        IERC20(_token).safeTransfer(msg.sender, amount);

        emit FeesCollected(_token, amount);
    }

    /**
        @notice Change the operator
        @param  _operator  address  New operator address
     */
    function changeOperator(address _operator) external onlyOwner {
        _setOperator(_operator);
    }

    /**
        @notice Change the `defaultToken`
        @param  _newToken  address  New default token address
     */
    function changeDefaultToken(address _newToken) external onlyOwner {
        _setDefaultToken(_newToken);
    }

    /**
        @notice Change the RewardSwapper contract
        @param  _newSwapper  address  New reward swapper address
     */
    function changeRewardSwapper(address _newSwapper) external onlyOwner {
        _setRewardSwapper(_newSwapper);
    }

    /**
        @notice Change claimer address
        @param  _claimer  address  New claimer address
     */
    function changeClaimer(address _claimer) external onlyOwner {
        if (_claimer == address(0)) revert Errors.InvalidAddress();

        claimer = _claimer;

        emit SetClaimer(_claimer);
    }

    /**
        @notice Set the active timer duration
        @param  _duration  uint256  Timer duration
    */
    function changeActiveTimerDuration(uint256 _duration) external onlyOwner {
        _setActiveTimerDuration(_duration);
    }

    //-----------------------//
    //   Internal Functions  //
    //-----------------------//
    /**
        @dev    Internal to set the default token
        @param  _newToken  address  Token address
     */
    function _setDefaultToken(address _newToken) internal {
        if (_newToken == address(0)) revert Errors.InvalidToken();

        defaultToken = _newToken;

        emit DefaultTokenUpdated(_newToken);
    }

    /**
        @dev    Internal to set the RewardSwapper contract
        @param  _newSwapper  address  RewardSwapper address
     */
    function _setRewardSwapper(address _newSwapper) internal {
        if (_newSwapper == address(0)) revert Errors.InvalidAddress();

        rewardSwapper = _newSwapper;

        emit SetRewardSwapper(_newSwapper);
    }

    /**
        @dev    Internal to set the operator
        @param  _operator  address  Token address
     */
    function _setOperator(address _operator) internal {
        if (_operator == address(0)) revert Errors.InvalidOperator();

        operator = _operator;

        emit SetOperator(_operator);
    }

    /**
        @dev    Internal to set the active timer duration
        @param  _duration  uint256  Timer duration
     */
    function _setActiveTimerDuration(uint256 _duration) internal {
        if (_duration < MINIMUM_ACTIVE_TIMER)
            revert Errors.InvalidTimerDuration();

        activeTimerDuration = _duration;

        emit SetActiveTimerDuration(_duration);
    }
}
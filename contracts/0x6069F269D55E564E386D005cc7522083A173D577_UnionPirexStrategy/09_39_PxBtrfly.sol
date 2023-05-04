// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";
import {ERC20SnapshotSolmate} from "src/tokens/ERC20SnapshotSolmate.sol";

contract PxBtrfly is
    ERC20SnapshotSolmate("Pirex BTRFLY", "pxBTRFLY", 18),
    Ownable
{
    /**
        @notice Epoch details
                Reward/snapshotRewards/futuresRewards indexes are associated with 1 reward
        @param  snapshotId               uint256    Snapshot id
        @param  rewards                  bytes32[]  Rewards
        @param  snapshotRewards          uint256[]  Snapshot reward amounts
        @param  futuresRewards           uint256[]  Futures reward amounts
        @param  redeemedSnapshotRewards  mapping    Redeemed snapshot rewards
     */
    struct Epoch {
        uint256 snapshotId;
        bytes32[] rewards;
        uint256[] snapshotRewards;
        uint256[] futuresRewards;
        mapping(address => uint256) redeemedSnapshotRewards;
    }

    // Address of currently assigned operator
    address public operator;

    // Epochs mapped to epoch details
    mapping(uint256 => Epoch) private epochs;

    // Tracks cumulative total amount of rewards per token
    mapping(address => uint256) public cumulativeRewardsByToken;

    event SetOperator(address operator);
    event UpdateEpochFuturesRewards(
        uint256 indexed epoch,
        uint256[] futuresRewards
    );

    error NotAuthorized();
    error NoOperator();
    error Paused();
    error ZeroAddress();
    error ZeroAmount();
    error InvalidEpoch();
    error InvalidFuturesRewards();
    error MismatchedFuturesRewards();

    modifier onlyOperator() {
        if (msg.sender != operator) revert NotAuthorized();
        _;
    }

    modifier onlyOperatorOrNotPaused() {
        address _operator = operator;

        // Ensure an operator is set
        if (_operator == address(0)) revert NoOperator();

        // This contract shares the same pause state as the operator
        if (msg.sender != _operator && Pausable(_operator).paused())
            revert Paused();
        _;
    }

    /** 
        @notice Set a new operator address
        @param  _operator  address  New operator address    
     */
    function setOperator(address _operator) external onlyOwner {
        if (_operator == address(0)) revert ZeroAddress();

        emit SetOperator(_operator);

        // If it's the first operator, also set up 1st epoch with snapshot id 1
        // and prevent reward claims until subsequent epochs
        if (operator == address(0)) {
            uint256 currentEpoch = getCurrentEpoch();
            epochs[currentEpoch].snapshotId = _snapshot();
        }

        operator = _operator;
    }

    /** 
        @notice Return the current snapshotId
        @return uint256  Current snapshot id
     */
    function getCurrentSnapshotId() external view returns (uint256) {
        return _getCurrentSnapshotId();
    }

    /**
        @notice Get current epoch
        @return uint256  Current epoch
     */
    function getCurrentEpoch() public view returns (uint256) {
        return (block.timestamp / 1209600) * 1209600;
    }

    /**
        @notice Get epoch
        @param  epoch            uint256    Epoch
        @return snapshotId       uint256    Snapshot id
        @return rewards          address[]  Reward tokens
        @return snapshotRewards  uint256[]  Snapshot reward amounts
        @return futuresRewards   uint256[]  Futures reward amounts
     */
    function getEpoch(uint256 epoch)
        external
        view
        returns (
            uint256 snapshotId,
            bytes32[] memory rewards,
            uint256[] memory snapshotRewards,
            uint256[] memory futuresRewards
        )
    {
        Epoch storage e = epochs[epoch];

        return (e.snapshotId, e.rewards, e.snapshotRewards, e.futuresRewards);
    }

    /**
        @notice Get redeemed snapshot rewards bitmap
        @param  account  address   Account
        @param  epoch    uint256   Epoch
        @return uint256  Redeemed snapshot bitmap
     */
    function getEpochRedeemedSnapshotRewards(address account, uint256 epoch)
        external
        view
        returns (uint256)
    {
        return epochs[epoch].redeemedSnapshotRewards[account];
    }

    /**
        @notice Add new epoch reward metadata
        @param  epoch           uint256  Epoch
        @param  token           address  Token address
        @param  snapshotReward  uint256  Snapshot reward amount
        @param  futuresReward   uint256  Futures reward amount
     */
    function addEpochRewardMetadata(
        uint256 epoch,
        bytes32 token,
        uint256 snapshotReward,
        uint256 futuresReward
    ) external onlyOperator {
        Epoch storage e = epochs[epoch];

        e.rewards.push(token);
        e.snapshotRewards.push(snapshotReward);
        e.futuresRewards.push(futuresReward);
    }

    /**
        @notice Set redeemed snapshot rewards bitmap
        @param  account   address  Account
        @param  epoch     uint256  Epoch
        @param  redeemed  uint256  Redeemed bitmap
     */
    function setEpochRedeemedSnapshotRewards(
        address account,
        uint256 epoch,
        uint256 redeemed
    ) external onlyOperator {
        epochs[epoch].redeemedSnapshotRewards[account] = redeemed;
    }

    /**
        @notice Update epoch futures rewards to reflect amounts remaining after redemptions
        @param  epoch           uint256    Epoch
        @param  futuresRewards  uint256[]  Futures rewards
     */
    function updateEpochFuturesRewards(
        uint256 epoch,
        uint256[] memory futuresRewards
    ) external onlyOperator {
        if (epoch == 0) revert InvalidEpoch();

        uint256 fLen = epochs[epoch].futuresRewards.length;

        if (fLen == 0) revert InvalidEpoch();
        if (futuresRewards.length == 0) revert InvalidFuturesRewards();
        if (futuresRewards.length != fLen) revert MismatchedFuturesRewards();

        epochs[epoch].futuresRewards = futuresRewards;

        emit UpdateEpochFuturesRewards(epoch, futuresRewards);
    }

    /**
        @notice Update amount of cumulative rewards for the specified reward token
        @param  token   address  Reward token address
        @param  amount  uint256  Amount of reward
     */
    function updateCumulativeRewardsByToken(address token, uint256 amount)
        external
        onlyOperator
    {
        cumulativeRewardsByToken[token] = amount;
    }

    /** 
        @notice Mint the specified amount of tokens to the specified account
        @param  account  address  Receiver of the tokens
        @param  amount   uint256  Amount to be minted
     */
    function mint(address account, uint256 amount) external onlyOperator {
        if (account == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        _mint(account, amount);
    }

    /** 
        @notice Burn the specified amount of tokens from the specified account
        @param  account  address  Owner of the tokens
        @param  amount   uint256  Amount to be burned
     */
    function burn(address account, uint256 amount) external onlyOperator {
        if (account == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        _burn(account, amount);
    }

    /** 
        @notice Approve allowances by operator with specified accounts and amount
        @param  from    address  Owner of the tokens
        @param  to      address  Account to be approved
        @param  amount  uint256  Amount to be approved
     */
    function operatorApprove(
        address from,
        address to,
        uint256 amount
    ) external onlyOperator {
        if (from == address(0)) revert ZeroAddress();
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        _approve(from, to, amount);
    }

    /**
        @notice Snapshot token balances for the current epoch
     */
    function takeEpochSnapshot() external onlyOperatorOrNotPaused {
        uint256 currentEpoch = getCurrentEpoch();

        // If snapshot has not been set for current epoch, take snapshot
        if (epochs[currentEpoch].snapshotId == 0) {
            epochs[currentEpoch].snapshotId = _snapshot();
        }
    }
}
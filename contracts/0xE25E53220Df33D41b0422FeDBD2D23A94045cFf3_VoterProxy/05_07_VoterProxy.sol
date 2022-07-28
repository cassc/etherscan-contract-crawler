// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./utils/Interfaces.sol";
import "./utils/MathUtil.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title VoterProxy contract
/// @dev based on Convex's VoterProxy smart contract
///      https://etherscan.io/address/0x989AEb4d175e16225E39E87d0D97A3360524AD80#code
contract VoterProxy is IVoterProxy {
    using MathUtil for uint256;
    using SafeERC20 for IERC20;

    // Same address on all chains
    address public constant SNAPSHOT_REGISTRY = 0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446;
    bytes32 public constant BALANCER_SNAPSHOT_ID = 0x62616c616e6365722e6574680000000000000000000000000000000000000000;

    event OperatorChanged(address newOperator);
    event DepositorChanged(address newDepositor);
    event OwnerChanged(address newOwner);
    event StashAccessGranted(address stash);
    event VotingPowerDelegated(address _delegate);
    event VotingPowerCleared();

    error BadInput();
    error Unauthorized();
    error NeedsShutdown(); // Current operator must be shutdown before changing the operator

    address public immutable mintr;
    address public immutable bal; // Reward token
    address public immutable wethBal; // Staking token
    address public immutable veBal; // veBal
    address public immutable gaugeController;

    address public owner; // MultiSig
    address public operator; // Controller smart contract
    address public depositor; // BalDepositor smart contract

    mapping(address => bool) private stashAccess; // stash -> canAccess
    mapping(address => bool) private protectedTokens; // token -> protected

    constructor(
        address _mintr,
        address _bal,
        address _wethBal,
        address _veBal,
        address _gaugeController
    ) {
        mintr = _mintr;
        bal = _bal;
        wethBal = _wethBal;
        veBal = _veBal;
        gaugeController = _gaugeController;
        owner = msg.sender;
        IERC20(_wethBal).approve(_veBal, type(uint256).max);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyOperator() {
        if (msg.sender != operator) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyDepositor() {
        if (msg.sender != depositor) {
            revert Unauthorized();
        }
        _;
    }

    /// @notice Balance of gauge
    /// @param _gauge The gauge to check
    /// @return uint256 balance
    function balanceOfPool(address _gauge) public view returns (uint256) {
        return IBalGauge(_gauge).balanceOf(address(this));
    }

    /// @notice Used to change the owner of the contract
    /// @param _newOwner The new owner of the contract
    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    /// @notice Changes the operator of the contract
    /// @dev Only the owner can change the operator
    ///      Current operator must be shutdown before changing the operator
    ///      Or we can set operator to address(0)
    /// @param _operator The new operator of the contract
    function setOperator(address _operator) external onlyOwner {
        if (operator != address(0) && !IController(operator).isShutdown()) {
            revert NeedsShutdown();
        }
        operator = _operator;
        emit OperatorChanged(_operator);
    }

    /// @notice Changes the depositor of the contract
    /// @dev Only the owner can change the depositor
    /// @param _depositor The new depositor of the contract
    function setDepositor(address _depositor) external onlyOwner {
        depositor = _depositor;
        emit DepositorChanged(_depositor);
    }

    /// @notice Used to deposit tokens
    /// @param _token The address of the LP token
    /// @param _gauge The gauge to deposit to
    function deposit(address _token, address _gauge) external onlyOperator {
        if (protectedTokens[_token] == false) {
            protectedTokens[_token] = true;
        }
        if (protectedTokens[_gauge] == false) {
            protectedTokens[_gauge] = true;
        }

        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_token).approve(_gauge, balance);
            IBalGauge(_gauge).deposit(balance);
        }
    }

    /// @notice Used for withdrawing tokens
    /// @dev If this contract doesn't have enough tokens it will withdraw them from gauge
    /// @param _token ERC20 token address
    /// @param _gauge The gauge to withdraw from
    /// @param _amount The amount of tokens to withdraw
    function withdraw(
        address _token,
        address _gauge,
        uint256 _amount
    ) public onlyOperator {
        uint256 _balance = IERC20(_token).balanceOf(address(this));

        if (_balance < _amount) {
            IBalGauge(_gauge).withdraw(_amount - _balance);
        }
        IERC20(_token).transfer(msg.sender, _amount);
    }

    /// @notice Delegates voting power to EOA
    /// so that it can vote on behalf of DAO off chain (Snapshot)
    /// @param _delegateTo to whom we delegate voting power
    function delegateVotingPower(address _delegateTo) external onlyOperator {
        ISnapshotDelegateRegistry(SNAPSHOT_REGISTRY).setDelegate(BALANCER_SNAPSHOT_ID, _delegateTo);
        emit VotingPowerDelegated(_delegateTo);
    }

    /// @notice Clears delegation
    function clearDelegate() external onlyOperator {
        ISnapshotDelegateRegistry(SNAPSHOT_REGISTRY).clearDelegate(BALANCER_SNAPSHOT_ID);
        emit VotingPowerCleared();
    }

    /// @notice Votes for multiple gauge weights
    /// @dev Input arrays must have same length
    /// @param _gauges The gauges to vote for
    /// @param _weights The weights for a gauge in basis points (units of 0.01%). Minimal is 0.01%. Ignored if 0
    function voteMultipleGauges(address[] calldata _gauges, uint256[] calldata _weights) external onlyOperator {
        if (_gauges.length != _weights.length) {
            revert BadInput();
        }
        for (uint256 i = 0; i < _gauges.length; i = i.unsafeInc()) {
            IVoting(gaugeController).vote_for_gauge_weights(_gauges[i], _weights[i]);
        }
    }

    /// @notice Claims VeBal tokens
    /// @param _gauge The gauge to claim from
    /// @return amount claimed
    function claimBal(address _gauge) external onlyOperator returns (uint256) {
        uint256 _balance;

        try IMinter(mintr).mint(_gauge) {
            _balance = IERC20(bal).balanceOf(address(this));
            IERC20(bal).transfer(operator, _balance);
            //solhint-disable-next-line
        } catch {}

        return _balance;
    }

    /// @notice Claims rewards
    /// @notice _gauge The gauge to claim from
    function claimRewards(address _gauge) external onlyOperator {
        IBalGauge(_gauge).claim_rewards();
    }

    /// @notice Claims fees
    /// @param _distroContract The distro contract to claim from
    /// @param _tokens The tokens to claim
    function claimFees(address _distroContract, IERC20[] calldata _tokens) external onlyOperator {
        IFeeDistro(_distroContract).claimTokens(address(this), _tokens);

        for (uint256 i = 0; i < _tokens.length; i = i.unsafeInc()) {
            uint256 balance = _tokens[i].balanceOf(address(this));
            if (balance != 0) {
                _tokens[i].safeTransfer(operator, balance);
            }
        }
    }

    /// @notice Executes a call to `_to` with calldata `_data`
    /// @param _to The address to call
    /// @param _value The ETH value to send
    /// @param _data calldata
    /// @return The result of the call (bool, result)
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOperator returns (bool, bytes memory) {
        // solhint-disable-next-line
        (bool success, bytes memory result) = _to.call{ value: _value }(_data);

        return (success, result);
    }

    /// @notice Locks BAL tokens to veBal
    /// @param _value The amount of BAL tokens to lock
    /// @param _unlockTime Epoch time when tokens unlock, rounded down to whole weeks
    function createLock(uint256 _value, uint256 _unlockTime) external onlyDepositor {
        IBalVoteEscrow(veBal).create_lock(_value, _unlockTime);
    }

    /// @notice Increases amount of veBal tokens without modifying the unlock time
    /// @param _value The amount of veBal tokens to increase
    function increaseAmount(uint256 _value) external onlyDepositor {
        IBalVoteEscrow(veBal).increase_amount(_value);
    }

    /// @notice Extend the unlock time
    /// @param _value New epoch time for unlocking
    function increaseTime(uint256 _value) external onlyDepositor {
        IBalVoteEscrow(veBal).increase_unlock_time(_value);
    }

    /// @notice Redeems veBal tokens
    /// @dev Only possible if the lock has expired
    function release() external onlyDepositor {
        IBalVoteEscrow(veBal).withdraw();
    }

    /// @notice Used for withdrawing tokens
    /// @dev If this contract doesn't have enough tokens it will withdraw them from gauge
    /// @param _token ERC20 token address
    /// @param _gauge The gauge to withdraw from
    function withdrawAll(address _token, address _gauge) external {
        // withdraw has authorization check, so we don't need to check here
        uint256 amount = balanceOfPool(_gauge) + (IERC20(_token).balanceOf(address(this)));
        withdraw(_token, _gauge, amount);
    }

    /// @notice Used for withdrawing wethBal tokens to address
    /// @param _to send to address
    function withdrawWethBal(address _to) external onlyOperator {
        IBalVoteEscrow(veBal).withdraw();
        uint256 _balance = IERC20(wethBal).balanceOf(address(this));
        IERC20(wethBal).safeTransfer(_to, _balance);
    }
}
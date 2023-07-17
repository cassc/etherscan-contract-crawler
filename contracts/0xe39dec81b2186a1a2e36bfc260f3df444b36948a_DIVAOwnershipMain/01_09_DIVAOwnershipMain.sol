// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IDIVAOwnershipMain} from "./interfaces/IDIVAOwnershipMain.sol";

/**
 * @notice Contract that stores the DIVA owner and implements a decentralized mechanism (a so-called
 * decentralized protocol takeover mechanism) to elect a new owner.
 * The reason for outsourcing the owner logic into a separate contract allows the owner to inherit all
 * future versions of DIVA protocol and other related contracts by referencing this contract.
 * The owner election logic is specific to the main chain. Tellor protocol is used to communicate
 * the owner to secondary chains.
 * 
 * Decentralized protocol takeover mechanism:
 * The owner is elected by DIVA Token holders which express their support for a candidate (incl. current owner) 
 * by staking DIVA tokens towards that candidate. If a candidate accumulates more stake than the current owner,
 * they can trigger an election cycle which is split into the following two successive periods:
 *   1. Showdown period (30 days): DIVA token holders continue to stake/unstake during that period to express
 *   their support for their preferred candidate. At the end of the period, a snapshot of the stakes is taken
 *   via a manual ownership claim submission process (see second period below) which determines the outcome of the
 *   election cycle.
 *   2. Ownership claim submission period (7 days): any candidate that has a higher stake than the current owner
 *   can submit a claim on the ownership by calling the `submitOwnershipClaim` function. 
 *   Staking/unstaking are disabled during that period. This manual ownership claim submission process has been
 *   implemented to avoid costly max calculations / loops inside the smart contract.
 */
contract DIVAOwnershipMain is IDIVAOwnershipMain, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    // `_owner` variable is equal to candidate that submitted a valid ownership claim during
    // the ownership claim submission period. `_owner` is returned as the new owner by the 
    // `getCurrentOwner()`function after the end of the election cycle.
    // Initialized in the constructor at contract deployment.
    address private _owner;

    // Previous owner is updated with the current owner when an election cycle is triggered.
    // `_previousOwner` is initialized to zero address at contract deployment.
    // Initialized to zero address at contract deployment.
    address private _previousOwner;

    // DIVA token address used for staking
    IERC20Metadata private immutable _DIVA_TOKEN;

    // Staking related storage variables
    mapping(address => uint256) private _candidateToStakedAmount;
    mapping(address => mapping(address => uint256)) private _voterToCandidateToStakedAmount;
    mapping(address => mapping(address => uint256)) private _voterToTimestampLastStakedForCandidate; 

    // Election cycle related end times. Initialized to zero ad contract deployment.
    uint256 private _showdownPeriodEnd;
    uint256 private _submitOwnershipClaimPeriodEnd;
    uint256 private _cooldownPeriodEnd;
    
    // Relevant period lengths
    uint256 private constant _SHOWDOWN_PERIOD = 30 days;
    uint256 private constant _SUBMIT_OWNERSHIP_CLAIM_PERIOD = 7 days;
    uint256 private constant _COOLDOWN_PERIOD = 7 days;
    uint256 private constant _MIN_STAKING_PERIOD = 7 days;

    constructor(
        address _initialOwner,
        IERC20Metadata _divaToken
    ) payable {
        if (_initialOwner == address(0)) {
            revert ZeroOwnerAddress();
        }
        if (address(_divaToken) == address(0)) {
            revert ZeroDIVATokenAddress();
        }

        _owner = _initialOwner;
        _DIVA_TOKEN = _divaToken;
    }

    function stake(address _candidate, uint256 _amount) external override nonReentrant {
        // Ensure that call is not within the ownership claim submission period
        if (_isWithinSubmitOwnershipClaimPeriod()) {
            revert WithinSubmitOwnershipClaimPeriod(block.timestamp, _submitOwnershipClaimPeriodEnd);
        }
        
        // Transfer DIVA token from `msg.sender` to `this`. Requires prior approval
        // from `msg.sender` to succeed. No security risk of executing this external function as 
        // `_DIVA_TOKEN` is initialized in the constructor and the functionality is known.
        _DIVA_TOKEN.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
                
        // Store timestamp of staking operation for the minimum staking period check in
        // `unstake` function
        _voterToTimestampLastStakedForCandidate[msg.sender][_candidate] = block.timestamp;

        // Increase `msg.sender`'s staked amount for candidate
        _voterToCandidateToStakedAmount[msg.sender][_candidate] += _amount;

        // Increase staked amount for candidate
        _candidateToStakedAmount[_candidate] += _amount;

        // Log candidate and amount
        emit Staked(msg.sender, _candidate, _amount);        
    }

    function triggerElectionCycle() external override {    
        // Confirm that there is no on-going election cycle
        if (_isWithinElectionCycle()) {
            revert WithinElectionCycle(block.timestamp, _submitOwnershipClaimPeriodEnd);
        }

        // Confirm that at least 7 days have passed since the last election cycle end
        if (_isWithinCooldownPeriod()) {
            revert WithinCooldownPeriod(block.timestamp, _cooldownPeriodEnd);
        }

        // Confirm that `msg.sender` has strictly more support than the current owner
        if (_candidateToStakedAmount[msg.sender] <= _candidateToStakedAmount[_owner]) {
            revert InsufficientStakingSupport();
        }

        // Store the current owner in `_previousOwner` variable which is returned as the current owner
        // by `getCurrentOwner()` function during an election cycle.
        _previousOwner = _owner;
        
        // Set end times for election cycle related periods
        _showdownPeriodEnd = block.timestamp + _SHOWDOWN_PERIOD;
        _submitOwnershipClaimPeriodEnd = _showdownPeriodEnd + _SUBMIT_OWNERSHIP_CLAIM_PERIOD;
        _cooldownPeriodEnd = _submitOwnershipClaimPeriodEnd + _COOLDOWN_PERIOD;

        // Log account that triggered the election cycle as well as the block timestamp
        emit ElectionCycleTriggered(msg.sender, block.timestamp);
    }
    
    function submitOwnershipClaim() external override {
        // Check that called within the ownership claim submission period
        if (!_isWithinSubmitOwnershipClaimPeriod()) {
            revert NotWithinSubmitOwnershipClaimPeriod() ;
        }

        // Check that `msg.sender` has strictly more stake than current leading candidate
        if (_candidateToStakedAmount[msg.sender] <= _candidateToStakedAmount[_owner]) {
                revert NotLeader();
        }        

        // Update `_owner` variable. Returned as owner inside `getCurrentOwner()`
        // after election cycle end.
        _owner = msg.sender;

        // Log candidate that submitted an ownership claim
        emit OwnershipClaimSubmitted(msg.sender);
    }

    function unstake(address _candidate, uint256 _amount) external override nonReentrant {
        // Check whether the 7 day minimum staking period has been respected
        uint _minStakingPeriodEnd =
            _voterToTimestampLastStakedForCandidate[msg.sender][_candidate] + _MIN_STAKING_PERIOD;
        if (block.timestamp < _minStakingPeriodEnd) {
            revert MinStakingPeriodNotExpired(block.timestamp, _minStakingPeriodEnd);
        }

        // Check that outside of ownership claim submission period
        if (_isWithinSubmitOwnershipClaimPeriod()) {
            revert WithinSubmitOwnershipClaimPeriod(block.timestamp, _submitOwnershipClaimPeriodEnd);
        }
 
        // Update staking balances. Both operations will revert on underflow as
        // Solidity version > 0.8.0 is used
        _voterToCandidateToStakedAmount[msg.sender][_candidate] -= _amount;
        _candidateToStakedAmount[_candidate] -= _amount;
        
        // Transfer DIVA token to `msg.sender`
        _DIVA_TOKEN.safeTransfer(msg.sender, _amount);

        // Log candidate and amount
        emit Unstaked(msg.sender, _candidate, _amount);
    }

    function getStakedAmount(
        address _voter,
        address _candidate
    ) 
        external
        view
        override returns (uint256)
    {
        return _voterToCandidateToStakedAmount[_voter][_candidate];
    }

    function getStakedAmount(address _candidate) external view override returns (uint256) {
        return _candidateToStakedAmount[_candidate];
    }

    function getCurrentOwner() public view override returns (address owner)
    {
        // During an election cycle, the current owner is stored inside the `_previousOwner` variable
        return _isWithinElectionCycle() ? _previousOwner : _owner;
    }

    function getTimestampLastStakedForCandidate(
        address _user,
        address _candidate
    ) external view override returns (uint256) {
        return _voterToTimestampLastStakedForCandidate[_user][_candidate];
    }

    function getShowdownPeriodEnd() external view override returns (uint256) {
        return _showdownPeriodEnd;
    }

    function getSubmitOwnershipClaimPeriodEnd() external view override returns (uint256) {
        return _submitOwnershipClaimPeriodEnd;
    }

    function getCooldownPeriodEnd() external view override returns (uint256) {
        return _cooldownPeriodEnd;
    }

    function getDIVAToken() external view override returns (address) {
        return address(_DIVA_TOKEN);
    }

    function getShowdownPeriod() external pure returns (uint256) {
        return _SHOWDOWN_PERIOD;
    }

    function getSubmitOwnershipClaimPeriod() external pure returns (uint256) {
        return _SUBMIT_OWNERSHIP_CLAIM_PERIOD;
    }

    function getCooldownPeriod() external pure returns (uint256) {
        return _COOLDOWN_PERIOD;
    }

    function getMinStakingPeriod() external pure returns (uint256) {
        return _MIN_STAKING_PERIOD;
    }

    function _isWithinSubmitOwnershipClaimPeriod() private view returns (bool) {
        return (block.timestamp > _showdownPeriodEnd &&  
            block.timestamp <= _submitOwnershipClaimPeriodEnd);
    }

    function _isWithinElectionCycle() private view returns (bool) {
        return (block.timestamp <= _submitOwnershipClaimPeriodEnd);
    }

    function _isWithinCooldownPeriod() private view returns (bool) {
        return (_submitOwnershipClaimPeriodEnd < block.timestamp &&
            block.timestamp <= _cooldownPeriodEnd);
    }
}
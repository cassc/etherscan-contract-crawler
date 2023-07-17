// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IBribe} from "../interfaces/IBribe.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import {AUTOMATE} from "../constants/Automate.sol";
import {BRIBE_VAULT} from "../constants/BribeVault.sol";
import {NATIVE_TOKEN} from "../constants/Tokens.sol";

import {Plan} from "./Plan.sol";
import {Mapping} from "./Mapping.sol";
import {AutomateReady} from "../vendor/AutomateReady.sol";

contract Briber is AutomateReady, Pausable {
    using Mapping for Mapping.Map;

    address public owner;
    Mapping.Map private _plans;
    mapping(IERC20 => uint256) public allocated;

    event CreatedPlan(bytes32 indexed key, Plan plan);

    event RemovedPlan(bytes32 indexed key, Plan plan);

    event PlanCancelled(bytes32 indexed key, Plan plan);

    event PlanCompleted(bytes32 indexed key, Plan plan);

    event PlanSkipped(bytes32 indexed key, Plan plan);

    event ExecutedBribe(
        bytes32 indexed key,
        bytes32 indexed proposal,
        uint256 indexed amount,
        uint256 fee,
        Plan plan
    );

    event Deposit(address indexed from, uint256 indexed amount);

    event Withdraw(address indexed to, uint256 indexed amount);

    event WithdrawERC20(
        address indexed to,
        IERC20 indexed token,
        uint256 indexed amount
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Briber.onlyOwner");
        _;
    }

    constructor() AutomateReady(AUTOMATE, msg.sender) {
        owner = msg.sender;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function createPlan(
        IBribe hhBriber,
        address gauge,
        IERC20 token,
        uint256 amount,
        uint256 interval,
        uint256 start,
        uint256 epochs,
        bool canSkip,
        bool unsafe
    ) external onlyOwner {
        require(amount > 0, "Briber.createPlan: amount must not be zero");

        uint256 totalAmount = _getAllocated(amount, epochs);

        // ensures that sufficient tokens are present to execute the plan to completion
        // this can be overridden with unsafe=true
        require(
            unsafe || totalAmount <= _getAvailable(token),
            "Briber.createPlan: amount exceeds available"
        );

        // tokens are allocated to this plan
        allocated[token] += totalAmount;

        _createPlan(
            hhBriber,
            gauge,
            token,
            amount,
            interval,
            start,
            epochs,
            canSkip,
            true
        );
    }

    // this function is inherently safe as its plans bribe all unallocated tokens
    function createPlanAll(
        IBribe hhBriber,
        address gauge,
        IERC20 token,
        uint256 interval,
        uint256 start,
        uint256 epochs,
        bool canSkip
    ) external onlyOwner {
        _createPlan(
            hhBriber,
            gauge,
            token,
            1000,
            interval,
            start,
            epochs,
            canSkip,
            false
        );
    }

    // bribe percentage of available (one decimal place -> 100% = 1000)
    // this function is inherently safe as its plans bribe a percentage of all unallocated tokens
    function createPlanPct(
        IBribe hhBriber,
        address gauge,
        IERC20 token,
        uint256 percent,
        uint256 interval,
        uint256 start,
        uint256 epochs,
        bool canSkip
    ) external onlyOwner {
        require(
            percent > 0 && percent <= 1000,
            "Briber.createPlanPct: percentage must be between 0-1000"
        );

        _createPlan(
            hhBriber,
            gauge,
            token,
            percent,
            interval,
            start,
            epochs,
            canSkip,
            false
        );
    }

    function removePlan(bytes32 key) external onlyOwner {
        Plan storage plan = _plans.get(key);

        _freeAllocated(plan);
        emit RemovedPlan(key, plan);
        _plans.remove(key);
    }

    // queue a plan for immediate execution
    // this doesn't work for plans with start times multiple epochs in the future
    // e.g., allows for re-exec of a plan which was skipped due to insufficient tokens
    function execBribeOnce(bytes32 key) external onlyOwner {
        Plan storage plan = _plans.get(key);

        plan.nextExec -= plan.interval;

        // solhint-disable not-rely-on-time
        require(
            plan.nextExec <= block.timestamp,
            "Briber.execBribeOnce: cannot queue for immediate execution"
        );
    }

    function execBribe(
        bytes32 key,
        bytes32 proposal
    ) external onlyDedicatedMsgSender whenNotPaused {
        (uint256 fee, address feeToken) = _getFeeDetails();
        _transfer(fee, feeToken);

        Plan storage plan = _plans.get(key);

        // avoid timeslip (block.timestamp is not used)
        // (nextExec - firstExec) % interval == 0
        plan.nextExec += plan.interval;
        plan.remainingEpochs--;

        // free up tokens used for the bribe
        // regardless of execution
        if (plan.isFixed) allocated[plan.token] -= plan.amount;

        uint256 amount = _getBribeAmount(plan);

        if (amount > 0) _bribe(key, plan, proposal, amount, fee);
        else _skipPlan(key, plan);

        // if plan is not already removed
        // remove plan if it has completed (no more epochs remaining)
        // no need to free up tokens since they are guaranteed to have been spent
        if (plan.remainingEpochs == 0 && _plans.exists(key)) {
            emit PlanCompleted(key, plan);
            _plans.remove(key);
        }
    }

    function withdraw(address payable to, uint256 amount) external onlyOwner {
        require(amount > 0, "Briber.withdraw: amount must not be zero");

        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Briber.withdraw: failed to withdraw");

        emit Withdraw(to, amount);
    }

    function withdrawERC20(
        address payable to,
        IERC20 token,
        uint256 amount,
        bool unsafe
    ) external onlyOwner {
        require(amount > 0, "Briber.withdrawERC20: amount must not be zero");

        require(
            address(token) != address(0),
            "Briber.withdrawERC20: invalid token"
        );

        require(
            address(token) != NATIVE_TOKEN,
            "Briber.withdrawERC20: use 'Briber.withdraw' instead"
        );

        // prevents withdrawing tokens which are in use by existing plans
        // can be overriden with unsafe=true
        require(
            unsafe || amount <= _getAvailable(token),
            "Briber.withdrawERC20: amount exceeds available"
        );

        bool sent = token.transfer(to, amount);
        require(sent, "Briber.withdrawERC20: failed to withdraw");

        emit WithdrawERC20(to, token, amount);
    }

    function getPlan(bytes32 key) external view returns (Plan memory) {
        return _plans.get(key);
    }

    function getPlans() external view returns (Plan[] memory) {
        return _plans.all();
    }

    // solhint-disable function-max-lines
    function _createPlan(
        IBribe hhBriber,
        address gauge,
        IERC20 token,
        uint256 amount,
        uint256 interval,
        uint256 start,
        uint256 epochs,
        bool canSkip,
        bool isFixed
    ) internal {
        require(epochs > 0, "Briber._createPlan: must have one or more epochs");

        require(
            interval >= 60,
            "Briber._createPlan: must have at least one minute interval"
        );

        require(gauge != address(0), "Briber._createPlan: invalid gauge");

        require(
            address(hhBriber) != address(0),
            "Briber._createPlan: invalid briber"
        );

        require(
            address(token) != address(0),
            "Briber._createPlan: invalid token"
        );
        require(
            address(token) != NATIVE_TOKEN,
            "Briber._createPlan: native token not supported"
        );
        require(
            hhBriber.isWhitelistedToken(token),
            "Briber._createPlan: token not whitelisted"
        );

        // solhint-disable not-rely-on-time
        uint256 createdAt = block.timestamp;

        if (start == 0)
            // start now
            start = createdAt;
        else {
            // ensure the plan starts either:
            // 1. in the future (or now)
            // 2. no more than one epoch in the past
            //    this allows us to e.g., schedule a plan for every Wednesday which is
            //    created on a Thursday without having to wait 6 days for the first exec
            //    the first exec will be on Thursday and subsequent execs on Wednesday
            require(
                start >= createdAt || createdAt - start < interval,
                "Briber._createPlan: Start must not be more than one epoch in the past"
            );
        }

        // derive unique identifier key
        // can not use nextExec or remainingEpochs since they are mutable
        bytes32 key = keccak256(
            abi.encodePacked(
                hhBriber,
                gauge,
                token,
                amount,
                interval,
                createdAt,
                canSkip,
                isFixed
            )
        );

        Plan memory plan = Plan(
            hhBriber,
            gauge,
            token,
            amount,
            interval,
            start,
            createdAt,
            epochs,
            canSkip,
            isFixed
        );

        _plans.set(key, plan);
        emit CreatedPlan(key, plan);
    }

    function _bribe(
        bytes32 key,
        Plan storage plan,
        bytes32 proposal,
        uint256 amount,
        uint256 fee
    ) internal {
        require(
            plan.hhBriber.proposalDeadlines(proposal) > block.timestamp,
            "Briber._bribe: proposal deadline has passed"
        );

        plan.token.approve(BRIBE_VAULT, amount);
        plan.hhBriber.depositBribeERC20(proposal, plan.token, amount);

        emit ExecutedBribe(key, proposal, amount, fee, plan);
    }

    function _skipPlan(bytes32 key, Plan storage plan) internal {
        if (plan.canSkip) {
            emit PlanSkipped(key, plan);
            return;
        }

        // cancel the plan if it is not skippable
        _freeAllocated(plan);
        emit PlanCancelled(key, plan);
        _plans.remove(key);
    }

    function _freeAllocated(Plan storage plan) internal {
        if (!plan.isFixed) return;

        // free up remaining portion of allocated tokens
        uint256 remainingAmount = _getAllocated(
            plan.amount,
            plan.remainingEpochs
        );

        allocated[plan.token] -= remainingAmount;
    }

    function _getBribeAmount(
        Plan storage plan
    ) internal view returns (uint256) {
        // fixed plans can only have insufficient tokens if:
        // 1. an unsafe plan was added and/or
        // 2. an unsafe withdrawal was requested
        if (plan.isFixed)
            return
                plan.amount <= plan.token.balanceOf(address(this))
                    ? plan.amount
                    : 0;

        uint256 available = _getAvailable(plan.token);
        return (available * plan.amount) / 1000;
    }

    // get the contract balance excluding tokens allocated to existing plans
    function _getAvailable(IERC20 token) internal view returns (uint256) {
        uint256 balance = token.balanceOf(address(this));
        return balance > allocated[token] ? balance - allocated[token] : 0;
    }

    // get a plans allocated tokens based on its amount per epoch and remaining epochs
    function _getAllocated(
        uint256 amount,
        uint256 epochs
    ) internal pure returns (uint256) {
        return amount * epochs;
    }
}
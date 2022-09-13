// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {YearnAngleVoter} from "./YearnAngleVoter.sol";

import "./interfaces/curve/ICurve.sol";
import "./interfaces/Angle/IStableMaster.sol";
import "./interfaces/Angle/IAngleGauge.sol";
import "./interfaces/Uniswap/IUniV2.sol";

library SafeVoter {
    function safeExecute(
        YearnAngleVoter voter,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        (bool success, bytes memory result) = voter.execute(to, value, data);
        require(success, string(result));
    }
}

contract AngleStrategyVoterProxy {
    using SafeVoter for YearnAngleVoter;
    using SafeERC20 for IERC20;
    using Address for address;

    YearnAngleVoter public yearnAngleVoter;
    address public constant angleToken = address(0x31429d1856aD1377A8A0079410B297e1a9e214c2);

    uint256 public constant UNLOCK_TIME = 4 * 365 * 24 * 60 * 60;

    // gauge => strategies
    mapping(address => address) public strategies;
    mapping(address => bool) public voters;
    address public governance;

    constructor(address _voter) public {
        governance = address(0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52);
        yearnAngleVoter = YearnAngleVoter(_voter);
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function approveStrategy(address _gauge, address _strategy) external {
        require(msg.sender == governance, "!governance");
        strategies[_gauge] = _strategy;
    }

    function revokeStrategy(address _gauge) external {
        require(msg.sender == governance, "!governance");
        strategies[_gauge] = address(0);
    }

    function approveVoter(address _voter) external {
        require(msg.sender == governance, "!governance");
        voters[_voter] = true;
    }

    function revokeVoter(address _voter) external {
        require(msg.sender == governance, "!governance");
        voters[_voter] = false;
    }

    function lock(uint256 amount) external {
        if (amount > 0 && amount <= IERC20(angleToken).balanceOf(address(yearnAngleVoter))) {
            yearnAngleVoter.createLock(amount, block.timestamp + UNLOCK_TIME);
        }
    }

    function increaseAmount(uint256 amount) external {
        if (amount > 0 && amount <= IERC20(angleToken).balanceOf(address(yearnAngleVoter))) {
            yearnAngleVoter.increaseAmount(amount);
        }
    }

    function vote(address _gauge, uint256 _amount) public {
        require(voters[msg.sender], "!voter");
        yearnAngleVoter.safeExecute(_gauge, 0, abi.encodeWithSignature("vote_for_gauge_weights(address,uint256)", _gauge, _amount));
    }

    function withdraw(
        address _gauge,
        address _token,
        uint256 _amount
    ) public returns (uint256) {
        require(strategies[_gauge] == msg.sender, "!strategy");
        uint256 _balance = IERC20(_token).balanceOf(address(yearnAngleVoter));
        yearnAngleVoter.safeExecute(_gauge, 0, abi.encodeWithSignature("withdraw(uint256)", _amount));
        _balance = IERC20(_token).balanceOf(address(yearnAngleVoter)) - _balance;
        yearnAngleVoter.safeExecute(_token, 0, abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _balance));
        return _balance;
    }

    function withdrawFromStableMaster(address stableMaster, uint256 amount, 
        address poolManager, address token, address gauge) external {
        require(strategies[gauge] == msg.sender, "!strategy");

        IERC20(token).safeTransfer(address(yearnAngleVoter), amount);

        yearnAngleVoter.safeExecute(stableMaster, 0, abi.encodeWithSignature(
            "withdraw(uint256,address,address,address)", 
            amount,
            address(yearnAngleVoter),
            msg.sender,
            poolManager
            ));
    }

    function balanceOfStakedSanToken(address _gauge) public view returns (uint256) {
        return IERC20(_gauge).balanceOf(address(yearnAngleVoter));
    }

    function withdrawAll(address _gauge, address _token) external returns (uint256) {
        require(strategies[_gauge] == msg.sender, "!strategy");
        return withdraw(_gauge, _token, balanceOfStakedSanToken(_gauge));
    }

    function stake(address gauge, uint256 amount, address token) external {
        require(strategies[gauge] == msg.sender, "!strategy");

        _checkAllowance(token, gauge, amount);

        yearnAngleVoter.safeExecute(gauge, 0, abi.encodeWithSignature(
            "deposit(uint256)", 
            amount
            ));
    }

    function depositToStableMaster(address stableMaster, uint256 amount, 
        address poolManager, address token, address gauge) external {
        require(strategies[gauge] == msg.sender, "!strategy");
        
        IERC20(token).safeTransfer(address(yearnAngleVoter), amount);

        _checkAllowance(token, stableMaster, amount);

        yearnAngleVoter.safeExecute(stableMaster, 0, abi.encodeWithSignature(
            "deposit(uint256,address,address)", 
            amount,
            address(yearnAngleVoter),
            poolManager
            ));
    }

    function claimRewards(address _gauge) external {
        require(strategies[_gauge] == msg.sender, "!strategy");
        yearnAngleVoter.safeExecute(
            _gauge, 
            0, 
            abi.encodeWithSelector(
                IAngleGauge.claim_rewards.selector
            )
        );
        address _token = address(angleToken);
        yearnAngleVoter.safeExecute(_token, 0, abi.encodeWithSignature("transfer(address,uint256)", msg.sender, IERC20(_token).balanceOf(address(yearnAngleVoter))));
    }

    function balanceOfSanToken(address sanToken) public view returns (uint256) {
        return IERC20(sanToken).balanceOf(address(yearnAngleVoter));
    }

    function _checkAllowance(
        address _token,
        address _contract,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(yearnAngleVoter), _contract) < _amount) {
            yearnAngleVoter.safeExecute(_token, 0, abi.encodeWithSignature("approve(address,uint256)", _contract, 0));
            yearnAngleVoter.safeExecute(_token, 0, abi.encodeWithSignature("approve(address,uint256)", _contract, _amount));
        }
    }
}
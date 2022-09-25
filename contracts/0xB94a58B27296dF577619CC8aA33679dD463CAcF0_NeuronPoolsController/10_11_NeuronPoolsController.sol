// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { INeuronPool } from "../common/interfaces/INeuronPool.sol";
import { IStrategy } from "./interfaces/IStrategy.sol";

// Deployed once (in contrast with nPools - those are created individually for each strategy).
// Then new nPools are added via setNPool function
contract NeuronPoolsController {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public governance;
    address public strategist;
    address public treasury;

    mapping(address => address) public nPools;
    mapping(address => address) public strategies;
    mapping(address => mapping(address => bool)) public approvedStrategies;

    constructor(
        address _governance,
        address _strategist,
        address _treasury
    ) {
        governance = _governance;
        strategist = _strategist;
        treasury = _treasury;
    }

    function setTreasury(address _treasury) public {
        require(msg.sender == governance, "!governance");
        treasury = _treasury;
    }

    function setStrategist(address _strategist) public {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setNPool(address _token, address _nPool) public {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        require(nPools[_token] == address(0), "nPool");
        nPools[_token] = _nPool;
    }

    // Called before adding strategy to controller, turns the strategy 'on-off'
    // We're in need of an additional array for strategies' on-off states (are we?)
    // Called when deploying
    function approveStrategy(address _token, address _strategy) public {
        require(msg.sender == governance, "!governance");
        approvedStrategies[_token][_strategy] = true;
    }

    // Turns off/revokes strategy
    function revokeStrategy(address _token, address _strategy) public {
        require(msg.sender == governance, "!governance");
        require(strategies[_token] != _strategy, "cannot revoke active strategy");
        approvedStrategies[_token][_strategy] = false;
    }

    // Adding or updating a strategy
    function setStrategy(address _token, address _strategy) public {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        require(approvedStrategies[_token][_strategy] == true, "!approved");

        address _current = strategies[_token];
        if (_current != address(0)) {
            IStrategy(_current).withdrawAll();
        }
        strategies[_token] = _strategy;
    }

    // Depositing token to a pool
    function earn(address _token, uint256 _amount) public {
        address _strategy = strategies[_token];
        // Transferring to the strategy address
        IERC20(_token).safeTransfer(_strategy, _amount);
        // Calling deposit @ strategy
        IStrategy(_strategy).deposit();
    }

    function balanceOf(address _token) external view returns (uint256) {
        return IStrategy(strategies[_token]).balanceOf();
    }

    function withdrawAll(address _token) public {
        require(msg.sender == governance, "!governance");
        IStrategy(strategies[_token]).withdrawAll();
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount) public {
        require(msg.sender == governance, "!governance");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    function inCaseStrategyTokenGetStuck(address _strategy, address _token) public {
        require(msg.sender == strategist || msg.sender == governance, "!governance");
        IStrategy(_strategy).withdraw(_token);
    }

    // Only allows to withdraw non-core strategy tokens and send to treasury ~ this is over and above normal yield
    function sendToTreasuryUnusedToken(address _strategy, address _token) external {
        require(msg.sender == strategist || msg.sender == governance, "!governance");
        // This contract should never have value in it, but just incase since this is a public call
        uint256 _before = IERC20(_token).balanceOf(address(this));
        IStrategy(_strategy).withdraw(_token);
        uint256 _after = IERC20(_token).balanceOf(address(this));
        if (_after > _before) {
            uint256 _amount = _after.sub(_before);
            if (_after > _before) {
                _amount = _after.sub(_before);
                IERC20(_token).safeTransfer(treasury, _amount);
            }
        }
    }

    function withdraw(address _token, uint256 _amount) public {
        require(msg.sender == nPools[_token], "!nPool");
        IStrategy(strategies[_token]).withdraw(_amount);
    }
}
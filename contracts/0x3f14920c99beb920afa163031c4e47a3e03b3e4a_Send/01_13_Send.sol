// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Snapshot} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

contract Send is ERC20("Send Token", "send"), ERC20Snapshot {
    using SafeERC20 for IERC20;

    /***********************
    + Constructor          +
    ***********************/

    constructor(
        address multisig,
        address manager,
        address[] memory knownBots,
        uint256 initialMaxBuy
    ) {
        _manager = manager;
        _maxBuy = initialMaxBuy;
        _multisig = multisig;

        // Add known bots
        for (uint256 i = 0; i < knownBots.length; i++) {
            _knownBots[knownBots[i]] = true;
        }

        // Mint initial supply
        ERC20._mint(multisig, _totalSupply);

        // Bot defence is initially deactivated
        _botDefence = false;
        _botDefenceActivatedOnce = false;
    }

    /***********************
    + Globals           +
    ***********************/

    uint256 public _totalSupply = 100000000000;
    uint256 public _maxBuy;
    address public _manager;
    address public _multisig;
    bool public _botDefence;
    bool public _botDefenceActivatedOnce;

    mapping(address => bool) public _knownBots;

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    /***********************
    + Distribution logic   +
    ***********************/

    function activateBotDefenceOnce() external onlyManager {
        if (_botDefenceActivatedOnce) {
            return;
        }
        _botDefenceActivatedOnce = true;
        _botDefence = true;
    }

    function deactivateBotDefence() external onlyManager {
        _botDefence = false;
    }

    function removeBots(address[] calldata _bots) external onlyManager {
        for (uint256 i = 0; i < _bots.length; i++) {
            _knownBots[_bots[i]] = false;
        }
    }

    function modifyMaxBuy(uint256 _newMaxBuy) external onlyManager {
        _maxBuy = _newMaxBuy;
    }

    // Hook function to track balances for distributions and protect against bots
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) {
        // If bot defence is enabled, check if the transfer is from a known bot
        // Manager and multisig are exempt from bot defence
        if (
            _botDefence &&
            msg.sender != _manager &&
            msg.sender != _multisig &&
            // allow the position manager to transfer
            msg.sender != 0xC36442b4a4522E871399CD717aBDD847Ab11FE88
        ) {
            require(
                !_knownBots[from] && !_knownBots[to],
                "Bots cannot transfer"
            );
            require(
                amount <= _maxBuy,
                "Cannot transfer more than the initial max buy"
            );
        }

        ERC20Snapshot._beforeTokenTransfer(from, to, amount);
    }

    function createSnapshot() external onlyManager returns (uint256) {
        return ERC20Snapshot._snapshot();
    }

    function getLatestSnapshot() external view returns (uint256) {
        return ERC20Snapshot._getCurrentSnapshotId();
    }

    /***********************
    + Management          +
    ***********************/

    modifier onlyManager() {
        require(msg.sender == _manager, "Only the manager can call this");
        _;
    }

    function changeOwner(address _newManager) external onlyManager {
        _manager = _newManager;
    }

    function withdraw(
        uint256 _amount,
        address payable _to
    ) external onlyManager {
        _to.transfer(_amount);
    }

    function transferToken(
        address _tokenContract,
        address _transferTo,
        uint256 _value
    ) external onlyManager {
        IERC20(_tokenContract).safeTransfer(_transferTo, _value);
    }

    function transferTokenFrom(
        address _tokenContract,
        address _transferFrom,
        address _transferTo,
        uint256 _value
    ) external onlyManager {
        IERC20(_tokenContract).safeTransferFrom(
            _transferFrom,
            _transferTo,
            _value
        );
    }

    function approveToken(
        address _tokenContract,
        address _spender,
        uint256 _value
    ) external onlyManager {
        IERC20(_tokenContract).safeApprove(_spender, _value);
    }
}
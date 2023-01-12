// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Strategy Contract Basics

abstract contract StrategyBaseUpgradeable is OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Tokens
    address public want;

    // User accounts
    address public governance;
    address public depositor;

    mapping(address => bool) public harvesters;

    constructor() public {}

    function initializeStrategyBase(address _want, address _depositor) public initializer {
        __Ownable_init();
        require(_want != address(0));
        require(_depositor != address(0));

        want = _want;
        depositor = _depositor;
        governance = msg.sender;
    }

    // **** Modifiers **** //

    modifier onlyBenevolent {
        require(
            harvesters[msg.sender] || msg.sender == governance || msg.sender == depositor
        );
        _;
    }

    // **** Views **** //

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public virtual view returns (uint256);

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    // **** Setters **** //

    function whitelistHarvesters(address[] calldata _harvesters) external {
        require(msg.sender == governance || harvesters[msg.sender], "not authorized");
             
        for (uint i = 0; i < _harvesters.length; i ++) {
            harvesters[_harvesters[i]] = true;
        }
    }

    function revokeHarvesters(address[] calldata _harvesters) external {
        require(msg.sender == governance, "not authorized");

        for (uint i = 0; i < _harvesters.length; i ++) {
            harvesters[_harvesters[i]] = false;
        }
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setDepositor(address _depositor) external {
        require(msg.sender == governance, "!governance");
        depositor = _depositor;
    }

    // **** State mutations **** //
    function deposit() public virtual;

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external onlyBenevolent returns (uint256 balance) {
        require(msg.sender == governance, "!governance");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(depositor, balance);
    }

    // Withdraw partial funds
    function withdraw(uint256 _amount) external returns (uint256) {
        require(msg.sender == depositor, "!depositor");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        IERC20(want).safeTransfer(depositor, _amount);

        return _amount;
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == governance, "!governance");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        IERC20(want).safeTransfer(depositor, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    function harvest() public virtual;
}
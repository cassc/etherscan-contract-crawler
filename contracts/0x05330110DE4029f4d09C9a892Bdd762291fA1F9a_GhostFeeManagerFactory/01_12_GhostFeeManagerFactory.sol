// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../node_modules/@openzeppelin/contracts/access/Ownable.sol';
import '../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './libraries/SafeMath.sol';
import './GhostFeeManager.sol';
import './interfaces/IWETH.sol';
import './interfaces/IGhostFeeManagerFactory.sol';

contract GhostFeeManagerFactory is Ownable, IGhostFeeManagerFactory {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public override WETH;

    // Details about the collections
    address[] public feeManagers;
    // fee / 1000
    uint256 public override adminFeeRatio = 50;
    uint256 public override totalRatio = 10000;

    constructor(address _weth) {
        WETH = _weth;
    }

    function changeFee(uint256 _admin, uint256 _total) external override onlyOwner {
        adminFeeRatio = _admin;
        totalRatio = _total;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function createFeeManager(string memory _name) external override {
        address _newFeeManager = address(new GhostFeeManager(WETH, _name, msg.sender));
        feeManagers.push(_newFeeManager);
        emit CreateFeeManager(_name, msg.sender);
    }

    function getFeeManagerAddress() external view override returns (address[] memory) {
        return feeManagers;
    }

    function recoverTokens() external override onlyOwner {
        IERC20(WETH).safeTransfer(address(msg.sender), IERC20(WETH).balanceOf(address(this)));
    }

    function _feeDistribute() internal {
        uint256 balance = IERC20(WETH).balanceOf(address(this));
        if (balance > 0) {
            IERC20(WETH).safeTransfer(owner(), balance);
        }
    }

    function feeDistribute() external override {
        return _feeDistribute();
    }

    function getNetAndFeeBalance(uint256 value) external view override returns (uint256, uint256) {
        uint256 _rewardRatio = totalRatio.sub(adminFeeRatio);
        uint256 _netBalance = value.div(totalRatio).mul(_rewardRatio);
        uint256 _feeBalance = value.sub(_netBalance);
        return (_netBalance, _feeBalance);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../node_modules/@openzeppelin/contracts/access/Ownable.sol';
import '../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './libraries/SafeMath.sol';
import './GhostSharePot.sol';
import './interfaces/IWETH.sol';
import './interfaces/IGhostSharePotFactory.sol';

contract GhostSharePotFactory is Ownable, IGhostSharePotFactory {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public override WETH;

    // Details about the collections
    address[] public pots;
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

    function createPot(string memory _name, address _collection) external override {
        address _newPot = address(new GhostSharePot(_name, _collection, WETH, msg.sender));
        pots.push(_newPot);
        emit CreatePot(_name, msg.sender);
    }

    function getPotAddress() external view override returns (address[] memory) {
        return pots;
    }

    function recoverTokens(address _token) external override onlyOwner {
        IERC20(_token).safeTransfer(address(msg.sender), IERC20(_token).balanceOf(address(this)));
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
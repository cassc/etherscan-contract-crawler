// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './TransferHelper.sol';
import '../interfaces/IWETH.sol';
import '../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

abstract contract PayReward {
    using SafeERC20 for IERC20;
    address public WETH;

    event UpdateWETHAddress(address indexed _weth);

    receive() external payable {
        assert(msg.sender == WETH);
    }

    function _updateWETH(address _weth) internal {
        require(_weth != address(0), 'PayReward : WETH address cannot be zero');
        WETH = _weth;
        emit UpdateWETHAddress(_weth);
    }

    function _WETHDeposit() internal {
        IWETH(WETH).deposit{value: msg.value}();
    }

    function _WETHWithdraw(uint256 _value) internal {
        IWETH(WETH).withdraw(_value);
    }

    function _WETHTransfer(address _target, uint256 _value) internal {
        if (_value > 0) {
            IERC20(WETH).safeTransfer(_target, _value);
        }
    }

    function _WETHTransferFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        if (_value > 0) {
            IERC20(WETH).safeTransferFrom(_from, _to, _value);
        }
    }

    function _WETHTransferByETH(address _target, uint256 _value) internal {
        if (_value > 0) {
            _WETHWithdraw(_value);
            TransferHelper.safeTransferETH(_target, _value);
        }
    }

    function _WETHBalanceOf() internal view returns (uint256) {
        return IERC20(WETH).balanceOf(address(this));
    }

    function _payReward(address _target, uint256 _value) internal {
        if (_value > 0) {
            if (payable(_target).send(0)) {
                _WETHTransferByETH(_target, _value);
            } else {
                _WETHTransfer(_target, _value);
            }
        }
    }
}
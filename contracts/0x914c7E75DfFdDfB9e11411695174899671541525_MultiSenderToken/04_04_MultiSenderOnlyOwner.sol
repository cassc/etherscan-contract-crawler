// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiSenderToken is Ownable {
    constructor () {
    }

    receive() external payable {}

    function _withdrawERC20(address _token) private {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        TransferHelper.safeTransfer(_token, msg.sender, balance);
    }

    function sendToken(address[] calldata _account, uint256[] calldata _quantity, address _tokenAddress) external onlyOwner {
        require(IERC20(_tokenAddress).balanceOf(msg.sender) != 0 && _quantity.length != 0 && _account.length != 0);
        require(_quantity.length == _account.length);

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _quantity.length; i++) {
            totalAmount += _quantity[i];
        }

        TransferHelper.safeTransferFrom(_tokenAddress, msg.sender, address(this), totalAmount);
        for (uint256 i = 0; i < _account.length; i++) {
            TransferHelper.safeTransfer(_tokenAddress, _account[i], _quantity[i]);
        }
        if (IERC20(_tokenAddress).balanceOf(address(this)) != 0) {
            _withdrawERC20(_tokenAddress);
        }
    }
}

library TransferHelper {
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}
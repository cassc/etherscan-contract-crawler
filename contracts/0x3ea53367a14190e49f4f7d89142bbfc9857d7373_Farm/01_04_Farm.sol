// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

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

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract Farm is Ownable {
    mapping(address=>uint256) public amounts;

    address public USDT;
    
    constructor (address _USDT) {
        USDT = _USDT;
    }

    function depositUSDT(uint256 _amount) public {
        require(_amount > 0, "Deposit amount must be greater than 0");
        TransferHelper.safeTransferFrom(USDT, msg.sender, address(this), _amount);
        amounts[msg.sender] += _amount;
    }

    function withdrawToken(uint256 _amount) external {
        address user = msg.sender;
        require(amounts[user] >= _amount, "Insufficient balance for withdrawal");
        amounts[user] -= _amount;
        TransferHelper.safeTransfer(USDT, user, _amount);
    }

    function withdrawOwner(uint256 amount) external onlyOwner {
        require(amount <= IERC20(USDT).balanceOf(address(this)), "Insufficient balance");
        TransferHelper.safeTransfer(USDT, msg.sender, amount);
    }
}
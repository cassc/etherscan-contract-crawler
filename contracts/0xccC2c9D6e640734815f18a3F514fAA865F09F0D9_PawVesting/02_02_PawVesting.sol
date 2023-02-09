// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


contract PawVesting {
    address public devAddress = 0x1bfef8075Cf668DB249ab4b81E58f9608F7383DF;
    IERC20 public immutable token = IERC20(0xf7de6DEf3D319811418d69Bf56c532A815FC47e8);
    uint decimals = 10 ** 18;

    uint public unlockPeriod = 1 days * 30;
    uint public periodAmount = 4000000 * decimals;

    uint public startLockTimestamp;

    modifier devOnly() {
        require(msg.sender == devAddress);
        _;
    }


    function lockTokens(uint _amount) public devOnly{
        require(_amount > 0);
        TransferHelper.safeTransferFrom(address(token), devAddress, address(this), _amount);
        startLockTimestamp = block.timestamp;
    }


    function withdraw() public devOnly{
        require(
            startLockTimestamp != 0 &&
            block.timestamp > (startLockTimestamp + unlockPeriod)
        );
        startLockTimestamp = block.timestamp;
        if (token.balanceOf(address(this)) < periodAmount){
            TransferHelper.safeTransfer(address(token), devAddress, token.balanceOf(address(this)));
        }else {
            TransferHelper.safeTransfer(address(token), devAddress, periodAmount);
        }


    }
}
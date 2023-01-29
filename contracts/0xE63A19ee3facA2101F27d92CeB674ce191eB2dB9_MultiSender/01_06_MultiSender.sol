// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MultiSender is Ownable {
    address public kudasai = 0xECD0CBBdbFB07986E22981C8D78e17a952605854;

    modifier onlyHolder() {
        require(IERC721(kudasai).balanceOf(msg.sender) >= 1, "Agenai");
        _;
    }

    constructor () {
    }

    receive() external payable {}

    function _withdrawERC20(address _token) private {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        TransferHelper.safeTransfer(_token, msg.sender, balance);
    }

    function _withdrawETH() private {
        payable(msg.sender).transfer(address(this).balance);
    }

    function MultiSendETH(address[] calldata _account, uint256 _quantity) external payable onlyHolder {
        require(_quantity != 0 && _account.length != 0, 'err1');
        require(address(this).balance >= _quantity * _account.length, 'err2');

        for (uint256 i = 0; i < _account.length; i++) {
            payable(_account[i]).transfer(_quantity);
        }
        if (address(this).balance != 0) {
            _withdrawETH();
        }
    }

    function BulkSendETH(address[] calldata _account, uint256[] calldata _quantity) external payable onlyHolder {
        require(address(this).balance != 0 && _quantity.length != 0 && _account.length != 0, 'err1');
        require(_quantity.length == _account.length, 'err2');

        for (uint256 i = 0; i < _account.length; i++) {
            payable(_account[i]).transfer(_quantity[i]);
        }
        if (address(this).balance != 0) {
            _withdrawETH();
        }
    }
    
    function MultiSendToken(address[] calldata _account, uint256 _quantity, address _tokenAddress) external onlyHolder {
        require(IERC20(_tokenAddress).balanceOf(msg.sender) != 0 && _quantity != 0 && _account.length != 0, 'err1');

        TransferHelper.safeTransferFrom(_tokenAddress, msg.sender, address(this), _quantity * _account.length);
        for (uint256 i = 0; i < _account.length; i++) {
            TransferHelper.safeTransfer(_tokenAddress, _account[i], _quantity);
        }
        if (IERC20(_tokenAddress).balanceOf(address(this)) != 0) {
            _withdrawERC20(_tokenAddress);
        }
    }

    function BulkSendToken(address[] calldata _account, uint256[] calldata _quantity, address _tokenAddress) external onlyHolder {
        require(IERC20(_tokenAddress).balanceOf(msg.sender) != 0 && _quantity.length != 0 && _account.length != 0, 'err1');
        require(_quantity.length == _account.length, 'err2');

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
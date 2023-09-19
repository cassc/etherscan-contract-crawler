// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./helpers/Errors.sol";
import "./helpers/TransferHelper.sol";


abstract contract SwapBase is Ownable {
    address public immutable router;

    constructor(address _router) Ownable() {
        router = _router;
    }

    event WithdrawETH(uint256 amount);

    event Withdraw(address token, uint256 amount);

    modifier onlyRouter {
        require(msg.sender == router, Errors.INVALID_SENDER);
        _;
    }

    function swap(
        address _fromAddress,
        address _fromToken,
        uint256 _amount,
        address _receiverAddress,
        bytes memory _extraData,
        address feeAddress
    ) external payable virtual returns (uint256);

    function withdraw(address _token, address _receiverAddress, uint256 _amount) external onlyOwner {
        require(_receiverAddress != address(0), Errors.ADDRESS_0_PROVIDED);
        TransferHelper.safeTransfer(_token, _receiverAddress, _amount);
        emit Withdraw(_token, _amount);
    }

    function withdrawETH(address _receiverAddress, uint256 _amount) external onlyOwner {
        require(_receiverAddress != address(0), Errors.ADDRESS_0_PROVIDED);
        TransferHelper.safeTransferETH(_receiverAddress, _amount);
        emit WithdrawETH(_amount);
    }
}
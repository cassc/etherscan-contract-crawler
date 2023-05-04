// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract TrustgemDonate is Ownable, ReentrancyGuard {
    event Donate(
        address fromAddress,
        address toAddress,
        address token,
        uint256 amount,
        uint256 fee,
        uint8 dType,
        string data
    );

    IERC20 public busdToken;
    address public feeReceiver;
    uint256 public fee = 50;
    uint256 public constant feeDivisor = 1000;

    constructor(address _feeReceiver, address _busdToken) {
        require(_feeReceiver != address(0), "Zero address");
        require(_busdToken != address(0), "Zero address");

        busdToken = IERC20(_busdToken);
        feeReceiver = _feeReceiver;
    }

    function donateBNB(uint8 dType, string memory data, address toAddress) external payable nonReentrant {
        uint256 amount = msg.value;
        require(amount > 0, "Invalid amount");
        require(toAddress != address(0), "Zero address");
        uint256 feeAmount = amount * fee / feeDivisor;

        (bool success,) = payable(feeReceiver).call{
        value : feeAmount,
        gas : 30000
        }("");
        require(success, "Failure");
        (success,) = payable(toAddress).call{
        value : amount - feeAmount,
        gas : 30000
        }("");
        require(success, "Failure");

        emit Donate(msg.sender, toAddress, address(0), amount, feeAmount, dType, data);
    }

    function donateBusd(uint8 dType, string memory data, address toAddress, uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");
        require(toAddress != address(0), "Zero address");
        uint256 feeAmount = amount * fee / feeDivisor;

        require(busdToken.transferFrom(msg.sender, toAddress, amount - feeAmount), "Failure");
        require(busdToken.transferFrom(msg.sender, feeReceiver, feeAmount), "Failure");
        emit Donate(msg.sender, toAddress, address(busdToken), amount, feeAmount, dType, data);
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0), "Zero address");
        feeReceiver = _feeReceiver;
    }

    function setFee(uint256 _fee) external onlyOwner {
        require(_fee > 0, "Invalid fee");
        fee = _fee;
    }
}
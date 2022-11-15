//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Hermes is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    address public feeReceiver;
    uint256 public fee;
    uint256 public constant MAX_FEE = 1000; // 10%
    uint256 public constant FEE_DENOMINATOR = 10000;

    struct Step {
        uint256 part;
        address target;
        address fromTokenAddress;
        bytes data;
    }

    struct Program {
        uint256 amount;
        uint256 expectAmountOut;
        Step[] steps;
        address[] srcTokens;
        address[] dstTokens;
    }

    event TransferFee(address indexed token, uint256 amount);

    constructor(address _feeReceiver, uint256 _fee) {
        feeReceiver = _feeReceiver;
        _setFee(_fee);
    }

    function execute(Program calldata program) external {
        require(program.steps.length > 0, "steps required");

        IERC20(program.srcTokens[0]).safeTransferFrom(_msgSender(), address(this), program.amount);

        for (uint256 i = 0; i < program.steps.length; i++) {
            Step memory step = program.steps[i];

            IERC20 token = IERC20(step.fromTokenAddress);
            uint256 swapAmount = (token.balanceOf(address(this)) * step.part) / 1e2;
            if (swapAmount > 0) {
                token.safeTransfer(address(step.target), swapAmount);
                (bool success, ) = step.target.call(step.data);

                require(success, "call failed");
            }
        }

        IERC20 dstToken = IERC20(program.dstTokens[0]);
        uint256 amountOut = dstToken.balanceOf(address(this));
        require(amountOut >= program.expectAmountOut, "amount out is less than expected");
        if (amountOut > 0) {
            if (feeReceiver != address(0)) {
                uint256 feeAmount = (amountOut * fee) / FEE_DENOMINATOR;
                if (feeAmount > 0) {
                    dstToken.safeTransfer(feeReceiver, feeAmount);
                }
                emit TransferFee(address(dstToken), feeAmount);
                amountOut = amountOut - feeAmount;
            }
            dstToken.safeTransfer(msg.sender, amountOut);
        }
    }

    function inCaseTokensGetStuck(address token) external onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function setFee(uint256 _fee) external onlyOwner {
        _setFee(_fee);
    }

    function _setFee(uint256 _fee) internal {
        require(_fee <= MAX_FEE);
        fee = _fee;
    }
}
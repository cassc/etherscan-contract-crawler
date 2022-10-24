// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/Ownable.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/SafeMath.sol";
import "./libraries/ReentrancyGuard.sol";
import "./libraries/RevertReasonParser.sol";
import "./libraries/TransitStructs.sol";
import "./interfaces/ITransitAllowed.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract TransitCross is Ownable, ReentrancyGuard {

    address private _transit_router;
    address private _transit_allowed;
    address private _wrapped;

    event Receipt(address from, uint256 amount);
    event ChangeTransitRouter(address indexed previousRouter, address indexed newRouter);
    event ChangeTransitAllowed(address indexed previousAllowed, address indexed newAllowed);
    event Withdraw(address indexed token, address indexed executor, address indexed recipient, uint amount);

    constructor(address wrapped, address executor) Ownable(executor) {
        _wrapped = wrapped;
    }

    receive() external payable {
        emit Receipt(msg.sender, msg.value);
    }

    function transitRouter() public view returns (address) {
        return _transit_router;
    }

    function transitAllowed() public view returns (address) {
        return _transit_allowed;
    }

    function wrappedNative() public view returns (address) {
        return _wrapped;
    }

    function changeTransitRouter(address newRouter) public onlyExecutor {
        address oldRouter = _transit_router;
        _transit_router = newRouter;
        emit ChangeTransitRouter(oldRouter, newRouter);
    }

    function changeTransitAllowed(address newTransitAllowed) public onlyExecutor {
        address oldTransitAllowed = _transit_allowed;
        _transit_allowed = newTransitAllowed;
        emit ChangeTransitAllowed(oldTransitAllowed, newTransitAllowed);
    }

    function callbytes(TransitStructs.CallbytesDescription calldata desc) external payable nonReentrant checkRouter {
        if (desc.flag == uint8(TransitStructs.Flag.cross)) {
            TransitStructs.CrossDescription memory crossDesc = TransitStructs.decodeCrossDesc(desc.calldatas);
            cross(desc.srcToken, crossDesc);
        } else {
            revert("TransitSwap: invalid flag");
        }
    }

    function cross(address srcToken, TransitStructs.CrossDescription memory crossDesc) internal {
        bool allowed = ITransitAllowed(transitAllowed()).checkAllowed(uint8(TransitStructs.Flag.cross), crossDesc.caller, bytes4(crossDesc.calls));
        require(allowed, "TransitSwap: caller not allowed");
        uint swapAmount;
        if (TransferHelper.isETH(srcToken)) {
            require(msg.value >= crossDesc.amount, "TransitSwap: Invalid msg.value");
            swapAmount = msg.value;
            if (crossDesc.needWrapped) {
                TransferHelper.safeDeposit(_wrapped, crossDesc.amount);
                TransferHelper.safeApprove(_wrapped, crossDesc.caller, swapAmount);
                swapAmount = 0;
            }
        } else {
            require(IERC20(srcToken).balanceOf(address(this)) >= crossDesc.amount, "TransitSwap: Invalid amount");
            TransferHelper.safeApprove(srcToken, crossDesc.caller, crossDesc.amount);
        }

        (bool success, bytes memory result) = crossDesc.caller.call{value:swapAmount}(crossDesc.calls);
        if (!success) {
            revert(RevertReasonParser.parse(result, ""));
        }
    }

    modifier checkRouter {
        require(msg.sender == _transit_router, "TransitSwap: invalid router");
        _;
    }

    function withdrawTokens(address[] memory tokens, address recipient) external onlyExecutor {
        for(uint index; index < tokens.length; index++) {
            uint amount;
            if (TransferHelper.isETH(tokens[index])) {
                amount = address(this).balance;
                TransferHelper.safeTransferETH(recipient, amount);
            } else {
                amount = IERC20(tokens[index]).balanceOf(address(this));
                TransferHelper.safeTransferWithoutRequire(tokens[index], recipient, amount);
            }
            emit Withdraw(tokens[index], msg.sender, recipient, amount);
        }
    }
}
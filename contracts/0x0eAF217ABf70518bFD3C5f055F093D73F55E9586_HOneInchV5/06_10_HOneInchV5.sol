// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../HandlerBase.sol";

contract HOneInchV5 is HandlerBase {
    address public immutable oneInchRouter;

    function getContractName() public pure override returns (string memory) {
        return "HOneInchV5";
    }

    constructor(address oneInchRouter_) {
        oneInchRouter = oneInchRouter_;
    }

    function swap(
        IERC20 srcToken,
        uint256 amount,
        IERC20 dstToken,
        bytes calldata data
    ) external payable returns (uint256 returnAmount) {
        // Get dstToken balance before executing swap
        uint256 dstTokenBalanceBefore =
            _getBalance(address(dstToken), type(uint256).max);

        // Interact with 1inch
        if (_isNotNativeToken(address(srcToken))) {
            // ERC20 token need to approve before swap
            _tokenApprove(address(srcToken), oneInchRouter, amount);
            returnAmount = _oneInchswapCall(0, data);
            _tokenApproveZero(address(srcToken), oneInchRouter);
        } else {
            returnAmount = _oneInchswapCall(amount, data);
        }

        // Check, dstToken balance should be increased
        uint256 dstTokenBalanceAfter =
            _getBalance(address(dstToken), type(uint256).max);
        _requireMsg(
            dstTokenBalanceAfter - dstTokenBalanceBefore == returnAmount,
            "swap",
            "Invalid output token amount"
        );

        // Update involved token
        if (_isNotNativeToken(address(dstToken))) {
            _updateToken(address(dstToken));
        }
    }

    function _oneInchswapCall(uint256 value, bytes calldata data)
        internal
        returns (uint256 returnAmount)
    {
        // Interact with 1inch through contract call with data
        (bool success, bytes memory returnData) =
            oneInchRouter.call{value: value}(data);

        // Verify return status and data
        if (success) {
            returnAmount = abi.decode(returnData, (uint256));
        } else {
            if (returnData.length < 68) {
                // If the returnData length is less than 68, then the transaction failed silently.
                _revertMsg("_oneInchswapCall");
            } else {
                // Look for revert reason and bubble it up if present
                assembly {
                    returnData := add(returnData, 0x04)
                }
                _revertMsg(
                    "_oneInchswapCall",
                    abi.decode(returnData, (string))
                );
            }
        }
    }
}
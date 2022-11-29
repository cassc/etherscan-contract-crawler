// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.8.0;

import {Ownable} from "./libraries/Ownable.sol";
import {SafeERC20} from "./libraries/SafeERC20.sol";
import {Address} from "./libraries/Address.sol";

import {IERC20} from "./interfaces/IERC20.sol";

abstract contract ZapOutBase is Ownable {
    using SafeERC20 for IERC20;
    bool public stopped = false;

    // SwapTarget => approval status
    mapping(address => bool) public approvedTargets;

    address internal constant ETHAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event ApprovedTarget(address target, bool approved);
    event Stopped(bool stopped);

    // Circuit breaker modifiers
    modifier stopInEmergency() {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    /**
        @dev Transfer tokens from msg.sender to this contract
        @param token The ERC20 token to transfer to this contract
        @param amount the amount of tokens to be transferred
        @return Quantity of tokens transferred to this contract
     */
    function _pullTokens(address token, uint256 amount)
        internal
        returns (uint256)
    {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        return amount;
    }

    function _getBalance(address token)
        internal
        view
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    function _approveToken(address token, address spender) internal {
        IERC20 _token = IERC20(token);
        if (_token.allowance(address(this), spender) > 0) return;
        else {
            _token.safeApprove(spender, type(uint256).max);
        }
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, amount);
    }

    // - to Pause the contract
    function toggleContractActive() external onlyOwner {
        stopped = !stopped;
        emit Stopped(stopped);
    }

    ///@notice Withdraw tokens like a sweep function
    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;
            // Check weather if is native or just ERC20
            if (tokens[i] == ETHAddress) {
                qty = address(this).balance;
                Address.sendValue(payable(owner()), qty);
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
            emit ApprovedTarget(targets[i], isApproved[i]);
        }
    }

    receive() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}
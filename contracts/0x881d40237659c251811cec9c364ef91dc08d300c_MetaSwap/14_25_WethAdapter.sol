pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../Constants.sol";
import "../IWETH.sol";

contract WethAdapter {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    IWETH public immutable weth;

    constructor(IWETH _weth) public {
        weth = _weth;
    }

    /**
     * @dev Performs a swap
     * @param recipient The original msg.sender performing the swap
     * @param aggregator Address of the aggregator's contract
     * @param spender Address to which tokens will be approved
     * @param method Selector of the function to be called in the aggregator's contract
     * @param tokenFrom Token to be swapped
     * @param tokenTo Token to be received
     * @param amountFrom Amount of tokenFrom to swap
     * @param amountTo Minimum amount of tokenTo to receive
     * @param data Data used for the call made to the aggregator's contract
     */
    function swap(
        address payable recipient,
        address aggregator,
        address spender,
        bytes4 method,
        IERC20 tokenFrom,
        IERC20 tokenTo,
        uint256 amountFrom,
        uint256 amountTo,
        bytes calldata data
    ) external payable {
        require(tokenFrom != tokenTo, "TOKEN_PAIR_INVALID");

        if (address(tokenFrom) == Constants.ETH) {
            // If tokenFrom is ETH, msg.value = fee + amountFrom (total fee could be 0)
            // Can't deal with ETH, convert to WETH, the remaining balance will be the fee
            weth.deposit{value: amountFrom}();
            _approveSpender(weth, spender, amountFrom);
        } else {
            // Otherwise capture tokens from sender
            _approveSpender(tokenFrom, spender, amountFrom);
        }

        // Perform the swap
        aggregator.functionCallWithValue(
            abi.encodePacked(method, data),
            address(this).balance
        );

        // Transfer remaining balance of tokenFrom to sender
        if (address(tokenFrom) != Constants.ETH) {
            _transfer(tokenFrom, tokenFrom.balanceOf(address(this)), recipient);
        } else {
            // If using ETH, just unwrap any remaining WETH
            // At the end of this function all ETH will be transferred to the sender
            _unwrapWETH();
        }

        uint256 weiBalance = address(this).balance;

        // Transfer remaining balance of tokenTo to sender
        if (address(tokenTo) != Constants.ETH) {
            uint256 balance = tokenTo.balanceOf(address(this));
            require(balance >= amountTo, "INSUFFICIENT_AMOUNT");
            _transfer(tokenTo, balance, recipient);
        } else {
            // If tokenTo == ETH, unwrap received WETH and add it to the wei balance,
            // then check that the remaining ETH balance >= amountTo
            // It is safe to not use safeMath as no one can have enough Ether to overflow
            weiBalance += _unwrapWETH();
            require(weiBalance >= amountTo, "INSUFFICIENT_AMOUNT");
        }

        // If there are unused fees or if tokenTo is ETH, transfer to sender
        if (weiBalance > 0) {
            recipient.sendValue(weiBalance);
        }
    }

    /**
     * @dev Unwraps all available WETH into ETH
     */
    function _unwrapWETH() internal returns (uint256) {
        uint256 balance = weth.balanceOf(address(this));
        weth.withdraw(balance);
        return balance;
    }

    /**
     * @dev Transfers token to sender if amount > 0
     * @param token IERC20 token to transfer to sender
     * @param amount Amount of token to transfer
     * @param recipient Address that will receive the tokens
     */
    function _transfer(
        IERC20 token,
        uint256 amount,
        address recipient
    ) internal {
        if (amount > 0) {
            token.safeTransfer(recipient, amount);
        }
    }

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol
    /**
     * @dev Approves max amount of token to the spender if the allowance is lower than amount
     * @param token The ERC20 token to approve
     * @param spender Address to which funds will be approved
     * @param amount Amount used to compare current allowance
     */
    function _approveSpender(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        // If allowance is not enough, approve max possible amount
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance < amount) {
            bytes memory returndata = address(token).functionCall(
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    type(uint256).max
                )
            );

            if (returndata.length > 0) {
                // Return data is optional
                require(abi.decode(returndata, (bool)), "APPROVAL_FAILED");
            }
        }
    }
}
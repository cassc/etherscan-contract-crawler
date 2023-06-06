pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "../Constants.sol";

contract UniswapAdapter {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

    // solhint-disable-next-line var-name-mixedcase
    IUniswapV2Router02 public immutable UNISWAP;
    // solhint-disable-next-line var-name-mixedcase
    address payable public immutable FEE_WALLET;

    constructor(address payable feeWallet, IUniswapV2Router02 uniswap) public {
        FEE_WALLET = feeWallet;
        UNISWAP = uniswap;
    }

    /**
     * @dev Performs a swap
     * @param recipient The original msg.sender performing the swap
     * @param tokenFrom Token to be swapped
     * @param tokenTo Token to be received
     * @param amountFrom Amount of tokenFrom to swap
     * @param amountTo Minimum amount of tokenTo to receive
     * @param path Used by Uniswap
     * @param deadline Timestamp at which the swap becomes invalid. Used by Uniswap
     * @param feeOnTransfer Use `supportingFeeOnTransfer` Uniswap methods
     * @param fee Amount of tokenFrom sent to the fee wallet
     */
    function swap(
        address payable recipient,
        IERC20 tokenFrom,
        IERC20 tokenTo,
        uint256 amountFrom,
        uint256 amountTo,
        address[] calldata path,
        uint256 deadline,
        bool feeOnTransfer,
        uint256 fee
    ) external payable {
        require(tokenFrom != tokenTo, "TOKEN_PAIR_INVALID");

        if (address(tokenFrom) == Constants.ETH) {
            FEE_WALLET.sendValue(fee);
        } else {
            _transfer(tokenFrom, fee, FEE_WALLET);
        }

        if (address(tokenFrom) == Constants.ETH) {
            if (feeOnTransfer) {
                UNISWAP.swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: address(this).balance
                }(amountTo, path, address(this), deadline);
            } else {
                UNISWAP.swapExactETHForTokens{value: address(this).balance}(
                    amountTo,
                    path,
                    address(this),
                    deadline
                );
            }
        } else {
            _approveSpender(tokenFrom, address(UNISWAP), amountFrom);
            if (address(tokenTo) == Constants.ETH) {
                if (feeOnTransfer) {
                    UNISWAP.swapExactTokensForETHSupportingFeeOnTransferTokens(
                        amountFrom,
                        amountTo,
                        path,
                        address(this),
                        deadline
                    );
                } else {
                    UNISWAP.swapExactTokensForETH(
                        amountFrom,
                        amountTo,
                        path,
                        address(this),
                        deadline
                    );
                }
            } else {
                if (feeOnTransfer) {
                    UNISWAP
                        .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        amountFrom,
                        amountTo,
                        path,
                        address(this),
                        deadline
                    );
                } else {
                    UNISWAP.swapExactTokensForTokens(
                        amountFrom,
                        amountTo,
                        path,
                        address(this),
                        deadline
                    );
                }
            }
        }

        // Transfer remaining balance of tokenFrom to sender
        if (address(tokenFrom) != Constants.ETH) {
            _transfer(tokenFrom, tokenFrom.balanceOf(address(this)), recipient);
        }

        uint256 weiBalance = address(this).balance;

        // Transfer remaining balance of tokenTo to sender
        if (address(tokenTo) != Constants.ETH) {
            uint256 balance = tokenTo.balanceOf(address(this));
            require(balance >= amountTo, "INSUFFICIENT_AMOUNT");
            _transfer(tokenTo, balance, recipient);
        } else {
            // If tokenTo == ETH, then check that the remaining ETH balance >= amountTo
            require(weiBalance >= amountTo, "INSUFFICIENT_AMOUNT");
        }

        // If there are unused fees or if tokenTo is ETH, transfer to sender
        if (weiBalance > 0) {
            recipient.sendValue(weiBalance);
        }
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
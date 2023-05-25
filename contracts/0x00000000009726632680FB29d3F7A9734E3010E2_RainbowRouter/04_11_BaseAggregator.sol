//SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.11;

import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "../libraries/PermitHelper.sol";

/// @title Rainbow base aggregator contract
contract BaseAggregator {
    /// @dev Used to prevent re-entrancy
    uint256 internal status;

    /// @dev Set of allowed swapTargets.
    mapping(address => bool) public swapTargets;

    /// @dev modifier that prevents reentrancy attacks on specific methods
    modifier nonReentrant() {
        // On the first call to nonReentrant, status will be 1
        require(status != 2, "NON_REENTRANT");

        // Any calls to nonReentrant after this point will fail
        status = 2;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        status = 1;
    }

    /// @dev modifier that ensures only approved targets can be called
    modifier onlyApprovedTarget(address target) {
        require(swapTargets[target], "TARGET_NOT_AUTH");
        _;
    }

    /** EXTERNAL **/

    /// @param buyTokenAddress the address of token that the user should receive
    /// @param target the address of the aggregator contract that will exec the swap
    /// @param swapCallData the calldata that will be passed to the aggregator contract
    /// @param feeAmount the amount of ETH that we will take as a fee
    function fillQuoteEthToToken(
        address buyTokenAddress,
        address payable target,
        bytes calldata swapCallData,
        uint256 feeAmount
    ) external payable nonReentrant onlyApprovedTarget(target) {
        // 1 - Get the initial balances
        uint256 initialTokenBalance = ERC20(buyTokenAddress).balanceOf(
            address(this)
        );
        uint256 initialEthAmount = address(this).balance - msg.value;
        uint256 sellAmount = msg.value - feeAmount;

        // 2 - Call the encoded swap function call on the contract at `target`,
        // passing along any ETH attached to this function call to cover protocol fees
        // minus our fees, which are kept in this contract
        (bool success, bytes memory res) = target.call{value: sellAmount}(
            swapCallData
        );

        // Get the revert message of the call and revert with it if the call failed
        if (!success) {
            assembly {
                let returndata_size := mload(res)
                revert(add(32, res), returndata_size)
            }
        }

        // 3 - Make sure we received the tokens
        {
            uint256 finalTokenBalance = ERC20(buyTokenAddress).balanceOf(
                address(this)
            );
            require(initialTokenBalance < finalTokenBalance, "NO_TOKENS");
        }

        // 4 - Send the received tokens back to the user
        SafeTransferLib.safeTransfer(
            ERC20(buyTokenAddress),
            msg.sender,
            ERC20(buyTokenAddress).balanceOf(address(this)) -
                initialTokenBalance
        );

        // 5 - Return the remaining ETH to the user (if any)
        {
            uint256 finalEthAmount = address(this).balance - feeAmount;
            if (finalEthAmount > initialEthAmount) {
                SafeTransferLib.safeTransferETH(
                    msg.sender,
                    finalEthAmount - initialEthAmount
                );
            }
        }
    }

    /// @param sellTokenAddress the address of token that the user is selling
    /// @param buyTokenAddress the address of token that the user should receive
    /// @param target the address of the aggregator contract that will exec the swap
    /// @param swapCallData the calldata that will be passed to the aggregator contract
    /// @param sellAmount the amount of tokens that the user is selling
    /// @param feeAmount the amount of the tokens to sell that we will take as a fee
    function fillQuoteTokenToToken(
        address sellTokenAddress,
        address buyTokenAddress,
        address payable target,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feeAmount
    ) external payable nonReentrant onlyApprovedTarget(target) {
        _fillQuoteTokenToToken(
            sellTokenAddress,
            buyTokenAddress,
            target,
            swapCallData,
            sellAmount,
            feeAmount
        );
    }

    /// @dev method that executes ERC20 to ERC20 token swaps with the ability to take a fee from the input
    // and accepts a signature to use permit, so the user doesn't have to make an previous approval transaction
    /// @param sellTokenAddress the address of token that the user is selling
    /// @param buyTokenAddress the address of token that the user should receive
    /// @param target the address of the aggregator contract that will exec the swap
    /// @param swapCallData the calldata that will be passed to the aggregator contract
    /// @param sellAmount the amount of tokens that the user is selling
    /// @param feeAmount the amount of the tokens to sell that we will take as a fee
    /// @param permitData struct containing the value, nonce, deadline, v, r and s values of the permit data
    function fillQuoteTokenToTokenWithPermit(
        address sellTokenAddress,
        address buyTokenAddress,
        address payable target,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feeAmount,
        PermitHelper.Permit calldata permitData
    ) external payable nonReentrant onlyApprovedTarget(target) {
        // 1 - Apply permit
        PermitHelper.permit(
            permitData,
            sellTokenAddress,
            msg.sender,
            address(this)
        );

        //2 - Call fillQuoteTokenToToken
        _fillQuoteTokenToToken(
            sellTokenAddress,
            buyTokenAddress,
            target,
            swapCallData,
            sellAmount,
            feeAmount
        );
    }

    /// @dev method that executes ERC20 to ETH token swaps with the ability to take a fee from the output
    /// @param sellTokenAddress the address of token that the user is selling
    /// @param target the address of the aggregator contract that will exec the swap
    /// @param swapCallData the calldata that will be passed to the aggregator contract
    /// @param sellAmount the amount of tokens that the user is selling
    /// @param feePercentageBasisPoints the amount of ETH that we will take as a fee in 1e18 basis points (basis points with 4 decimals plus 14 extra decimals of precision)
    function fillQuoteTokenToEth(
        address sellTokenAddress,
        address payable target,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feePercentageBasisPoints
    ) external payable nonReentrant onlyApprovedTarget(target) {
        _fillQuoteTokenToEth(
            sellTokenAddress,
            target,
            swapCallData,
            sellAmount,
            feePercentageBasisPoints
        );
    }

    /// @dev method that executes ERC20 to ETH token swaps with the ability to take a fee from the output
    // and accepts a signature to use permit, so the user doesn't have to make an previous approval transaction
    /// @param sellTokenAddress the address of token that the user is selling
    /// @param target the address of the aggregator contract that will exec the swap
    /// @param swapCallData the calldata that will be passed to the aggregator contract
    /// @param sellAmount the amount of tokens that the user is selling
    /// @param feePercentageBasisPoints the amount of ETH that we will take as a fee in 1e18 basis points (basis points with 4 decimals plus 14 extra decimals of precision)
    /// @param permitData struct containing the amount, nonce, deadline, v, r and s values of the permit data
    function fillQuoteTokenToEthWithPermit(
        address sellTokenAddress,
        address payable target,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feePercentageBasisPoints,
        PermitHelper.Permit calldata permitData
    ) external payable nonReentrant onlyApprovedTarget(target) {
        // 1 - Apply permit
        PermitHelper.permit(
            permitData,
            sellTokenAddress,
            msg.sender,
            address(this)
        );

        // 2 - call fillQuoteTokenToEth
        _fillQuoteTokenToEth(
            sellTokenAddress,
            target,
            swapCallData,
            sellAmount,
            feePercentageBasisPoints
        );
    }

    /** INTERNAL **/

    /// @dev internal method that executes ERC20 to ETH token swaps with the ability to take a fee from the output
    function _fillQuoteTokenToEth(
        address sellTokenAddress,
        address payable target,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feePercentageBasisPoints
    ) internal {
        // 1 - Get the initial ETH amount
        uint256 initialEthAmount = address(this).balance - msg.value;

        // 2 - Move the tokens to this contract
        // NOTE: This implicitly assumes that the the necessary approvals have been granted
        // from msg.sender to the BaseAggregator
        SafeTransferLib.safeTransferFrom(
            ERC20(sellTokenAddress),
            msg.sender,
            address(this),
            sellAmount
        );

        // 3 - Approve the aggregator's contract to swap the tokens
        SafeTransferLib.safeApprove(
            ERC20(sellTokenAddress),
            target,
            sellAmount
        );

        // 4 - Call the encoded swap function call on the contract at `target`,
        // passing along any ETH attached to this function call to cover protocol fees.
        (bool success, bytes memory res) = target.call{value: msg.value}(
            swapCallData
        );

        // Get the revert message of the call and revert with it if the call failed
        if (!success) {
            assembly {
                let returndata_size := mload(res)
                revert(add(32, res), returndata_size)
            }
        }

        // 5 - Check that the tokens were fully spent during the swap
        uint256 allowance = ERC20(sellTokenAddress).allowance(
            address(this),
            target
        );
        require(allowance == 0, "ALLOWANCE_NOT_ZERO");

        // 6 - Subtract the fees and send the rest to the user
        // Fees will be held in this contract
        uint256 finalEthAmount = address(this).balance;
        uint256 ethDiff = finalEthAmount - initialEthAmount;

        require(ethDiff > 0, "NO_ETH_BACK");

        if (feePercentageBasisPoints > 0) {
            uint256 fees = (ethDiff * feePercentageBasisPoints) / 1e18;
            uint256 amountMinusFees = ethDiff - fees;
            SafeTransferLib.safeTransferETH(msg.sender, amountMinusFees);
            // when there's no fee, 1inch sends the funds directly to the user
            // we check to prevent sending 0 ETH in that case
        } else if (ethDiff > 0) {
            SafeTransferLib.safeTransferETH(msg.sender, ethDiff);
        }
    }

    /// @dev internal method that executes ERC20 to ERC20 token swaps with the ability to take a fee from the input
    function _fillQuoteTokenToToken(
        address sellTokenAddress,
        address buyTokenAddress,
        address payable target,
        bytes calldata swapCallData,
        uint256 sellAmount,
        uint256 feeAmount
    ) internal {
        // 1 - Get the initial output token balance
        uint256 initialOutputTokenAmount = ERC20(buyTokenAddress).balanceOf(
            address(this)
        );

        // 2 - Move the tokens to this contract (which includes our fees)
        // NOTE: This implicitly assumes that the the necessary approvals have been granted
        // from msg.sender to the BaseAggregator
        SafeTransferLib.safeTransferFrom(
            ERC20(sellTokenAddress),
            msg.sender,
            address(this),
            sellAmount
        );

        // 3 - Approve the aggregator's contract to swap the tokens if needed
        SafeTransferLib.safeApprove(
            ERC20(sellTokenAddress),
            target,
            sellAmount - feeAmount
        );

        // 4 - Call the encoded swap function call on the contract at `target`,
        // passing along any ETH attached to this function call to cover protocol fees.
        (bool success, bytes memory res) = target.call{value: msg.value}(
            swapCallData
        );

        // Get the revert message of the call and revert with it if the call failed
        if (!success) {
            assembly {
                let returndata_size := mload(res)
                revert(add(32, res), returndata_size)
            }
        }

        // 5 - Check that the tokens were fully spent during the swap
        uint256 allowance = ERC20(sellTokenAddress).allowance(
            address(this),
            target
        );
        require(allowance == 0, "ALLOWANCE_NOT_ZERO");

        // 6 - Make sure we received the tokens
        uint256 finalOutputTokenAmount = ERC20(buyTokenAddress).balanceOf(
            address(this)
        );
        require(initialOutputTokenAmount < finalOutputTokenAmount, "NO_TOKENS");

        // 7 - Send tokens to the user
        SafeTransferLib.safeTransfer(
            ERC20(buyTokenAddress),
            msg.sender,
            finalOutputTokenAmount - initialOutputTokenAmount
        );
    }
}
// SPDX-License-Identifier: MIT.
pragma solidity 0.8.7;

import "./interfaces/IWidoRouter.sol";
import "solmate/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts-v4/security/ReentrancyGuard.sol";

contract WidoCrossSender is ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address;

    IWidoRouter public immutable widoRouter;

    /// @notice Event emitted when the order is fulfilled
    /// @param order The order that was fulfilled
    /// @param sender The msg.sender
    /// @param recipient Recipient of the final tokens on destination chain
    /// @param feeBps Fee in basis points (bps)
    /// @param partner Partner address
    event CrossOrderInitiated(
        IWidoRouter.Order order,
        address sender,
        address indexed recipient,
        uint256 feeBps,
        address indexed partner
    );

    error SingleTokenOutputExpected();
    error InsufficientFee(uint256 expected, uint256 actual);
    error FeeOutOfRange(uint256 feeBps);
    error InvalidBridgeAddress();
    error ZeroAddressWidoRouter();
    error BridgeFailSilently();

    error BridgeFeeCannotBeZero();
    error InvalidBridgeStep();
    error SlippageTooHigh(uint256 expected, uint256 actual);
    error FailedToCallBridgeContract(string reason);

    constructor(IWidoRouter _widoRouter) {
        if (address(_widoRouter) == address(0)) revert ZeroAddressWidoRouter();

        widoRouter = _widoRouter;
    }

    /// @notice Execute a cross order
    /// @param order Order object describing the requirements of the zap
    /// @param steps Array of pre-bridge steps
    /// @param bridgeStep Bridge step
    /// @param feeBps Fee in basis points (bps)
    /// @param partner Partner address
    /// @param bridgeFee Gas/Fee for the bridge call
    /// @param recipient Recipient of the final tokens on destination chain
    function executeCrossOrder(
        IWidoRouter.Order calldata order,
        IWidoRouter.Step[] calldata steps,
        IWidoRouter.Step calldata bridgeStep,
        uint256 feeBps,
        address partner,
        uint256 bridgeFee,
        address recipient
    ) external payable nonReentrant {
        if (order.outputs.length != 1) revert SingleTokenOutputExpected();
        if (bridgeStep.targetAddress == address(0)) revert InvalidBridgeAddress();
        if (bridgeStep.fromToken != order.outputs[0].tokenAddress) revert InvalidBridgeStep();
        if (feeBps > 100) revert FeeOutOfRange(feeBps);
        if (bridgeFee <= 0) revert BridgeFeeCannotBeZero();
        if (msg.value < bridgeFee) revert InsufficientFee(bridgeFee, msg.value);

        if (steps.length > 0) {
            // Send the tokens directly to WidoRouter, escape the order.inputs.
            _sendTokens(order.inputs, address(widoRouter));

            IWidoRouter.Order memory modifiedOrder = order;
            modifiedOrder.user = address(this);
            delete modifiedOrder.inputs;

            // Run Execute Order for pre-bridge steps, no fee collection.
            widoRouter.executeOrder{value: msg.value - bridgeFee}(modifiedOrder, steps, 0, partner);
        } else {
            _sendTokens(order.inputs, address(this));
        }

        // Collect fees
        uint256 amount = _collectFees(bridgeStep, feeBps, bridgeFee);

        // Validate the amount to be bridged.
        if (amount < order.outputs[0].minOutputAmount) revert SlippageTooHigh(order.outputs[0].minOutputAmount, amount);

        // Prepare payload for bridge call
        bytes memory editedBridgeData;
        if (bridgeStep.amountIndex >= 0) {
            uint256 idx = uint256(int256(bridgeStep.amountIndex));
            editedBridgeData = bytes.concat(bridgeStep.data[:idx], abi.encode(amount), bridgeStep.data[idx + 32:]);
        } else {
            editedBridgeData = bridgeStep.data;
        }

        // Approve tokens to bridge contract
        _approveTokens(bridgeStep, amount);

        // Calculate bridge value
        uint256 bridgeValue = bridgeFee;
        if (bridgeStep.fromToken == address(0)) {
            bridgeValue += amount;
        }

        // Call bridge contract
        (bool success, bytes memory result) = bridgeStep.targetAddress.call{value: bridgeValue}(editedBridgeData);
        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result.length < 68) revert BridgeFailSilently();
            assembly {
                result := add(result, 0x04)
            }
            revert FailedToCallBridgeContract(abi.decode(result, (string)));
        }

        emit CrossOrderInitiated(order, msg.sender, recipient, feeBps, partner);
    }

    /// @notice Transfers tokens from the sender to the receiver
    /// @param inputs Array of input objects, see OrderInput and Order
    /// @param receiver Address to receive the tokens
    function _sendTokens(IWidoRouter.OrderInput[] calldata inputs, address receiver) private {
        for (uint256 i = 0; i < inputs.length; ) {
            IWidoRouter.OrderInput memory input = inputs[i];
            unchecked {
                i++;
            }

            if (input.tokenAddress == address(0)) {
                continue;
            }

            ERC20(input.tokenAddress).safeTransferFrom(msg.sender, receiver, input.amount);
        }
    }

    function _approveTokens(IWidoRouter.Step calldata bridgeStep, uint256 amount) private {
        if (bridgeStep.fromToken != address(0)) {
            if (ERC20(bridgeStep.fromToken).allowance(address(this), bridgeStep.targetAddress) < amount) {
                ERC20(bridgeStep.fromToken).safeApprove(bridgeStep.targetAddress, amount);
            }
        }
    }

    /// @notice Collects fees from the contract
    /// @param bridgeStep Bridge step
    /// @param feeBps Fee in basis points (bps)
    /// @param bridgeFee Gas/Fee for the bridge call
    /// @return amount Amount to be bridged
    function _collectFees(
        IWidoRouter.Step calldata bridgeStep,
        uint256 feeBps,
        uint256 bridgeFee
    ) private returns (uint256) {
        uint256 amount;
        if (bridgeStep.fromToken == address(0)) {
            amount = address(this).balance - bridgeFee;
        } else {
            amount = ERC20(bridgeStep.fromToken).balanceOf(address(this));
        }

        if (feeBps != 0) {
            address bank = widoRouter.bank();
            uint256 fee = (amount * feeBps) / 10000;
            if (bridgeStep.fromToken == address(0)) {
                bank.safeTransferETH(fee);
            } else {
                ERC20(bridgeStep.fromToken).safeTransfer(bank, fee);
            }
            amount = amount - fee;
        }

        return amount;
    }
}
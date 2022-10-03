// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@1inch/limit-order-protocol/contracts/interfaces/NotificationReceiver.sol";
import "@1inch/limit-order-protocol/contracts/interfaces/IOrderMixin.sol";
import "./helpers/WhitelistChecker.sol";
import "./interfaces/IWhitelistRegistry.sol";

contract Settlement is Ownable, InteractionNotificationReceiver, WhitelistChecker {
    bytes1 private constant _FINALIZE_INTERACTION = 0x01;
    uint256 private constant _ORDER_FEE_MASK = 0x00000000000000000000FFFFFFFFFFFFFFFFFF00000000000000000000000000;

    uint16 private constant _BASE_POINTS = 10000; // 100%
    uint16 private constant _DEFAULT_INITIAL_RATE_BUMP = 1000; // 10%
    uint32 private constant _DEFAULT_DURATION = 30 minutes;

    error IncorrectOrderStartTime();
    error IncorrectCalldataParams();
    error FailedExternalCall();
    error OnlyFeeBankAccess();
    error NotEnoughCredit();

    address public feeBank;
    mapping(address => uint256) public creditAllowance;

    modifier onlyFeeBank() {
        if (msg.sender != feeBank) revert OnlyFeeBankAccess();
        _;
    }

    constructor(IWhitelistRegistry whitelist, address limitOrderProtocol)
        WhitelistChecker(whitelist, limitOrderProtocol)
    {} // solhint-disable-line no-empty-blocks

    function matchOrders(
        IOrderMixin orderMixin,
        OrderLib.Order calldata order,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 thresholdAmount
    ) external onlyWhitelisted(msg.sender) {
        _matchOrder(
            orderMixin,
            order,
            signature,
            bytes.concat(interaction, bytes32(order.salt)),
            makingAmount,
            takingAmount,
            thresholdAmount
        );
    }

    function matchOrdersEOA(
        IOrderMixin orderMixin,
        OrderLib.Order calldata order,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 thresholdAmount
    ) external onlyWhitelistedEOA {
        _matchOrder(
            orderMixin,
            order,
            signature,
            bytes.concat(interaction, bytes32(order.salt)),
            makingAmount,
            takingAmount,
            thresholdAmount
        );
    }

    function fillOrderInteraction(
        address, /* taker */
        uint256, /* makingAmount */
        uint256 takingAmount,
        bytes calldata interactiveData
    ) external onlyLimitOrderProtocol returns (uint256) {
        if (interactiveData[0] == _FINALIZE_INTERACTION) {
            (address[] memory targets, bytes[] memory calldatas) = abi.decode(
                interactiveData[1:],
                (address[], bytes[])
            );

            uint256 length = targets.length;
            if (length != calldatas.length) revert IncorrectCalldataParams();
            for (uint256 i = 0; i < length; i++) {
                // solhint-disable-next-line avoid-low-level-calls
                (bool success, ) = targets[i].call(calldatas[i]);
                if (!success) revert FailedExternalCall();
            }
        } else {
            (
                OrderLib.Order memory order,
                bytes memory signature,
                bytes memory interaction,
                uint256 makingOrderAmount,
                uint256 takingOrderAmount,
                uint256 thresholdAmount
            ) = abi.decode(interactiveData[1:], (OrderLib.Order, bytes, bytes, uint256, uint256, uint256));

            _matchOrder(
                IOrderMixin(msg.sender),
                order,
                signature,
                bytes.concat(interaction, bytes32(order.salt)),
                makingOrderAmount,
                takingOrderAmount,
                thresholdAmount
            );
        }
        uint256 salt = uint256(bytes32(interactiveData[interactiveData.length - 32:]));
        return (takingAmount * _getFeeRate(salt)) / _BASE_POINTS;
    }

    function _getFeeRate(uint256 salt) internal view returns (uint256) {
        uint32 orderTime = uint32((salt & (0xFFFFFFFF << 224)) >> 224); // orderTimeMask 216-255
        // solhint-disable-next-line not-rely-on-time
        uint32 currentTimestamp = uint32(block.timestamp);
        if (orderTime > currentTimestamp) revert IncorrectOrderStartTime();

        uint32 duration = uint32((salt & (0xFFFFFFFF << 192)) >> 192); // durationMask 192-215
        if (duration == 0) {
            duration = _DEFAULT_DURATION;
        }
        orderTime += duration;

        uint16 initialRate = uint16((salt & (0xFFFF << 176)) >> 176); // initialRateMask 176-191
        if (initialRate == 0) {
            initialRate = _DEFAULT_INITIAL_RATE_BUMP;
        }

        return
            currentTimestamp < orderTime
                ? _BASE_POINTS + (initialRate * (orderTime - currentTimestamp)) / duration
                : _BASE_POINTS;
    }

    function _matchOrder(
        IOrderMixin orderMixin,
        OrderLib.Order memory order,
        bytes memory signature,
        bytes memory interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 thresholdAmount
    ) private {
        uint256 orderFee = (order.salt & _ORDER_FEE_MASK) >> (256 - 80 - 72);
        uint256 currentAllowance = creditAllowance[tx.origin]; // solhint-disable-line avoid-tx-origin
        if (currentAllowance < orderFee) revert NotEnoughCredit();
        unchecked {
            creditAllowance[tx.origin] = currentAllowance - orderFee;  // solhint-disable-line avoid-tx-origin
        }
        orderMixin.fillOrder(order, signature, interaction, makingAmount, takingAmount, thresholdAmount);
    }

    function addCreditAllowance(address account, uint256 amount) external onlyFeeBank returns (uint256 allowance) {
        allowance = creditAllowance[account];
        allowance += amount;
        creditAllowance[account] = allowance;
    }

    function subCreditAllowance(address account, uint256 amount) external onlyFeeBank returns (uint256 allowance) {
        allowance = creditAllowance[account];
        allowance -= amount;
        creditAllowance[account] = allowance;
    }

    function setFeeBank(address newFeeBank) external onlyOwner {
        feeBank = newFeeBank;
    }
}
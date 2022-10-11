// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@1inch/limit-order-protocol/contracts/interfaces/NotificationReceiver.sol";
import "@1inch/limit-order-protocol/contracts/interfaces/IOrderMixin.sol";
import "./helpers/WhitelistChecker.sol";
import "./interfaces/IWhitelistRegistry.sol";
import "./interfaces/ISettlement.sol";

contract Settlement is ISettlement, Ownable, WhitelistChecker {
    bytes1 private constant _FINALIZE_INTERACTION = 0x01;
    uint256 private constant _ORDER_TIME_START_MASK     = 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000; // prettier-ignore
    uint256 private constant _ORDER_DURATION_MASK       = 0x00000000FFFFFFFF000000000000000000000000000000000000000000000000; // prettier-ignore
    uint256 private constant _ORDER_INITIAL_RATE_MASK   = 0x0000000000000000FFFF00000000000000000000000000000000000000000000; // prettier-ignore
    uint256 private constant _ORDER_FEE_MASK            = 0x00000000000000000000FFFFFFFF000000000000000000000000000000000000; // prettier-ignore
    uint256 private constant _ORDER_TIME_START_SHIFT = 224; // orderTimeMask 224-255
    uint256 private constant _ORDER_DURATION_SHIFT = 192; // durationMask 192-223
    uint256 private constant _ORDER_INITIAL_RATE_SHIFT = 176; // initialRateMask 176-191
    uint256 private constant _ORDER_FEE_SHIFT = 144; // orderFee 144-175

    uint256 private constant _ORDER_FEE_BASE_POINTS = 1e15;
    uint16 private constant _BASE_POINTS = 10000; // 100%
    uint16 private constant _DEFAULT_INITIAL_RATE_BUMP = 1000; // 10%
    uint32 private constant _DEFAULT_DURATION = 30 minutes;

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
        uint256 thresholdAmount,
        address target
    ) external onlyWhitelisted(msg.sender) {
        _matchOrder(orderMixin, order, msg.sender, signature, interaction, makingAmount, takingAmount, thresholdAmount, target);
    }

    function matchOrdersEOA(
        IOrderMixin orderMixin,
        OrderLib.Order calldata order,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 thresholdAmount,
        address target
    ) external onlyWhitelistedEOA {
        _matchOrder(
            orderMixin,
            order,
            tx.origin, // solhint-disable-line avoid-tx-origin
            signature,
            interaction,
            makingAmount,
            takingAmount,
            thresholdAmount,
            target
        );
    }

    function fillOrderInteraction(
        address, /* taker */
        uint256, /* makingAmount */
        uint256 takingAmount,
        bytes calldata interactiveData
    ) external returns (uint256) {
        address interactor = _onlyLimitOrderProtocol();
        if (interactiveData[0] == _FINALIZE_INTERACTION) {
            (address[] calldata targets, bytes[] calldata calldatas) = _abiDecodeFinal(interactiveData[1:]);

            uint256 length = targets.length;
            if (length != calldatas.length) revert IncorrectCalldataParams();
            for (uint256 i = 0; i < length; i++) {
                // solhint-disable-next-line avoid-low-level-calls
                (bool success, ) = targets[i].call(calldatas[i]);
                if (!success) revert FailedExternalCall();
            }
        } else {
            (
                OrderLib.Order calldata order,
                bytes calldata signature,
                bytes calldata interaction,
                uint256 makingOrderAmount,
                uint256 takingOrderAmount,
                uint256 thresholdAmount,
                address target
            ) = _abiDecodeIteration(interactiveData[1:]);

            _matchOrder(
                IOrderMixin(msg.sender),
                order,
                interactor,
                signature,
                interaction,
                makingOrderAmount,
                takingOrderAmount,
                thresholdAmount,
                target
            );
        }
        uint256 salt = uint256(bytes32(interactiveData[interactiveData.length - 32:]));
        return (takingAmount * _getFeeRate(salt)) / _BASE_POINTS;
    }

    function _getFeeRate(uint256 salt) internal view returns (uint256) {
        uint256 orderStartTime = (salt & _ORDER_TIME_START_MASK) >> _ORDER_TIME_START_SHIFT;
        uint256 duration = (salt & _ORDER_DURATION_MASK) >> _ORDER_DURATION_SHIFT;
        uint256 initialRateBump = (salt & _ORDER_INITIAL_RATE_MASK) >> _ORDER_INITIAL_RATE_SHIFT;
        if (duration == 0) {
            duration = _DEFAULT_DURATION;
        }
        if (initialRateBump == 0) {
            initialRateBump = _DEFAULT_INITIAL_RATE_BUMP;
        }

        unchecked {
            if (block.timestamp > orderStartTime) {  // solhint-disable-line not-rely-on-time
                uint256 timePassed = block.timestamp - orderStartTime;  // solhint-disable-line not-rely-on-time
                return timePassed < duration
                    ? _BASE_POINTS + initialRateBump * (duration - timePassed) / duration
                    : _BASE_POINTS;
            } else {
                return _BASE_POINTS + initialRateBump;
            }
        }
    }

    function _matchOrder(
        IOrderMixin orderMixin,
        OrderLib.Order calldata order,
        address interactor,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 thresholdAmount,
        address target
    ) private {
        uint256 orderFee = ((order.salt & _ORDER_FEE_MASK) >> _ORDER_FEE_SHIFT) * _ORDER_FEE_BASE_POINTS;
        uint256 currentAllowance = creditAllowance[interactor];
        if (currentAllowance < orderFee) revert NotEnoughCredit();
        unchecked {
            creditAllowance[interactor] = currentAllowance - orderFee;
        }
        bytes memory patchedInteraction = abi.encodePacked(interaction, order.salt);
        orderMixin.fillOrderTo(
            order,
            signature,
            patchedInteraction,
            makingAmount,
            takingAmount,
            thresholdAmount,
            target
        );
    }

    function increaseCreditAllowance(address account, uint256 amount) external onlyFeeBank returns (uint256 allowance) {
        allowance = creditAllowance[account];
        allowance += amount;
        creditAllowance[account] = allowance;
    }

    function decreaseCreditAllowance(address account, uint256 amount) external onlyFeeBank returns (uint256 allowance) {
        allowance = creditAllowance[account];
        allowance -= amount;
        creditAllowance[account] = allowance;
    }

    function setFeeBank(address newFeeBank) external onlyOwner {
        feeBank = newFeeBank;
    }

    function _abiDecodeFinal(bytes calldata cd)
        private
        pure
        returns (address[] calldata targets, bytes[] calldata calldatas)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := add(cd.offset, calldataload(cd.offset))
            targets.offset := add(ptr, 0x20)
            targets.length := calldataload(ptr)

            ptr := add(cd.offset, calldataload(add(cd.offset, 0x20)))
            calldatas.offset := add(ptr, 0x20)
            calldatas.length := calldataload(ptr)
        }
    }

    function _abiDecodeIteration(bytes calldata cd)
        private
        pure
        returns (
            OrderLib.Order calldata order,
            bytes calldata signature,
            bytes calldata interaction,
            uint256 makingOrderAmount,
            uint256 takingOrderAmount,
            uint256 thresholdAmount,
            address target
        )
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            order := add(cd.offset, calldataload(cd.offset))

            let ptr := add(cd.offset, calldataload(add(cd.offset, 0x20)))
            signature.offset := add(ptr, 0x20)
            signature.length := calldataload(ptr)

            ptr := add(cd.offset, calldataload(add(cd.offset, 0x40)))
            interaction.offset := add(ptr, 0x20)
            interaction.length := calldataload(ptr)

            makingOrderAmount := calldataload(add(cd.offset, 0x60))
            takingOrderAmount := calldataload(add(cd.offset, 0x80))
            thresholdAmount := calldataload(add(cd.offset, 0xa0))
            target := calldataload(add(cd.offset, 0xc0))
        }
    }
}
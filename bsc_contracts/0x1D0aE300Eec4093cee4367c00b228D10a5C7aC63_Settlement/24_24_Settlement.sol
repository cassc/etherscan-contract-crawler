// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@1inch/limit-order-protocol-contract/contracts/interfaces/IOrderMixin.sol";
import "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import "./interfaces/ISettlement.sol";
import "./interfaces/IResolver.sol";
import "./libraries/DynamicSuffix.sol";
import "./libraries/OrderSaltParser.sol";
import "./libraries/OrderSuffix.sol";
import "./FeeBankCharger.sol";

contract Settlement is ISettlement, FeeBankCharger {
    using SafeERC20 for IERC20;
    using OrderSaltParser for uint256;
    using DynamicSuffix for bytes;
    using AddressLib for Address;
    using OrderSuffix for OrderLib.Order;
    using TakingFee for TakingFee.Data;

    error AccessDenied();
    error IncorrectCalldataParams();
    error FailedExternalCall();
    error ResolverIsNotWhitelisted();
    error WrongInteractionTarget();

    bytes1 private constant _FINALIZE_INTERACTION = 0x01;
    uint256 private constant _ORDER_FEE_BASE_POINTS = 1e15;
    uint256 private constant _BASE_POINTS = 10_000_000; // 100%

    IOrderMixin private immutable _limitOrderProtocol;

    modifier onlyThis(address account) {
        if (account != address(this)) revert AccessDenied();
        _;
    }

    modifier onlyLimitOrderProtocol {
        if (msg.sender != address(_limitOrderProtocol)) revert AccessDenied();
        _;
    }

    constructor(IOrderMixin limitOrderProtocol, IERC20 token)
        FeeBankCharger(token)
    {
        _limitOrderProtocol = limitOrderProtocol;
    }

    function settleOrders(bytes calldata data) external {
        _settleOrder(data, msg.sender, 0, new bytes(0));
    }

    function fillOrderInteraction(
        address taker,
        uint256, /* makingAmount */
        uint256 takingAmount,
        bytes calldata interactiveData
    ) external onlyThis(taker) onlyLimitOrderProtocol returns (uint256 result) {
        (DynamicSuffix.Data calldata suffix, bytes calldata tokensAndAmounts, bytes calldata interaction) = interactiveData.decodeSuffix();
        IERC20 token = IERC20(suffix.token.get());
        result = takingAmount * (_BASE_POINTS + suffix.rateBump) / _BASE_POINTS;
        uint256 takingFee = result * suffix.takingFee.ratio() / TakingFee._TAKING_FEE_BASE;

        bytes memory allTokensAndAmounts = new bytes(tokensAndAmounts.length + 0x40);
        assembly {
            let ptr := add(allTokensAndAmounts, 0x20)
            calldatacopy(ptr, tokensAndAmounts.offset, tokensAndAmounts.length)
            ptr := add(ptr, tokensAndAmounts.length)
            mstore(ptr, token)
            mstore(add(ptr, 0x20), add(result, takingFee))
        }

        if (interactiveData[0] == _FINALIZE_INTERACTION) {
            _chargeFee(suffix.resolver.get(), suffix.totalFee);
            address target = address(bytes20(interaction));
            bytes calldata data = interaction[20:];
            IResolver(target).resolveOrders(suffix.resolver.get(), allTokensAndAmounts, data);
        } else {
            _settleOrder(
                interaction,
                suffix.resolver.get(),
                suffix.totalFee,
                allTokensAndAmounts
            );
        }

        if (takingFee > 0) {
            token.safeTransfer(suffix.takingFee.receiver(), takingFee);
        }
        token.forceApprove(address(_limitOrderProtocol), result);
    }

    bytes4 private constant _FILL_ORDER_TO_SELECTOR = 0xe5d7bde6; // IOrderMixin.fillOrderTo.selector
    bytes4 private constant _WRONG_INTERACTION_TARGET_SELECTOR = 0x5b34bf89; // WrongInteractionTarget.selector

    function _settleOrder(bytes calldata data, address resolver, uint256 totalFee, bytes memory tokensAndAmounts) private {
        OrderLib.Order calldata order;
        assembly {
            order := add(data.offset, calldataload(data.offset))
        }
        if (!order.checkResolver(resolver)) revert ResolverIsNotWhitelisted();
        TakingFee.Data takingFeeData = order.takingFee();
        totalFee += order.salt.getFee() * _ORDER_FEE_BASE_POINTS;

        uint256 rateBump = order.rateBump();
        uint256 suffixLength = DynamicSuffix._STATIC_DATA_SIZE + tokensAndAmounts.length + 0x20;
        IOrderMixin limitOrderProtocol = _limitOrderProtocol;

        assembly {
            function memcpy(dst, src, len) {
                pop(staticcall(gas(), 0x4, src, len, dst, len))
            }

            let interactionLengthOffset := calldataload(add(data.offset, 0x40))
            let interactionOffset := add(interactionLengthOffset, 0x20)
            let interactionLength := calldataload(add(data.offset, interactionLengthOffset))

            { // stack too deep
                let target := shr(96, calldataload(add(data.offset, interactionOffset)))
                if or(lt(interactionLength, 20), iszero(eq(target, address()))) {
                    mstore(0, _WRONG_INTERACTION_TARGET_SELECTOR)
                    revert(0, 4)
                }
            }

            // Copy calldata and patch interaction.length
            let ptr := mload(0x40)
            mstore(ptr, _FILL_ORDER_TO_SELECTOR)
            calldatacopy(add(ptr, 4), data.offset, data.length)
            mstore(add(add(ptr, interactionLengthOffset), 4), add(interactionLength, suffixLength))

            {  // stack too deep
                // Append suffix fields
                let offset := add(add(ptr, interactionOffset), interactionLength)
                mstore(add(offset, 0x04), totalFee)
                mstore(add(offset, 0x24), resolver)
                mstore(add(offset, 0x44), calldataload(add(order, 0x40)))  // takerAsset
                mstore(add(offset, 0x64), rateBump)
                mstore(add(offset, 0x84), takingFeeData)
                let tokensAndAmountsLength := mload(tokensAndAmounts)
                memcpy(add(offset, 0xa4), add(tokensAndAmounts, 0x20), tokensAndAmountsLength)
                mstore(add(offset, add(0xa4, tokensAndAmountsLength)), tokensAndAmountsLength)
            }

            // Call fillOrderTo
            if iszero(call(gas(), limitOrderProtocol, 0, ptr, add(add(4, suffixLength), data.length), ptr, 0)) {
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }
}
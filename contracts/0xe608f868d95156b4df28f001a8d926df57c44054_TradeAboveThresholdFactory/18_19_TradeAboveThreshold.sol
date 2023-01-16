// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./ConditionalOrder.sol";
import "lib/contracts/src/contracts/GPv2Settlement.sol";
import "lib/contracts/src/contracts/interfaces/GPv2EIP1271.sol";

// @title A smart contract that trades whenever its balance of a certain token exceeds a target threshold
contract TradeAboveThreshold is ConditionalOrder, EIP1271Verifier {
    using GPv2Order for GPv2Order.Data;

    IERC20 public immutable sellToken;
    IERC20 public immutable buyToken;
    address public immutable target;
    uint256 public immutable threshold;
    bytes32 public domainSeparator;

    constructor(
        IERC20 _sellToken,
        IERC20 _buyToken,
        address _target,
        uint256 _threshold,
        GPv2Settlement _settlementContract
    ) {
        sellToken = _sellToken;
        buyToken = _buyToken;
        if (_target == address(0)) {
            _target = address(this);
        }
        target = _target;
        threshold = _threshold;
        domainSeparator = _settlementContract.domainSeparator();
        _sellToken.approve(
            address(_settlementContract.vaultRelayer()),
            uint(-1)
        );

        emit ConditionalOrderCreated(_target);
    }

    // @dev If the `target`'s balance of `sellToken` is above the specified threshold, sell its entire balance
    // for `buyToken` at the current market price (no limit!).
    function getTradeableOrder()
        external
        view
        override
        returns (GPv2Order.Data memory)
    {
        uint256 balance = sellToken.balanceOf(target);
        require(balance >= threshold, "Not enough balance");
        // ensures that orders queried shortly after one another result in the same hash (to avoid spamming the orderbook)
        // solhint-disable-next-line not-rely-on-time
        uint32 currentTimeBucket = ((uint32(block.timestamp) / 900) + 1) * 900;
        return
            GPv2Order.Data(
                sellToken,
                buyToken,
                target,
                balance,
                1, // 0 buy amount is not allowed
                currentTimeBucket + 900, // between 15 and 30 miunte validity
                keccak256("TradeAboveThreshold"),
                0,
                GPv2Order.KIND_SELL,
                false,
                GPv2Order.BALANCE_ERC20,
                GPv2Order.BALANCE_ERC20
            );
    }

    /// @param orderDigest The EIP-712 signing digest derived from the order
    /// @param encodedOrder Bytes-encoded order information, originally created by an off-chain bot. Created by concatening the order data (in the form of GPv2Order.Data), the price checker address, and price checker data.
    function isValidSignature(
        bytes32 orderDigest,
        bytes calldata encodedOrder
    ) external view override returns (bytes4) {
        GPv2Order.Data memory order = abi.decode(
            encodedOrder,
            (GPv2Order.Data)
        );
        require(
            order.hash(domainSeparator) == orderDigest,
            "encoded order digest mismatch"
        );

        // If getTradeableOrder() may change between blocks (e.g. because of a variable exchange rate or exprity date, perform a proper attribute comparison with `order` here instead of matching full hashes)
        require(
            ConditionalOrder(this).getTradeableOrder().hash(domainSeparator) ==
                orderDigest,
            "encoded order != tradable order"
        );

        return GPv2EIP1271.MAGICVALUE;
    }
}
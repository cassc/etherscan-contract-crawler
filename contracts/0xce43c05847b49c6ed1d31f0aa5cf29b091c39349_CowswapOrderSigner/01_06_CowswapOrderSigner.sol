// SPDX-License-Identifier: MIT

// contract taken from https://gist.github.com/Arachnid/6950b3367258b5d5033f6e1c411086e8
// cowswap contracts taken from https://github.com/cowprotocol/contracts/releases/tag/v1.3.2

pragma solidity ^0.8.12;

import "./cowProtocol/libraries/GPv2Order.sol";
import "./cowProtocol/mixins/GPv2Signing.sol";
import "./cowProtocol/interfaces/IERC20.sol";

contract CowswapOrderSigner {
    using GPv2Order for GPv2Order.Data;

    GPv2Signing public immutable signing;
    bytes32 immutable domainSeparator;
    address immutable deployedAt;

    constructor(GPv2Signing _signing) { 
        signing = _signing;
        domainSeparator = _signing.domainSeparator();
        deployedAt = address(this);
    }

    // write an internal function that creates the order digest
    function packOrder(
        IERC20 sellToken,
        IERC20 buyToken,
        uint256 sellAmount,
        uint256 buyAmount,
        uint32 validTo,
        uint256 feeAmount,
        bytes32 kind,
        bool partiallyFillable,
        bytes32 sellTokenBalance,
        bytes32 buyTokenBalance
    ) internal view returns (bytes memory) {
        GPv2Order.Data memory order;
        order.sellToken = sellToken;
        order.buyToken = buyToken;
        order.receiver = address(this);
        order.sellAmount = sellAmount;
        order.buyAmount = buyAmount;
        order.validTo = validTo;
        order.appData = bytes32(uint256(uint160(deployedAt)));
        order.feeAmount = feeAmount;
        order.kind = kind;
        order.partiallyFillable = partiallyFillable;
        order.sellTokenBalance = sellTokenBalance;
        order.buyTokenBalance = buyTokenBalance;

        bytes32 orderDigest = order.hash(domainSeparator);
        bytes memory orderUid = new bytes(GPv2Order.UID_LENGTH);
        GPv2Order.packOrderUidParams(
            orderUid,
            orderDigest,
            address(this),
            validTo);

        return orderUid;
    }

    function signOrder(
        IERC20 sellToken,
        IERC20 buyToken,
        uint256 sellAmount,
        uint256 buyAmount,
        uint32 validTo, // unix timestamp
        uint32 validDuration, // seconds
        uint256 feeAmount,
        uint256 feeAmountBP,
        bytes32 kind,
        bool partiallyFillable,
        bytes32 sellTokenBalance,
        bytes32 buyTokenBalance
    ) external {
        require(address(this) != deployedAt, "DELEGATECALL only");
        require(block.timestamp + validDuration > validTo, "Dishonest valid duration");
        require(feeAmount <= (sellAmount * feeAmountBP) / 10000 + 1, "Fee too high");

        bytes memory orderUid = packOrder(sellToken, buyToken, sellAmount, buyAmount, validTo, feeAmount, kind, partiallyFillable, sellTokenBalance, buyTokenBalance);
        signing.setPreSignature(orderUid, true);
    }
}
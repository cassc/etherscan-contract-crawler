// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "lib/contracts/src/contracts/GPv2Settlement.sol";
import "lib/contracts/src/contracts/interfaces/GPv2EIP1271.sol";
import "lib/milkman/contracts/pricecheckers/IExpectedOutCalculator.sol";

// @title A smart contract that is always willing to trade token A for B as long
// as the price is better than some on-chain reference. Thus, this liquidity can be
// used to replace interactions that would otherwise use this reference liquidity
// source to settle another user order.
contract WaitForCoWOrder is EIP1271Verifier {
    event WaitForCoWOrderCreated(address indexed);

    using GPv2Order for GPv2Order.Data;
    using SafeMath for uint256;

    // There are 10k basis points in a unit
    uint256 public constant BPS = 10_000;

    IERC20 public immutable sellToken;
    IERC20 public immutable buyToken;
    address public immutable target;
    bytes32 public immutable domainSeparator;

    IExpectedOutCalculator public immutable expectedOutCalculator;
    bytes public expectedOutCalculatorCalldata;
    uint256 public slippageToleranceBps;

    /**
     * Creates a new wait-for-cow order. All resulting swaps will be made from the target contract.
     * @param _sellToken The token that we are willing to sell
     * @param _buyToken The other that we are willing to buy
     * @param _target The contract holding the relevant balances (e.g a target Safe)
     * @param _settlementContract The CoW Protocol settlement contract
     * @param _expectedOutCalculator The contract which is used to check the reference liquidity
     * @param _expectedOutCalculatorCalldata The calldata provided into the reference checker
     * @param _slippageToleranceBps How much discount from the reference price you are willing to match.
     * In order to match at the current spot price this should be the same as the pool's fee.
     */
    constructor(
        IERC20 _sellToken,
        IERC20 _buyToken,
        address _target,
        GPv2Settlement _settlementContract,
        IExpectedOutCalculator _expectedOutCalculator,
        bytes memory _expectedOutCalculatorCalldata,
        uint256 _slippageToleranceBps
    ) {
        sellToken = _sellToken;
        buyToken = _buyToken;
        domainSeparator = _settlementContract.domainSeparator();
        target = _target;
        expectedOutCalculator = _expectedOutCalculator;
        expectedOutCalculatorCalldata = _expectedOutCalculatorCalldata;
        slippageToleranceBps = _slippageToleranceBps;

        require(_target != address(0), "Need a target");
        emit WaitForCoWOrderCreated(_target);
    }

    /// @param orderDigest The EIP-712 signing digest derived from the order
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

        require(order.receiver == target, "Wrong recipient");
        require(order.sellToken == sellToken, "Wrong sellToken");
        require(order.buyToken == buyToken, "Wrong buyToken");
        require(order.feeAmount == 0, "CoWs don't pay fees");
        require(!order.partiallyFillable, "Match must be FoK");
        require(
            order.sellTokenBalance == GPv2Order.BALANCE_ERC20,
            "Wrong Balance"
        );
        require(
            order.buyTokenBalance == GPv2Order.BALANCE_ERC20,
            "Wrong Balance"
        );

        // Check how much the reverse order would get out.
        uint256 expectedOut = expectedOutCalculator.getExpectedOut(
            order.buyAmount,
            address(order.buyToken),
            address(order.sellToken),
            expectedOutCalculatorCalldata
        );

        // Increase expected out by what we think is half the spread (to allow match at midpoint)
        expectedOut = expectedOut.mul(BPS.add(slippageToleranceBps)).div(BPS);

        // As long as we are not selling more than what the reverse order would get at midpoint, we are making a good deal
        require(expectedOut >= order.sellAmount, "Bad price");

        return GPv2EIP1271.MAGICVALUE;
    }
}
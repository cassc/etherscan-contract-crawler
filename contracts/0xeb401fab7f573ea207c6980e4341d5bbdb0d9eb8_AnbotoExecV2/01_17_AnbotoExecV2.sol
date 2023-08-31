// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/* ========== STRUCTS ========== */

/**
 * @notice Represents a customer order.
 * @member inputToken Token being sold.
 * @member totalAmount Amount to sell.
 * @member outputToken Token being bought.
 * @member outMin Minumum amount the user expects to get.
 * @member maxGasPrice Maximum gas price accepted.
 * @member maxFeeAbsolute Agreed max fee amount for order.
 * This fee is covering tx gas fee and taken dependant on the ratio between tx gas price and max gas price.
 * @member feePercent Agreed Anboto service fee amount in percents, where 1_00 equals one percent.
 * @member isFeeTakenInInput If true, the fee will be taken in input tokens; otherwise it will be taken in output token.
 * @member deadline Deadline until which the order is valid.
 * @member salt Random additional input to make the order unique.
 */
struct Order {
    IERC20 inputToken;
    uint256 totalAmount;
    IERC20 outputToken;
    uint256 outMin;
    uint256 maxGasPrice;
    uint256 maxFeeAbsolute;
    uint256 feePercent;
    bool isFeeTakenInInput;
    uint256 deadline;
    uint256 salt;
}

/**
 * @notice Exchange quote for swapping tokens.
 * @member spender Address approved to execute swap.
 * @member swapTarget Contract executing the swap.
 * @member sellAmount Amount to sell in the swap.
 * @member swapCallData Custom swap data.
 */
struct Quote {
    address spender;
    address swapTarget;
    uint256 sellAmount;
    bytes swapCallData;
}

/**
 * @notice CoW settlement details.
 * @member sellAmount Amount to sell to the CoW.
 * @member buyAmount Amount to buy from the CoW.
 */
struct Settlement {
    uint256 sellAmount;
    uint256 buyAmount;
}

/* ========== CONTRACTS ========== */

/**
 * @title Composite order contract version 2.
 * @notice This contract manages sliced execution of customer's swap orders.
 * Slices can be executed in two ways:
 * - via executing a swap on external exchange based on a quote
 * - by settling a CoW order based on settlement provided by Anboto CoW solver
 * @dev Contract is Ownable and EIP712.
 * It uses SafeERC20 for token operations.
 * It supports EIP1271 signed messages.
 */
contract AnbotoExecV2 is Ownable, EIP712 {
    using SafeERC20 for IERC20;

    /* ========== EVENTS ========== */

    /**
     * @notice Event emitted when new Anboto authorized address is set.
     * @dev Emitted when `setAnboto` is called.
     * @param anboto Anboto authorized address.
     * @param set `true` if authorized, `false` if unathorized.
     */
    event AnbotoSet(address indexed anboto, bool set);

    /**
     * @notice Event emitted when exchange allowlist is updated.
     * @dev Emmited when `_updateExchangeAllowlist` is called.
     * @param exchange Address of exchange to update.
     * @param allowed True when exchange is allowed, false when disallowed.
     */
    event ExchangeAllowlistUpdated(address exchange, bool allowed);

    /**
     * @notice Event emitted when address for Anboto CoW solver is set.
     * @dev Emitted when `setAnbotoCowSolver` is called.
     * @param anbotoCowSolver Address belonging to Anboto CoW solver.
     */
    event AnbotoCowSolverSet(address indexed anbotoCowSolver);

    /**
     * @notice Event emitted when order slice is executed.
     * @dev Emitted when `executeOrder` is called.
     * @param maker Maker of the order.
     * @param sig Order signature.
     * @param spentAmount Amount of user tokens spent in execution.
     * @param boughtAmount Amount of tokens bought for user in execution.
     * @param feeAmount Amount of tokens taken as fees.
     */
    event OrderExecuted(
        address indexed maker,
        bytes indexed sig,
        uint256 spentAmount,
        uint256 boughtAmount,
        uint256 feeAmount
    );

    /**
     * @notice Event emitted when part of the order is executed by settling CoW order.
     * @dev Emitted when `settleCow` is called.
     * @param maker Maker of the order.
     * @param sig Order signature.
     * @param spentAmount Amount of user tokens spent in settlement.
     * @param boughtAmount Amount of tokens bought for user in settlement.
     * @param feeAmount Amount of tokens taken as fees.
     */
    event CowSettled(
        address indexed maker,
        bytes indexed sig,
        uint256 spentAmount,
        uint256 boughtAmount,
        uint256 feeAmount
    );

    /**
     * @notice Event emitted when fees are claimed.
     * @dev Emitted when `claimFees` is called.
     * @param claimedTo Where claimed fees were sent to.
     * @param token Token claimed.
     * @param amount Amount claimed.
     */
    event FeesClaimed(address indexed claimedTo, address indexed token, uint256 amount);

    /* ========== CONSTANTS ========== */

    /** @notice One hundred percent. */
    uint256 public constant FULL_PERCENT = 100_00;

    /** @notice Order struct type signature hash. */
    bytes32 private constant ORDER_TYPEHASH =
        keccak256(
            "Order(address inputToken,uint256 totalAmount,address outputToken,uint256 outMin,uint256 maxGasPrice,uint256 maxFeeAbsolute,uint256 feePercent,bool isFeeTakenInInput,uint256 deadline,uint256 salt)"
        );

    /* ========== STATE VARIABLES ========== */

    /** @notice Addresses approved to execute order slices. */
    mapping(address => bool) public isAnboto;
    /** @notice Tracks how much each order is already fulfilled. */
    mapping(bytes => uint256) public orderFulfilledAmount;

    /** @notice Which exchanges are allowed to be used for executing orders. */
    mapping(address => bool) public exchangeAllowlist;

    /** @notice Address where CoW settlement contract is deployed. */
    address public immutable cowSettlementContract;
    /** @notice Address of approved Anboto CoW solver. */
    address public anbotoCowSolver;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Contract constructor setting contract domain name and version,
     * and other state.
     * @param _allowedExchanges Address of exchanges that are allowed to be used for executing orders.
     * @param _cowSettlementContract Address where CoW settlement contract is deployed.
     * @param _anbotoCowSolver Address of approved Anboto CoW solver.
     */
    constructor(
        address[] memory _allowedExchanges,
        address _cowSettlementContract,
        address _anbotoCowSolver
    ) EIP712("AnbotoExecV2", "2") {
        for (uint256 i; i < _allowedExchanges.length; ++i) {
            _updateExchangeAllowlist(_allowedExchanges[i], true);
        }

        cowSettlementContract = _cowSettlementContract;
        _setAnbotoCowSolver(_anbotoCowSolver);
    }

    /* ========== ADMINISTRATION ========== */

    /**
     * @notice Sets or unsets the address as Anboto approved.
     * @dev Requirements:
     * - can only be called by owner
     * @param _anboto Address to approve or unapprove.
     * @param _set Approves the address when `true`, unapproves when `false`.
     */
    function setAnboto(address _anboto, bool _set) external onlyOwner {
        isAnboto[_anboto] = _set;

        emit AnbotoSet(_anboto, _set);
    }

    function updateExchangeAllowlist(
        address[] calldata exchanges,
        bool[] calldata allowed
    ) external onlyOwner {
        require(
            exchanges.length == allowed.length,
            "AnbotoExecV2::updateExchangeAllowlist: Parameter length mismatch."
        );

        for (uint256 i; i < exchanges.length; ++i) {
            _updateExchangeAllowlist(exchanges[i], allowed[i]);
        }
    }

    function _updateExchangeAllowlist(address exchange, bool allowed) private {
        exchangeAllowlist[exchange] = allowed;

        emit ExchangeAllowlistUpdated(exchange, allowed);
    }

    /**
     * @notice Sets address as approved Anboto CoW solver.
     * @dev Requirements:
     * - can only be called by owner
     * @param _anbotoCowSolver Address to set.
     */
    function setAnbotoCowSolver(address _anbotoCowSolver) external onlyOwner {
        _setAnbotoCowSolver(_anbotoCowSolver);
    }

    /**
     * @dev Sets address as approved Anboto CoW solver.
     * @param _anbotoCowSolver Address to set.
     */
    function _setAnbotoCowSolver(address _anbotoCowSolver) private {
        anbotoCowSolver = _anbotoCowSolver;

        emit AnbotoCowSolverSet(_anbotoCowSolver);
    }

    /* ========== ORDER FULFILLMENT ========== */

    /**
     * @notice Executes a slice of the original order.
     * The slice is executed by swapping tokens with external exchange as
     * specified in the quote, while making sure that original order
     * specifications are honored.
     * Allowance should be set with input token beforehand by maker.
     * Portion of the output will be held as a fee.
     * Un-swapped  portion of the input will be returned to the maker.
     * @dev Requirements:
     * - should be called by owner or Anboto approved address
     * - should be called before order deadline
     * - should be called with different token order input and output tokens
     * - should be called with valid signature; order is signed by maker and is unchanged
     * - should be called when gas price is not too high
     * - quote sell amount should not over fulfill order
     * - quote buy amount should be over limit specified by order
     * - quote swap target needs to be on exchange allowlist
     * @param _order Original order made by maker.
     * @param _quote Slice execution specifications.
     * @param _maker Anboto user that made the order.
     * @param _sig Order signed by maker.
     */
    function executeOrder(
        Order calldata _order,
        Quote calldata _quote,
        address _maker,
        bytes calldata _sig
    ) external {
        // Verify conditions.
        require(
            msg.sender == owner() || isAnboto[msg.sender],
            "AnbotoExecV2::executeOrder: Caller is not Anboto."
        );
        validateOrder(_order, _maker, _sig);
        require(
            exchangeAllowlist[_quote.swapTarget],
            "AnbotoExecV2::executeOrder: Swap target not allowed."
        );
        require(
            tx.gasprice <= _order.maxGasPrice,
            "AnbotoExecV2::executeOrder: Gas price too high."
        );

        // Unpack structs.
        uint256 sliceInputAmount = _quote.sellAmount;
        IERC20 inputToken = _order.inputToken;
        IERC20 outputToken = _order.outputToken;

        // Update state and check that order total is not exceeded.
        orderFulfilledAmount[_sig] += sliceInputAmount;
        checkOrderTotal(_order, _sig);

        // Get the balance before the swap.
        uint256 swapInputBalance = inputToken.balanceOf(address(this));
        uint256 swapOutputBalance = outputToken.balanceOf(address(this));

        // Transfer input tokens.
        inputToken.safeTransferFrom(_maker, address(this), sliceInputAmount);

        uint256 feeAmountInputToken;
        if (_order.isFeeTakenInInput) {
            // Take fees in input tokens.
            feeAmountInputToken = getFee(
                _order,
                sliceInputAmount,
                sliceInputAmount,
                tx.gasprice
            );
        }

        // Execute the swap.
        inputToken.safeApprove(_quote.spender, sliceInputAmount - feeAmountInputToken);
        {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory data) = _quote.swapTarget.call(
                _quote.swapCallData
            );
            if (!success) revert(getRevertMsg(data));
        }

        // Get the balance after the swap.
        // Equals amount of input tokens that were pulled from maker but not swapped.
        swapInputBalance =
            inputToken.balanceOf(address(this)) -
            swapInputBalance -
            feeAmountInputToken;
        // Equals amount of output tokens that were obtained in the swap.
        swapOutputBalance = outputToken.balanceOf(address(this)) - swapOutputBalance;

        // If we swapped less than expected
        if (swapInputBalance > 0) {
            // - correct collected fees
            uint256 feeCorrection = (feeAmountInputToken * swapInputBalance) /
                (sliceInputAmount - feeAmountInputToken);
            uint256 swapInputBalanceCorrected = swapInputBalance + feeCorrection;

            feeAmountInputToken -= feeCorrection;
            // - correct slice amount
            sliceInputAmount -= swapInputBalanceCorrected;
            // - correct fulfilled tally
            orderFulfilledAmount[_sig] -= swapInputBalanceCorrected;
            // - return unspent tokens
            inputToken.safeTransfer(_maker, swapInputBalanceCorrected);
            // - set approval to 0
            inputToken.safeApprove(_quote.spender, 0);
        }

        uint256 feeAmountOutputToken;
        if (!_order.isFeeTakenInInput) {
            // Take fees in output tokens.
            feeAmountOutputToken = getFee(
                _order,
                sliceInputAmount,
                swapOutputBalance,
                tx.gasprice
            );
        }

        uint256 swapOutputBalanceCorrected = swapOutputBalance - feeAmountOutputToken;

        // Check if enough output tokens were received by the swap.
        checkOutputAmount(_order, sliceInputAmount, swapOutputBalanceCorrected);

        // Transfer output tokens (minus fees) to the maker.
        outputToken.safeTransfer(_maker, swapOutputBalanceCorrected);

        emit OrderExecuted(
            _maker,
            _sig,
            sliceInputAmount,
            swapOutputBalanceCorrected,
            feeAmountInputToken + feeAmountOutputToken
        );
    }

    /**
     * @notice Use a slice of the original order to settle a CoW order.
     * The CoW order is settled by swapping tokens with CoW settlement contract
     * as specified in the settlement, while making sure that original order
     * specifications are honored.
     * Allowance should be set with input token beforehand by maker.
     * Portion of the output will be held as a fee.
     * @dev Requirements:
     * - should be called by CoW settlement contract
     * - transaction should be originating from Anboto CoW solver
     * - should be called before order deadline
     * - should be called with different token order input and output tokens
     * - should be called with valid signature; order is signed by maker and is unchanged
     * - settlement sell amount should not over fulfill order
     * - settlement buy amount should be over limit specified by order
     * @param _order Original order made by maker.
     * @param _settlement CoW settlement specifications.
     * @param _maker Anboto user that made the order.
     * @param _sig Order signed by maker.
     */
    function settleCow(
        Order calldata _order,
        Settlement calldata _settlement,
        address _maker,
        bytes calldata _sig
    ) external {
        // Verify conditions.
        require(
            msg.sender == cowSettlementContract,
            "AnbotoExecV2::settleCow: Caller is not CoW settlement contract."
        );
        require(
            // solhint-disable-next-line avoid-tx-origin
            tx.origin == anbotoCowSolver,
            "AnbotoExecV2::settleCow: Origin is not Anboto CoW solver."
        );
        validateOrder(_order, _maker, _sig);

        // Unpack structs.
        IERC20 inputToken = _order.inputToken;
        IERC20 outputToken = _order.outputToken;
        uint256 sellAmount = _settlement.sellAmount;
        uint256 buyAmount = _settlement.buyAmount;

        // Calculate fees.
        uint256 feeAmountInputToken;
        if (_order.isFeeTakenInInput) {
            // Take fees in input tokens.
            feeAmountInputToken = getCowFee(_order, sellAmount);
        }
        uint256 feeAmountOutputToken;
        if (!_order.isFeeTakenInInput) {
            // Take fees in output tokens.
            feeAmountOutputToken = getCowFee(_order, buyAmount);
        }

        // Update balance and verify settlement.
        orderFulfilledAmount[_sig] += sellAmount + feeAmountInputToken;
        checkOrderTotal(_order, _sig);
        checkOutputAmount(
            _order,
            sellAmount + feeAmountInputToken,
            buyAmount - feeAmountOutputToken
        );

        // Settle order.
        inputToken.safeTransferFrom(_maker, cowSettlementContract, sellAmount);
        outputToken.safeTransferFrom(cowSettlementContract, address(this), buyAmount);
        // Take fees.
        if (feeAmountInputToken > 0) {
            inputToken.safeTransferFrom(_maker, address(this), feeAmountInputToken);
        }

        // Transfer output tokens (minus fees) to the maker.
        outputToken.safeTransfer(_maker, buyAmount - feeAmountOutputToken);

        emit CowSettled(
            _maker,
            _sig,
            sellAmount + feeAmountInputToken,
            buyAmount,
            feeAmountInputToken + feeAmountOutputToken
        );
    }

    /* ========== FEES ========== */

    /**
     * @notice Claim collected fees.
     * @dev Requirements:
     * - can only be called by owner
     * - cannot be claimed to null address
     * @param _tokens Claim fees collected in these tokens.
     * @param _claimTo Where to send collected fees.
     */
    function claimFees(IERC20[] calldata _tokens, address _claimTo) external onlyOwner {
        require(
            _claimTo != address(0),
            "AnbotoExecV2::claimFees: Cannot claim to null address."
        );

        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 amountToClaim = _tokens[i].balanceOf(address(this));
            _tokens[i].safeTransfer(_claimTo, amountToClaim);

            emit FeesClaimed(_claimTo, address(_tokens[i]), amountToClaim);
        }
    }

    /* ========== HELPERS ========== */

    /**
     * @notice Checks validity of order signature.
     * The signature is considered valid, if
     * - it is signed by provided signer and
     * - provided order matches signed one.
     * @dev Uses EIP712 and EIP1271 standard libraries.
     * @param _order Signed order.
     * @param _signer Order signer.
     * @param _sig Signature to validate.
     * @return `true` if order is valid, `false` otherwise.
     */
    function isValidSignature(
        Order calldata _order,
        address _signer,
        bytes calldata _sig
    ) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(hashOrder(_order));
        return SignatureChecker.isValidSignatureNow(_signer, digest, _sig);
    }

    /**
     * @dev Calculates hash of an Order struct.
     * Used as part of EIP712 and checking validity of order signature.
     * @param _order Order to hash.
     * @return Hash of the order.
     */
    function hashOrder(Order calldata _order) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    _order.inputToken,
                    _order.totalAmount,
                    _order.outputToken,
                    _order.outMin,
                    _order.maxGasPrice,
                    _order.maxFeeAbsolute,
                    _order.feePercent,
                    _order.isFeeTakenInInput,
                    _order.deadline,
                    _order.salt
                )
            );
    }

    /**
     * @dev Gets revert message when a low-level call reverts, so that it can
     * be bubbled-up to caller.
     * @param _returnData Data returned from reverted low-level call.
     * @return Revert message.
     */
    function getRevertMsg(bytes memory _returnData) private pure returns (string memory) {
        // if the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68)
            return "AnbotoExecV2::getRevertMsg: Transaction reverted silently.";

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // slice the sig hash
            _returnData := add(_returnData, 0x04)
        }

        return abi.decode(_returnData, (string)); // all that remains is the revert string
    }

    /**
     * @dev Calculates fees owed to Anboto.
     * @param _order Order made by maker.
     * @param _sliceAmount Size of slice being executed.
     * @param _baseAmount Base amount for fee calculation.
     * @param _gasPrice Tx gas price
     * @return feeAmount Amount of fees owed to Anboto.
     */
    function getFee(
        Order calldata _order,
        uint256 _sliceAmount,
        uint256 _baseAmount,
        uint256 _gasPrice
    ) private pure returns (uint256 feeAmount) {
        if (_order.maxFeeAbsolute > 0) {
            // Take absolute fee when absolute max fee is specified.
            // Absolute fees are total amount owed for whole order, so for each
            // slice we need to take amount proportional to amount sold in the
            // slice as compared to the total order. This amount is multiplied by
            // ratio of tx gas price to max gas price so we could take the fee to
            // cover the transaction costs.
            feeAmount +=
                (_order.maxFeeAbsolute * _gasPrice * _sliceAmount) /
                (_order.maxGasPrice * _order.totalAmount);
        }
        if (_order.feePercent > 0) {
            // Take relative fee when relative fee percent is specified.
            feeAmount += (_baseAmount * _order.feePercent) / FULL_PERCENT;
        }

        // Should not collect more fees than we have.
        require(
            _baseAmount > feeAmount,
            "AnbotoExecV2::calculateFee: Fee larger than base amount."
        );
    }

    /**
     * @dev Calculates fees owed to Anboto.
     * @param _order Order made by maker.
     * @param _baseAmount Base amount for fee calculation.
     * @return feeAmount Amount of fees owed to Anboto.
     */
    function getCowFee(Order calldata _order, uint256 _baseAmount)
        private
        pure
        returns (uint256 feeAmount)
    {
        require(
            _order.feePercent < FULL_PERCENT,
            "AnbotoExecV2::getCowFee: Fee larger than base amount."
        );

        if (_order.feePercent > 0) {
            if (_order.isFeeTakenInInput) {
                feeAmount =
                    (_baseAmount * _order.feePercent) /
                    (FULL_PERCENT - _order.feePercent);
            } else {
                feeAmount = (_baseAmount * _order.feePercent) / FULL_PERCENT;
            }
        }
    }

    /**
     * @dev Validates order and its signature:
     * - order deadline should not have passed
     * - order fee amount should not be too high
     * - order input and output tokens should not be same
     * - order should be signed by maker and should be unchanged
     * @param _order Order made by maker.
     * @param _maker Anboto user that made the order.
     * @param _sig Order signed by maker.
     */
    function validateOrder(
        Order calldata _order,
        address _maker,
        bytes calldata _sig
    ) private view {
        require(
            block.timestamp <= _order.deadline,
            "AnbotoExecV2::validateOrder: Order deadline passed."
        );
        require(
            _order.inputToken != _order.outputToken,
            "AnbotoExecV2::validateOrder: Input and output tokens are same."
        );

        // Verify signature.
        require(
            isValidSignature(_order, _maker, _sig),
            "AnbotoExecV2::validateOrder: Invalid signature."
        );
    }

    /**
     * @dev Checks that order total amount has not been exceeded.
     * @param _order Order made by maker.
     * @param _sig Order signed by maker.
     */
    function checkOrderTotal(Order calldata _order, bytes calldata _sig) private view {
        require(
            orderFulfilledAmount[_sig] <= _order.totalAmount,
            "AnbotoExecV2::checkOrderTotal: Order total exceeded."
        );
    }

    /**
     * @dev Checks that output amount is not too low.
     * @param _order Order made by maker.
     * @param _soldAmount Amount of tokens sold in trade.
     * @param _boughtAmount Amount of tokens bought in trade.
     */
    function checkOutputAmount(
        Order calldata _order,
        uint256 _soldAmount,
        uint256 _boughtAmount
    ) private pure {
        require(
            _boughtAmount * _order.totalAmount >= _order.outMin * _soldAmount,
            "AnbotoExecV2::checkOutputAmount: Output amount too low."
        );
    }
}
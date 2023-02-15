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
 * @member outMin Minumum amount to buy.
 * @member maxGasPrice Maximum gas price accepted.
 * @member feeAmount Agreed fee amount in percents, where 1_00 equals one percent.
 * @member deadline Deadline until which the order is valid.
 * @member salt Random additional input to make the order unique.
 */
struct Order {
    IERC20 inputToken;
    uint256 totalAmount;
    IERC20 outputToken;
    uint256 outMin;
    uint256 maxGasPrice;
    uint256 feeAmount;
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
     * @param soldToken Token sold in execution.
     * @param boughtToken Token bought in execution.
     * @param soldAmount Amount bought in execution.
     * @param boughtAmount Amount sold in execution.
     */
    event OrderExecuted(
        address indexed maker,
        bytes indexed sig,
        address soldToken,
        address boughtToken,
        uint256 soldAmount,
        uint256 boughtAmount
    );

    /**
     * @notice Event emitted when part of the order is executed by settling CoW order.
     * @dev Emitted when `settleCow` is called.
     * @param maker Maker of the order.
     * @param sig Order signature.
     * @param soldToken Token sold in settlement.
     * @param boughtToken Token bought in settlement.
     * @param soldAmount Amount sold in settlement.
     * @param boughtAmount Amount bought in settlement.
     */
    event CowSettled(
        address indexed maker,
        bytes indexed sig,
        address soldToken,
        address boughtToken,
        uint256 soldAmount,
        uint256 boughtAmount
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
    /** @notice Max fee is one percent. */
    uint256 public constant MAX_FEE = 1_00;

    /** @notice Order struct type signature hash. */
    bytes32 private constant ORDER_TYPEHASH =
        keccak256(
            "Order(address inputToken,uint256 totalAmount,address outputToken,uint256 outMin,uint256 maxGasPrice,uint256 feeAmount,uint256 deadline,uint256 salt)"
        );

    /* ========== STATE VARIABLES ========== */

    /** @notice Addresses approved to execute order slices. */
    mapping(address => bool) public isAnboto;
    /** @notice Tracks how much each order is already fulfilled. */
    mapping(bytes => uint256) public orderFulfilledAmount;

    /** @notice Address where CoW settlement contract is deployed. */
    address public immutable cowSettlementContract;
    /** @notice Address of approved Anboto CoW solver. */
    address public anbotoCowSolver;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Contract constructor setting contract domain name and version,
     * and other state.
     * @param _cowSettlementContract Address where CoW settlement contract is deployed.
     * @param _anbotoCowSolver Address of approved Anboto CoW solver.
     */
    constructor(address _cowSettlementContract, address _anbotoCowSolver)
        EIP712("AnbotoExecV2", "2")
    {
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
     * - should be called with gas price under limit specified by order
     * - should be called with order fee under max fee amount
     * - should be called with different token order input and output tokens
     * - should be called with valid signature; order is signed by maker and is unchanged
     * - quote sell amount should not over fulfill order
     * - quote buy amount should be over limit specified by order
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

        // Execute the swap.
        inputToken.safeTransferFrom(_maker, address(this), sliceInputAmount);
        inputToken.safeApprove(_quote.spender, sliceInputAmount);
        {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory data) = _quote.swapTarget.call(
                _quote.swapCallData
            );
            if (!success) revert(getRevertMsg(data));
        }

        // Get the balance after the swap.
        // Equals amount of input tokens that were pulled from maker but not swapped.
        swapInputBalance = inputToken.balanceOf(address(this)) - swapInputBalance;
        // Equals amount of output tokens that were obtained in the swap.
        swapOutputBalance = outputToken.balanceOf(address(this)) - swapOutputBalance;

        // If input tokens went unspent, return them and update balances.
        if (swapInputBalance > 0) {
            sliceInputAmount -= swapInputBalance;
            orderFulfilledAmount[_sig] -= swapInputBalance;
            inputToken.safeTransfer(_maker, swapInputBalance);
            inputToken.safeApprove(_quote.spender, 0);
        }

        // Check if enough output tokens were received by the swap.
        checkOutputAmount(_order, sliceInputAmount, swapOutputBalance);

        // Transfer output tokens (minus fees) to the maker.
        outputToken.safeTransfer(
            _maker,
            swapOutputBalance - getFee(swapOutputBalance, _order.feeAmount)
        );

        emit OrderExecuted(
            _maker,
            _sig,
            address(inputToken),
            address(outputToken),
            sliceInputAmount,
            swapOutputBalance
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
     * - should be called with order fee under max fee amount
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

        // Update balance and verify settlement.
        orderFulfilledAmount[_sig] += sellAmount;
        checkOrderTotal(_order, _sig);
        checkOutputAmount(_order, sellAmount, buyAmount);

        // Settle order.
        inputToken.safeTransferFrom(_maker, cowSettlementContract, sellAmount);
        outputToken.safeTransferFrom(cowSettlementContract, address(this), buyAmount);

        // Transfer output tokens (minus fees) to the maker.
        outputToken.safeTransfer(_maker, buyAmount - getFee(buyAmount, _order.feeAmount));

        emit CowSettled(
            _maker,
            _sig,
            address(inputToken),
            address(outputToken),
            sellAmount,
            buyAmount
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
            _tokens[i].transfer(_claimTo, amountToClaim);

            emit FeesClaimed(_claimTo, address(_tokens[i]), amountToClaim);
        }
    }

    /* ========== HELPERS ========== */

    /**
     * @notice Checks validitiy of order signature.
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
                    _order.feeAmount,
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
     * @dev Calculates fee owed to Anboto.
     * @param amount Amount of tokens bought.
     * @param fee Fee in percents, where 1_00 equals one percent.
     * @return Fee owed in output tokens.
     */
    function getFee(uint256 amount, uint256 fee) private pure returns (uint256) {
        return (amount * fee) / FULL_PERCENT;
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
            _order.feeAmount <= MAX_FEE,
            "AnbotoExecV2::validateOrder: Fee too high."
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
            _boughtAmount >= (_order.outMin * _soldAmount) / _order.totalAmount,
            "AnbotoExecV2::checkOutputAmount: Output amount too low."
        );
    }
}
// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./libraries/Errors.sol";
import "./libraries/Transfers.sol";
import "./interfaces/IViaRouter.sol";
import "./interfaces/external/IAllowanceTransfer.sol";

contract GaslessRelay is Ownable, EIP712 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeCast for uint256;

    // CONSTANTS

    /// @notice EIP712 typehash used for transfers
    bytes32 public constant TRANSFER_CALL_TYPEHASH =
        keccak256(
            "TransferCall(address token,address to,uint256 amount,uint256 fee,uint256 nonce)"
        );

    /// @notice EIP712 typehash used for executions
    bytes32 public constant EXECUTION_CALL_TYPEHASH =
        keccak256(
            "ExecutionCall(address token,uint256 amount,address quoter,bytes quoteData,uint256 fee,bytes executionData,uint256 value)"
        );

    /// @notice EIP712 typehash used for batch calls
    bytes32 public constant BATCH_CALL_TYPEHASH =
        keccak256(
            "BatchCall(TransferCall[] transferCalls,ExecutionCall[] executionCalls)ExecutionCall(address token,uint256 amount,address quoter,bytes quoteData,uint256 fee,bytes executionData,uint256 value)TransferCall(address token,address to,uint256 amount,uint256 fee,uint256 nonce)"
        );

    // STORAGE

    /// @notice Address of ViaRouter contract
    address public immutable router;

    /// @notice Address of Permit2 contract
    address public immutable permit2;

    /// @notice Mapping of transfer nonces for accounts to them being used
    mapping(address => mapping(uint256 => bool)) public nonceUsed;

    /// @notice Mapping of addresses to their allowed permit selector
    mapping(address => bytes4) public permitSelectors;

    /// @notice Structure describing transfer call
    /// @param token Token to transfer
    /// @param to Address to transfer to
    /// @param amount Amount to transfer
    /// @param fee Fee to collect (on top of amount)
    /// @param nonce Transfer's nonce (to avoid double-spending)
    struct TransferCall {
        address token;
        address to;
        uint256 amount;
        uint256 fee;
        uint256 nonce;
    }

    /// @notice Structure describing execution call
    /// @param token Token to transfer
    /// @param amount Amount to transfer
    /// @param quoter Address of the contract used to quote incoming amount
    /// @param quoteData Calldata used for quote
    /// @param fee Fee to collect (on top of amount)
    /// @param executionData Calldata for ViaRouter
    /// @param value Value to transfer
    struct ExecutionCall {
        address token;
        uint256 amount;
        address quoter;
        bytes quoteData;
        uint256 fee;
        bytes executionData;
        uint256 value;
    }

    // EVENTS

    /// @notice Event emitted when gasless transfer is performed
    event Transfer(address from, TransferCall call);

    /// @notice Event emitted when gasless execution is performed
    event Execution(address from, ExecutionCall call);

    /// @notice Event emitted when funds are withdrawn from contract
    event Withdrawn(IERC20 token, address to, uint256 amount);

    /// @notice Event emitted when permit selector is set for some token
    event PermitSelectorSet(address token, bytes4 selector);

    // CONSTRUCTOR

    /// @notice Contract constructor
    /// @param router_ Address of ViaRouter contract
    /// @param permit2_ Address of Permit2 contract
    constructor(address router_, address permit2_)
        EIP712("Transfer Money", "1.0.0")
    {
        router = router_;
        permit2 = permit2_;
    }

    // PUBLIC FUNCTIONS

    /// @notice Function used to perform transfer
    /// @param call TransferCall struct
    /// @param usePermit2 Use Permit2 for transfer
    /// @param sig EIP712 signature by `from` account
    /// @param permit Off-chain permit calldata for given token
    function transfer(
        TransferCall calldata call,
        bool usePermit2,
        bytes calldata sig,
        bytes calldata permit
    ) public {
        // Determine sender
        address from = msg.sender;
        if (sig.length > 0) {
            bytes32 digest = _hashTypedDataV4(_hashTransferCall(call));
            from = ECDSA.recover(digest, sig);
        }

        // Execute permit if required
        if (permit.length > 0) {
            _permit(call.token, permit, usePermit2);
        }

        // Execute transfer
        _transfer(from, call, usePermit2);
    }

    /// @notice Function used to perform execution
    /// @param call ExecutionCall struct
    /// @param usePermit2 Use Permit2 for transfer
    /// @param sig EIP712 signature by `from` account
    function execute(
        ExecutionCall calldata call,
        bool usePermit2,
        bytes calldata sig,
        bytes calldata permit
    ) public payable {
        // Determine sender
        address from = msg.sender;
        if (sig.length > 0) {
            bytes32 digest = _hashTypedDataV4(_hashExecutionCall(call));
            from = ECDSA.recover(digest, sig);
        }

        // Check for value
        require(msg.value == call.value, Errors.INVALID_MESSAGE_VALUE);

        // Execute permit if required
        if (permit.length != 0) {
            _permit(call.token, permit, usePermit2);
        }

        // Execute request
        _execute(from, call, usePermit2);
    }

    /// @notice Function to call a batch of transfers and executions
    /// @param transferCalls Array of transfer calls
    /// @param executionCalls Array of execution calls
    /// @param sig EIP712 signature of call by `from` account
    /// @param permitTokens List of tokens to execute permits on
    /// @param permits Permits to execute
    function batchCall(
        TransferCall[] calldata transferCalls,
        ExecutionCall[] calldata executionCalls,
        bytes calldata sig,
        address[] calldata permitTokens,
        bytes[] calldata permits
    ) external payable {
        // Determine sender
        address from = msg.sender;
        if (sig.length > 0) {
            bytes32 digest = _hashTypedDataV4(
                _hashBatchCall(transferCalls, executionCalls)
            );
            from = ECDSA.recover(digest, sig);
        }

        // Check total value
        uint256 totalValue;
        for (uint256 i = 0; i < executionCalls.length; i++) {
            totalValue += executionCalls[i].value;
        }
        require(totalValue == msg.value, Errors.INVALID_MESSAGE_VALUE);

        // Check that nonce sequence is valid (only 0th should be checked)
        require(
            transferCalls[0].nonce != type(uint256).max,
            Errors.INVALID_NONCE
        );
        for (uint256 i = 1; i < transferCalls.length; i++) {
            require(
                transferCalls[i].nonce == type(uint256).max,
                Errors.INVALID_NONCE
            );
        }

        // Check permits lenghts match
        require(permitTokens.length == permits.length, Errors.LENGHTS_MISMATCH);

        // Execute permits
        for (uint256 i = 0; i < permitTokens.length; i++) {
            _permit(permitTokens[i], permits[i], false);
        }

        // Process transfer calls
        for (uint256 i = 0; i < transferCalls.length; i++) {
            _transfer(from, transferCalls[i], false);
        }

        // Process executions calls
        for (uint256 i = 0; i < executionCalls.length; i++) {
            _execute(from, executionCalls[i], false);
        }
    }

    // RESTRICTED FUNCTIONS

    /// @notice Owner's function to withdraw collected fees
    /// @param token Token to transfer
    /// @param to Address to transfer to
    /// @param amount Amount to transfer
    function withdraw(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner {
        token.safeTransfer(to, amount);

        emit Withdrawn(token, to, amount);
    }

    /// @notice Owner's function to set permit selector for some tokens
    /// @param tokens List of tokens to set selectors for
    /// @param selectors List of permit selectors for respective tokens
    function setPermitSelectors(
        address[] calldata tokens,
        bytes4[] calldata selectors
    ) external onlyOwner {
        require(tokens.length == selectors.length, Errors.LENGHTS_MISMATCH);

        for (uint256 i = 0; i < tokens.length; i++) {
            _setPermitSelector(tokens[i], selectors[i]);
        }
    }

    // INTERNAL FUNCTIONS

    /// @notice Function used to perform gasless transfer
    /// @param from Address to transfer from
    /// @param call TransferCall struct
    /// @param usePermit2 Use Permit2 contract for transfer
    function _transfer(
        address from,
        TransferCall calldata call,
        bool usePermit2
    ) private {
        if (call.nonce != type(uint256).max) {
            // Check that nonce was not used yet
            require(!nonceUsed[from][call.nonce], Errors.NONCE_ALREADY_USED);

            // Mark nonce as used
            nonceUsed[from][call.nonce] = true;
        }

        // Transfer amount and fee
        if (usePermit2) {
            IAllowanceTransfer(permit2).transferFrom(
                from,
                call.to,
                call.amount.toUint160(),
                call.token
            );
            if (call.fee > 0) {
                IAllowanceTransfer(permit2).transferFrom(
                    from,
                    address(this),
                    call.fee.toUint160(),
                    call.token
                );
            }
        } else {
            IERC20(call.token).safeTransferFrom(from, call.to, call.amount);
            if (call.fee > 0) {
                IERC20(call.token).safeTransferFrom(
                    from,
                    address(this),
                    call.fee
                );
            }
        }

        // Emit event
        emit Transfer(from, call);
    }

    /// @notice Function used to perform gasless transfer
    /// @param from Address to transfer from
    /// @param call ExecutionCall struct
    /// @param usePermit2 Use Permit2 for transfer
    function _execute(
        address from,
        ExecutionCall calldata call,
        bool usePermit2
    ) private {
        // Check that execution selector is correct
        bytes4 selector = bytes4(call.executionData);
        require(
            selector == IViaRouter.execute.selector ||
                selector == IViaRouter.executeNew.selector,
            Errors.INVALID_ROUTER_SELECTOR
        );

        // Detemite amount (through quoter if required) and execution data
        uint256 amount = call.amount;
        if (call.quoter != address(0)) {
            bytes memory response = call.quoter.functionStaticCall(
                call.quoteData
            );
            (amount) = abi.decode(response, (uint256));
        }

        // Transfer amount and fee to relay contract
        if (usePermit2) {
            IAllowanceTransfer(permit2).transferFrom(
                from,
                address(this),
                (amount + call.fee).toUint160(),
                call.token
            );
        } else {
            IERC20(call.token).safeTransferFrom(
                from,
                address(this),
                amount + call.fee
            );
        }

        // Approve router for spending
        Transfers.approve(call.token, router, amount);

        // Execute router call
        router.functionCallWithValue(call.executionData, call.value);

        // Emit event
        emit Execution(from, call);
    }

    /// @notice Internal function to set permit selector for some token
    /// @param token Address of the token
    /// @param selector Permit function selector
    function _setPermitSelector(address token, bytes4 selector) private {
        permitSelectors[token] = selector;

        emit PermitSelectorSet(token, selector);
    }

    // INTERNAL VIEW FUNCTIONS

    function _hashTransferCall(TransferCall calldata transferCall)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    TRANSFER_CALL_TYPEHASH,
                    transferCall.token,
                    transferCall.to,
                    transferCall.amount,
                    transferCall.fee,
                    transferCall.nonce
                )
            );
    }

    function _hashExecutionCall(ExecutionCall calldata executionCall)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EXECUTION_CALL_TYPEHASH,
                    executionCall.token,
                    executionCall.amount,
                    executionCall.quoter,
                    keccak256(executionCall.quoteData),
                    executionCall.fee,
                    keccak256(executionCall.executionData),
                    executionCall.value
                )
            );
    }

    /// @notice Internal function that hashes batch call according to EIP712
    /// @param transferCalls Array of transfer calls
    /// @param executionCalls Array of execution calls
    function _hashBatchCall(
        TransferCall[] calldata transferCalls,
        ExecutionCall[] calldata executionCalls
    ) private pure returns (bytes32) {
        // Hash transfer calls
        bytes32[] memory transferCallHashes = new bytes32[](
            transferCalls.length
        );
        for (uint256 i = 0; i < transferCalls.length; i++) {
            transferCallHashes[i] = _hashTransferCall(transferCalls[i]);
        }

        // Hash execution calls
        bytes32[] memory executionCallHashes = new bytes32[](
            executionCalls.length
        );
        for (uint256 i = 0; i < executionCalls.length; i++) {
            executionCallHashes[i] = _hashExecutionCall(executionCalls[i]);
        }

        // Hash batch
        return
            keccak256(
                abi.encode(
                    BATCH_CALL_TYPEHASH,
                    keccak256(abi.encodePacked(transferCallHashes)),
                    keccak256(abi.encodePacked(executionCallHashes))
                )
            );
    }

    /// @notice Internal function that executes permit on given token, checking for selector
    /// @param token Address of the token to permit on
    /// @param permit Permit calldata
    /// @param usePermit2 Use Permit2 contract
    function _permit(
        address token,
        bytes calldata permit,
        bool usePermit2
    ) private {
        address target;
        if (usePermit2) {
            require(
                IAllowanceTransfer.permit.selector == bytes4(permit),
                Errors.INVALID_PERMIT_SELECTOR
            );
            target = permit2;
        } else {
            require(
                permitSelectors[token] == bytes4(permit),
                Errors.INVALID_PERMIT_SELECTOR
            );
            target = token;
        }

        target.functionCall(permit);
    }
}
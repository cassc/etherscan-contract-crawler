// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./libraries/Errors.sol";
import "./libraries/Transfers.sol";
import "./interfaces/IViaRouter.sol";

contract GaslessRelay is Ownable, EIP712 {
    using SafeERC20 for IERC20;
    using Address for address;

    // CONSTANTS

    /// @notice EIP712 typehash used for transfers
    bytes32 public constant TRANSFER_TYPEHASH =
        keccak256(
            "Transfer(address token,address to,uint256 amount,uint256 fee,uint256 nonce)"
        );

    /// @notice EIP712 typehash used for executions
    bytes32 public constant EXECUTE_TYPEHASH =
        keccak256(
            "Execute(address token,uint256 amount,uint256 fee,bytes executionData)"
        );

    bytes32 public constant BATCH_CALL_TYPEHASH =
        keccak256(
            "BatchCall(address from,TransferCall[] transferCalls,ExecutionCall[] executionCalls,uint256 nonce)ExecutionCall(address token,uint256 amount,uint256 fee,bytes executionData,uint256 value)TransferCall(address token,address to,uint256 amount,uint256 fee)"
        );

    /// @notice EIP712 typehash used for batch call transfer call
    bytes32 public constant TRANSFER_CALL_TYPEHASH =
        keccak256(
            "TransferCall(address token,address to,uint256 amount,uint256 fee)"
        );

    /// @notice EIP712 typehash used for batch call execute call
    bytes32 public constant EXECUTION_CALL_TYPEHASH =
        keccak256(
            "ExecutionCall(address token,uint256 amount,uint256 fee,bytes executionData,uint256 value)"
        );

    // STORAGE

    /// @notice Address of ViaRouter contract
    address public immutable router;

    /// @notice Mapping of transfer nonces for accounts to them being used
    mapping(address => mapping(uint256 => bool)) public nonceUsed;

    /// @notice Mapping of addresses to their allowed permit selector
    mapping(address => bytes4) public permitSelectors;

    struct TransferCall {
        address token;
        address to;
        uint256 amount;
        uint256 fee;
    }

    struct ExecutionCall {
        address token;
        uint256 amount;
        uint256 fee;
        bytes executionData;
        uint256 value;
    }

    // EVENTS

    /// @notice Event emitted when gasless transfer is performed
    event Transfer(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 fee
    );

    /// @notice Event emitted when gasless execution is performed
    event Execute(
        IERC20 token,
        address from,
        uint256 amount,
        uint256 fee,
        bytes executionData
    );

    /// @notice Event emitted when funds are withdrawn from contract
    event Withdrawn(IERC20 token, address to, uint256 amount);

    /// @notice Event emitted when permit selector is set for some token
    event PermitSelectorSet(address token, bytes4 selector);

    // CONSTRUCTOR

    /// @notice Contract constructor
    /// @param router_ Address of ViaRouter contract
    constructor(address router_) EIP712("Via Gasless Relay", "1.0.0") {
        router = router_;
    }

    // PUBLIC FUNCTIONS

    /// @notice Function used to perform transfer
    /// @param token Token to transfer
    /// @param from Address to transfer from
    /// @param to Address to transfer to
    /// @param amount Amount to transfer
    /// @param fee Fee to collect (on top of amount)
    /// @param nonce Transfer's nonce (to avoid double-spending)
    /// @param sig EIP712 signature by `from` account
    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        bytes calldata sig
    ) public {
        if (from != msg.sender) {
            // Check EIP712 signature
            bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        TRANSFER_TYPEHASH,
                        address(token),
                        to,
                        amount,
                        fee,
                        nonce
                    )
                )
            );
            require(
                ECDSA.recover(digest, sig) == from,
                Errors.INVALID_SIGNATURE
            );
        }

        _transfer(token, from, to, amount, fee, nonce);
    }

    /// @notice Function used to perform transfer with initial permit
    /// @param token Token to transfer
    /// @param from Address to transfer from
    /// @param to Address to transfer to
    /// @param amount Amount to transfer
    /// @param fee Fee to collect (on top of amount)
    /// @param nonce Transfer's nonce (to avoid double-spending)
    /// @param sig EIP712 signature by `from` account
    /// @param permit Off-chain permit calldata for given token
    function transferWithPermit(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        bytes calldata sig,
        bytes calldata permit
    ) external {
        _permit(address(token), permit);
        transfer(token, from, to, amount, fee, nonce, sig);
    }

    /// @notice Function used to perform execution
    /// @param token Token to transfer
    /// @param from Address to transfer from
    /// @param amount Amount to transfer
    /// @param fee Fee to collect (on top of amount)
    /// @param executionData Calldata for ViaRouter
    /// @param sig EIP712 signature by `from` account
    function execute(
        IERC20 token,
        address from,
        uint256 amount,
        uint256 fee,
        bytes calldata executionData,
        bytes calldata sig
    ) public payable {
        if (from != msg.sender) {
            // Check EIP712 signature
            bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        EXECUTE_TYPEHASH,
                        address(token),
                        amount,
                        fee,
                        keccak256(executionData)
                    )
                )
            );
            require(
                ECDSA.recover(digest, sig) == from,
                Errors.INVALID_SIGNATURE
            );
        }

        // Execute
        _execute(token, from, amount, fee, executionData, msg.value);
    }

    /// @notice Function used to perform execution
    /// @param token Token to transfer
    /// @param from Address to transfer from
    /// @param amount Amount to transfer
    /// @param fee Fee to collect (on top of amount)
    /// @param executionData Calldata for ViaRouter
    /// @param sig EIP712 signature by `from` account
    /// @param permit Off-chain permit calldata for given token
    function executeWithPermit(
        IERC20 token,
        address from,
        uint256 amount,
        uint256 fee,
        bytes calldata executionData,
        bytes calldata sig,
        bytes calldata permit
    ) external payable {
        _permit(address(token), permit);
        execute(token, from, amount, fee, executionData, sig);
    }

    /// @notice Function to call a batch of transfers and executions
    /// @param from Address to transfer from
    /// @param transferCalls Array of transfer calls
    /// @param executionCalls Array of execution calls
    /// @param nonce Call's nonce (to avoid double execution)
    /// @param sig EIP712 signature of call by `from` account
    /// @param permitTokens List of tokens to execute permits on
    /// @param permits Permits to execute
    function batchCall(
        address from,
        TransferCall[] calldata transferCalls,
        ExecutionCall[] calldata executionCalls,
        uint256 nonce,
        bytes calldata sig,
        address[] calldata permitTokens,
        bytes[] calldata permits
    ) external payable {
        if (from != msg.sender) {
            // Check EIP712 signature
            bytes32 digest = _hashBatchCall(
                from,
                transferCalls,
                executionCalls,
                nonce
            );
            require(
                ECDSA.recover(digest, sig) == from,
                Errors.INVALID_SIGNATURE
            );
        }

        // Check total value
        uint256 totalValue;
        for (uint256 i = 0; i < executionCalls.length; i++) {
            totalValue += executionCalls[i].value;
        }
        require(totalValue == msg.value, Errors.INVALID_MESSAGE_VALUE);

        // Check that nonce was not used yet
        require(!nonceUsed[from][nonce], Errors.NONCE_ALREADY_USED);

        // Mark nonce as used
        nonceUsed[from][nonce] = true;

        // Check permits lenghts match
        require(permitTokens.length == permits.length, Errors.LENGHTS_MISMATCH);

        // Execute permits

        for (uint256 i = 0; i < permitTokens.length; i++) {
            _permit(permitTokens[i], permits[i]);
        }

        // Process transfer calls
        for (uint256 i = 0; i < transferCalls.length; i++) {
            _transfer(
                IERC20(transferCalls[i].token),
                from,
                transferCalls[i].to,
                transferCalls[i].amount,
                transferCalls[i].fee,
                type(uint256).max
            );
        }

        // Process executions calls
        for (uint256 i = 0; i < executionCalls.length; i++) {
            _execute(
                IERC20(executionCalls[i].token),
                from,
                executionCalls[i].amount,
                executionCalls[i].fee,
                executionCalls[i].executionData,
                executionCalls[i].value
            );
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
            permitSelectors[tokens[i]] = selectors[i];

            emit PermitSelectorSet(tokens[i], selectors[i]);
        }
    }

    // INTERNAL FUNCTIONS

    /// @notice Function used to perform gasless transfer
    /// @param token Token to transfer
    /// @param from Address to transfer from
    /// @param to Address to transfer to
    /// @param amount Amount to transfer
    /// @param fee Fee to collect (on top of amount)
    /// @param nonce Transfer's nonce (to avoid double-spending), MaxUint256 passed for no-check
    function _transfer(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 fee,
        uint256 nonce
    ) private {
        if (nonce != type(uint256).max) {
            // Check that nonce was not used yet
            require(!nonceUsed[from][nonce], Errors.NONCE_ALREADY_USED);

            // Mark nonce as used
            nonceUsed[from][nonce] = true;
        }

        // Transfer amount and fee
        token.safeTransferFrom(from, to, amount);
        if (fee > 0) {
            token.safeTransferFrom(from, address(this), fee);
        }

        // Emit event
        emit Transfer(token, from, to, amount, fee);
    }

    /// @notice Function used to perform gasless transfer
    /// @param token Token to transfer
    /// @param from Address to transfer from
    /// @param amount Amount to transfer
    /// @param fee Fee to collect (on top of amount)
    /// @param executionData Calldata for ViaRouter
    /// @param value Value to pass
    function _execute(
        IERC20 token,
        address from,
        uint256 amount,
        uint256 fee,
        bytes memory executionData,
        uint256 value
    ) private {
        // Check that execution selector is correct
        bytes4 selector = bytes4(executionData);
        require(
            selector == IViaRouter.execute.selector ||
                selector == IViaRouter.executeSplit.selector,
            Errors.INVALID_ROUTER_SELECTOR
        );

        // Transfer amount and fee to relay contract
        token.safeTransferFrom(from, address(this), amount + fee);

        // Approve router for spending
        Transfers.approve(address(token), router, amount);

        // Execute router call
        router.functionCallWithValue(executionData, value);

        // Emit event
        emit Execute(token, from, amount, fee, executionData);
    }

    // INTERNAL VIEW FUNCTIONS

    /// @notice Internal function that hashes batch call according to EIP712
    /// @param from Address to transfer from
    /// @param transferCalls Array of transfer calls
    /// @param executionCalls Array of execution calls
    /// @param nonce Nonce used
    function _hashBatchCall(
        address from,
        TransferCall[] calldata transferCalls,
        ExecutionCall[] calldata executionCalls,
        uint256 nonce
    ) private view returns (bytes32) {
        bytes32[] memory transferCallHashes = new bytes32[](
            transferCalls.length
        );
        for (uint256 i = 0; i < transferCalls.length; i++) {
            transferCallHashes[i] = keccak256(
                abi.encode(
                    TRANSFER_CALL_TYPEHASH,
                    transferCalls[i].token,
                    transferCalls[i].to,
                    transferCalls[i].amount,
                    transferCalls[i].fee
                )
            );
        }
        bytes32[] memory executionCallHashes = new bytes32[](
            executionCalls.length
        );
        for (uint256 i = 0; i < executionCalls.length; i++) {
            executionCallHashes[i] = keccak256(
                abi.encode(
                    EXECUTION_CALL_TYPEHASH,
                    executionCalls[i].token,
                    executionCalls[i].amount,
                    executionCalls[i].fee,
                    keccak256(executionCalls[i].executionData),
                    executionCalls[i].value
                )
            );
        }
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        BATCH_CALL_TYPEHASH,
                        from,
                        keccak256(abi.encodePacked(transferCallHashes)),
                        keccak256(abi.encodePacked(executionCallHashes)),
                        nonce
                    )
                )
            );
    }

    /// @notice Internal function that executes permit on given token, checking for selector
    /// @param token Address of the token to permit on
    /// @param permit Permit calldata
    function _permit(address token, bytes calldata permit) private {
        require(
            permitSelectors[token] == bytes4(permit),
            Errors.INVALID_PERMIT_SELECTOR
        );
        token.functionCall(permit);
    }
}
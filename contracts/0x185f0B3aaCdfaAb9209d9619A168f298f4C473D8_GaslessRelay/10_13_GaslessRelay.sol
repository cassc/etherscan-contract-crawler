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

    // STORAGE

    /// @notice Address of ViaRouter contract
    address public immutable router;

    /// @notice Mapping of transfer nonces for accounts to them being used
    mapping(address => mapping(uint256 => bool)) public nonceUsed;

    // EVENTS

    /// @notice Event emitted when gasless transfer is performed
    event Transfer(IERC20 token, address from, address to, uint256 amount);

    /// @notice Event emitted when gasless execution is performed
    event Execute(
        IERC20 token,
        address from,
        uint256 amount,
        bytes executionData
    );

    // CONSTRUCTOR

    /// @notice Contract constructor
    /// @param router_ Address of ViaRouter contract
    constructor(address router_) EIP712("Via Gasless Relay", "1.0.0") {
        router = router_;
    }

    // PUBLIC FUNCTIONS

    /// @notice Function used to perform gasless transfer
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
    ) external {
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
        require(ECDSA.recover(digest, sig) == from, Errors.INVALID_SIGNATURE);

        // Check that nonce was not used yet
        require(!nonceUsed[from][nonce], Errors.NONCE_ALREADY_USED);

        // Mark nonce as used
        nonceUsed[from][nonce] = true;

        // Transfer amount and fee
        token.safeTransferFrom(from, to, amount);
        token.safeTransferFrom(from, address(this), fee);

        // Emit event
        emit Transfer(token, from, to, amount);
    }

    /// @notice Function used to perform gasless transfer
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
    ) external payable {
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
        require(ECDSA.recover(digest, sig) == from, Errors.INVALID_SIGNATURE);

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
        router.functionCallWithValue(executionData, msg.value);

        // Emit event
        emit Execute(token, from, amount, executionData);
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
    }
}
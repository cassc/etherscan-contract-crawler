// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { EIP712 } from "./EIP712.sol";
import { Nonces } from "./Nonces.sol";

/// @title NativeMetaTransaction
/// @notice Functions that enables meta transactions
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
abstract contract NativeMetaTransaction is EIP712, Nonces {
    /// Precomputed typeHash as defined in EIP712
    /// keccak256("MetaTransaction(uint256 nonce,address from,bytes functionSignature)")
    bytes32 public constant META_TRANSACTION_TYPEHASH =
        0x23d10def3caacba2e4042e0c75d44a42d2558aabcf5ce951d0642a8032e1e653;

    /// Event that is emitted when a meta-transaction is executed
    /// @dev Useful for off-chain services to pick up these events
    /// @param userAddress Address of the user that sent the meta-transaction
    /// @param relayerAddress Address of the relayer that executed the meta-transaction
    /// @param functionSignature Signature of the function
    event MetaTransactionExecuted(
        address indexed userAddress,
        address payable indexed relayerAddress,
        bytes functionSignature
    );

    /// @dev Function call is not successful
    error FunctionCallError();

    /// @dev Error thrown when invalid signer
    error InvalidSigner();

    /// Meta transaction structure.
    /// No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
    /// He should call the desired function directly in that case.
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    /// @notice Executes a meta transaction in the context of the signer
    /// Allows a relayer to send another user's transaction and pay the gas
    /// @param userAddress Address of the user the sender is performing on behalf of
    /// @param functionSignature The signature of the user
    /// @param sigR Output of the ECDSA signature
    /// @param sigS Output of the ECDSA signature
    /// @param sigV recovery identifier
    /// @return data encoded return data of the underlying function call
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external returns (bytes memory data) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: _nonces[userAddress]++,
            from: userAddress,
            functionSignature: functionSignature
        });

        _verifyMetaTx(userAddress, metaTx, sigV, sigR, sigS);

        // Appends userAddress at the end to extract it from calling context
        // solhint-disable-next-line avoid-low-level-calls
        (bool isSuccess, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );

        if (!isSuccess) {
            revert FunctionCallError();
        }

        emit MetaTransactionExecuted(userAddress, payable(msg.sender), functionSignature);

        return returnData;
    }

    /// @notice verify if the meta transaction is valid
    /// @dev Performs some validity check and checks if the signature matches the hash struct
    /// See EIP712.sol for details about `_verifySig`
    /// @return isValid bool that is true if the signature is valid. False if otherwise
    function _verifyMetaTx(
        address signer,
        MetaTransaction memory metaTx,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool isValid) {
        if (signer == address(0)) {
            revert InvalidSigner();
        }

        bytes32 hashStruct = keccak256(
            abi.encode(META_TRANSACTION_TYPEHASH, metaTx.nonce, metaTx.from, keccak256(metaTx.functionSignature))
        );

        return _verifySig(signer, hashStruct, v, r, s);
    }
}
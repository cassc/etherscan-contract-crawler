// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./EIP712Base.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
@title Interface to enable MetaTransactions
 */
contract EIP712MetaTransaction is EIP712Base {
    using Address for address;

    bytes32 private constant META_TRANSACTION_TYPEHASH =
    // solium-disable-next-line
    keccak256("MetaTransaction(uint256 nonce,address from,bytes functionSignature)");

    event MetaTransactionExecuted(address indexed _userAddress, address payable indexed _relayerAddress, bytes _functionSignature);

    mapping(address => uint256) public nonces;

    /**
     @dev Meta transaction structure.
     @dev No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     @dev He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    /**
    @notice Executes a MetaTransaction
    @param _userAddress The address of the user
    @param _functionSignature The signature of the function
    @param _sigR ECDSA signature
    @param _sigS ECDS signature
    @param _sigV Recovery ID signature
     */
    function executeMetaTransaction(
        address _userAddress,
        bytes memory _functionSignature,
        bytes32 _sigR,
        bytes32 _sigS,
        uint8 _sigV
    ) external payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction(nonces[_userAddress], _userAddress, _functionSignature);

        require(
            verify(_userAddress, metaTx, _sigR, _sigS, _sigV),
            "EIP712MetaTransaction: Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[_userAddress]++;

        emit MetaTransactionExecuted(_userAddress, payable(msg.sender), _functionSignature);

        // Append userAddress and relayer address at the end to extract it from calling context
        bytes memory returnData = address(this).functionCall(abi.encodePacked(_functionSignature, _userAddress));

        return returnData;
    }

    /**
    @notice Hashes a meta transaction
    @param _metaTx The MetaTransaction struct
    @return bytes Representing the hashed meta transaction
     */
    function hashMetaTransaction(MetaTransaction memory _metaTx) internal pure returns (bytes32) {
        return
        keccak256(
            abi.encode(META_TRANSACTION_TYPEHASH, _metaTx.nonce, _metaTx.from, keccak256(_metaTx.functionSignature))
        );
    }

    /**
    @notice Returns the message sender of a transaction, not the relayer
    @return sender Representing the message sender
     */
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;

            // solium-disable-next-line
            assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = payable(msg.sender);
        }

        return sender;
    }

    /**
    @notice Gets the nonce of a particular address
    @param _user Address of the user
    @return uint256 Representing the nonce of a particular address
     */
    function getNonce(address _user) external view returns (uint256) {
        return nonces[_user];
    }

    /**
    @notice Verifies the meta transaction being executed
    @param _signer Address of transaction's signer
    @param _metaTx The MetaTransaction struct
    @param _sigR ECDSA signature
    @param _sigS ECDS signature
    @param _sigV Recovery ID signature
    @return bool Representing whether or not the transaction is valid
     */
    function verify(
        address _signer,
        MetaTransaction memory _metaTx,
        bytes32 _sigR,
        bytes32 _sigS,
        uint8 _sigV
    ) internal view returns (bool) {
        require(_signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        // Github: https://github.com/OpenZeppelin/openzeppelin-sdk/blob/master/packages/lib/contracts/cryptography/ECDSA.sol

        // For 's'
        if (uint256(_sigS) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return false;
        }

        // For 'v'
        if (_sigV != 27 && _sigV != 28) {
            return false;
        }

        return _signer == ecrecover(toTypedMessageHash(hashMetaTransaction(_metaTx)), _sigV, _sigR, _sigS);
    }
}
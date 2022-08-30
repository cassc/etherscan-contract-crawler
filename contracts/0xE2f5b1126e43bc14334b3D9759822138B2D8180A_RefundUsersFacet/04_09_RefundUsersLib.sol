// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

pragma solidity ^0.8.0;

library RefundUsersLib {
    bytes32 constant REFUND_USERS_FACET_STORAGE =
        keccak256("refund.users.facet.storage");

    address constant REFUND_APPROVER =
        0x806356BC6911630748Ef0315EF3ee966eC308EDb;

    struct RefundUsersStorage {
        uint256 nonce;
    }

    function refundUsersStorage()
        internal
        pure
        returns (RefundUsersStorage storage s)
    {
        bytes32 position = REFUND_USERS_FACET_STORAGE;
        assembly {
            s.slot := position
        }
    }

    function _verifySingleRefundSig(
        address[] memory _recipients,
        uint256 _value,
        bytes memory _approvalSignature
    ) internal view {
        bytes memory signedBytes = abi.encode(
            _recipients,
            _value,
            block.chainid,
            address(this),
            refundUsersStorage().nonce
        );
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(signedBytes);
        address signer = ECDSA.recover(ethHash, _approvalSignature);
        require(signer == REFUND_APPROVER, "RefundUsers: invalid signature");
    }

    function _verifyMultiRefundSig(
        address[] memory _recipients,
        uint256[] memory _values,
        bytes memory _approvalSignature
    ) internal view {
        // encode the chain and address to prevent signature replay
        bytes memory signedBytes = abi.encode(
            _recipients,
            _values,
            block.chainid,
            address(this),
            refundUsersStorage().nonce
        );
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(signedBytes);
        address signer = ECDSA.recover(ethHash, _approvalSignature);
        require(signer == REFUND_APPROVER, "RefundUsers: invalid signature");
    }

    function singleValueEthRefund(
        address[] memory _recipients,
        uint256 _value,
        bytes memory _approvalSignature
    ) internal {
        uint256 gasAtStart = gasleft();
        require(_value != 0, "RefundUsers: Cannot send zero value eth");
        require(_recipients.length != 0, "RefundUsers: empty receivers");
        _verifySingleRefundSig(_recipients, _value, _approvalSignature);

        for (uint256 i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0)) {
                payable(_recipients[i]).transfer(_value);
            }
        }

        // increment the nonce
        refundUsersStorage().nonce += 1;

        // refund the sender gas
        uint256 gasSpent = gasAtStart - gasleft() + 28925;
        payable(msg.sender).transfer(gasSpent * tx.gasprice);
    }

    function multiValueEthRefund(
        address[] memory _recipients,
        uint256[] memory _values,
        bytes memory _approvalSignature
    ) internal {
        uint256 gasAtStart = gasleft();
        require(
            _recipients.length == _values.length,
            "RefundUsers: receivers and values length mismatch"
        );
        require(_recipients.length != 0, "RefundUsers: empty receivers");
        _verifyMultiRefundSig(_recipients, _values, _approvalSignature);

        for (uint256 i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0) && _values[i] > 0) {
                payable(_recipients[i]).transfer(_values[i]);
            }
        }

        // increment the nonce
        refundUsersStorage().nonce += 1;

        // refund the sender gas
        uint256 gasSpent = gasAtStart - gasleft() + 28925;
        payable(msg.sender).transfer(gasSpent * tx.gasprice);
    }
}
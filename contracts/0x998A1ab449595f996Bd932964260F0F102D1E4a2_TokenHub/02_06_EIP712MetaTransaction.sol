// SPDX-License-Identifier: -- vitally.eth --

pragma solidity =0.8.21;

import "./EIP712Base.sol";

abstract contract EIP712MetaTransaction is EIP712Base {

    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );

    mapping(address => uint256) internal nonces;

    struct MetaTransaction {
		uint256 nonce;
		address from;
        bytes functionSignature;
	}

    function executeMetaTransaction(
        address _userAddress,
        bytes memory _functionSignature,
        bytes32 _sigR,
        bytes32 _sigS,
        uint8 _sigV
    )
        public
        payable
        returns(bytes memory)
    {
        MetaTransaction memory metaTx = MetaTransaction(
            {
                nonce: nonces[_userAddress],
                from: _userAddress,
                functionSignature: _functionSignature
            }
        );

        require(
            verify(
                _userAddress,
                metaTx,
                _sigR,
                _sigS,
                _sigV
            ), "EIP712MetaTransaction: INVALID_SIGNATURE"
        );

	    nonces[_userAddress] =
	    nonces[_userAddress] + 1;

        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(
                _functionSignature,
                _userAddress
            )
        );

        require(
            success,
            "EIP712MetaTransaction: INVALID_CALL"
        );

        emit MetaTransactionExecuted(
            _userAddress,
            payable(msg.sender),
            _functionSignature
        );

        return returnData;
    }

    function hashMetaTransaction(
        MetaTransaction memory _metaTx
    )
        internal
        pure
        returns (bytes32)
    {
		return keccak256(
		    abi.encode(
                META_TRANSACTION_TYPEHASH,
                _metaTx.nonce,
                _metaTx.from,
                keccak256(_metaTx.functionSignature)
            )
        );
	}

    function verify(
        address _user,
        MetaTransaction memory _metaTx,
        bytes32 _sigR,
        bytes32 _sigS,
        uint8 _sigV
    )
        internal
        view
        returns (bool)
    {
        address signer = ecrecover(
            toTypedMessageHash(
                hashMetaTransaction(_metaTx)
            ),
            _sigV,
            _sigR,
            _sigS
        );

        require(
            signer != address(0x0),
            "EIP712MetaTransaction: INVALID_SIGNATURE"
        );

		return signer == _user;
	}

    function msgSender()
        internal
        view
        returns(address sender)
    {
        if (msg.sender == address(this)) {

            bytes memory array = msg.data;
            uint256 index = msg.data.length;

            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }

        return sender;
    }

    function getNonce(
        address _user
    )
        external
        view
        returns(uint256 nonce)
    {
        nonce = nonces[_user];
    }
}
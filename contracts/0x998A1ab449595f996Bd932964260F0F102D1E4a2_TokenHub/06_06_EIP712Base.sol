// SPDX-License-Identifier: -- vitally.eth --

pragma solidity =0.8.21;

contract EIP712Base {

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        )
    );

    bytes32 internal domainSeperator;

    constructor(
        string memory _name,
        string memory _version
    ) {
        domainSeperator = keccak256(abi.encode(
			EIP712_DOMAIN_TYPEHASH,
			keccak256(bytes(_name)),
			keccak256(bytes(_version)),
			getChainID(),
			address(this)
		));
    }

    function getChainID()
        internal
        pure
        returns (uint256 id)
    {
		assembly {
			id := 1
		}
	}

    function getDomainSeperator()
        private
        view
        returns(bytes32)
    {
		return domainSeperator;
	}

    function toTypedMessageHash(
        bytes32 _messageHash
    )
        internal
        view
        returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                getDomainSeperator(),
                _messageHash
            )
        );
    }
}
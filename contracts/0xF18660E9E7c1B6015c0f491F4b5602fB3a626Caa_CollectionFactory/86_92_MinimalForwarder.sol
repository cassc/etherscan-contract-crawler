// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/MinimalForwarder.sol)

pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/**
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 */
contract MinimalForwarder is EIP712 {
    using ECDSA for bytes32;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) private _nonces;

    constructor() EIP712("MinimalForwarder", "0.0.1") {}

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        /* solhint-disable reason-string */
        require(verify(req, signature), "MinimalForwarder: signature does not match request");
        /* solhint-enable reason-string */
        _nonces[req.from] = req.nonce + 1;

        /* solhint-disable avoid-low-level-calls */
        (bool success, bytes memory returndata) = req.to.call{ gas: req.gas, value: req.value }(
            abi.encodePacked(req.data, req.from)
        );
        /* solhint-enable avoid-low-level-calls */

        require(success, string(returndata));

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            /* solhint-disable no-inline-assembly */
            assembly {
                invalid()
            }
            /* solhint-enable no-inline-assembly */
        }

        return (success, returndata);
    }

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }
}
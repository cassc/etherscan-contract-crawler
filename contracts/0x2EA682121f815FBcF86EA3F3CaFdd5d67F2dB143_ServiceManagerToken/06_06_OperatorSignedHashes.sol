// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ISignatureValidator {
    /// @dev Should return whether the signature provided is valid for the provided hash.
    /// @notice MUST return the bytes4 magic value 0x1626ba7e when function passes.
    ///         MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5).
    ///         MUST allow external calls.
    /// @param hash Hash of the data to be signed.
    /// @param signature Signature byte array associated with hash.
    /// @return magicValue bytes4 magic value.
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

/// @dev Provided zero address.
error ZeroOperatorAddress();

/// @dev Incorrect signature length provided.
/// @param signature Signature bytes.
/// @param provided Provided signature length.
/// @param expected Expected signature length.
error IncorrectSignatureLength(bytes signature, uint256 provided, uint256 expected);

/// @dev Hash is not validated.
/// @param operator Operator contract address.
/// @param msgHash Message hash.
/// @param signature Signature bytes associated with the message hash.
error HashNotValidated(address operator, bytes32 msgHash, bytes signature);

/// @dev Hash is not approved.
/// @param operator Operator address.
/// @param msgHash Message hash.
/// @param signature Signature bytes associated with the message hash.
error HashNotApproved(address operator, bytes32 msgHash, bytes signature);

/// @dev Obtained wrong operator address.
/// @param provided Provided address.
/// @param expected Expected address.
error WrongOperatorAddress(address provided, address expected);

/// @title OperatorSignedHashes - Smart contract for managing operator signed hashes
/// @author AL
/// @author Aleksandr Kuperman - <[email protected]>
contract OperatorSignedHashes {
    event OperatorHashApproved(address indexed operator, bytes32 hash);

    // Value for the contract signature validation: bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 constant internal MAGIC_VALUE = 0x1626ba7e;
    // Domain separator type hash
    bytes32 public constant DOMAIN_SEPARATOR_TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    // Unbond type hash
    bytes32 public constant UNBOND_TYPE_HASH =
        keccak256("Unbond(address operator,address serviceOwner,uint256 serviceId,uint256 nonce)");
    // Register agents type hash
    bytes32 public constant REGISTER_AGENTS_TYPE_HASH =
        keccak256("RegisterAgents(address operator,address serviceOwner,uint256 serviceId,bytes32 agentsData,uint256 nonce)");
    // Original domain separator value
    bytes32 public immutable domainSeparator;
    // Original chain Id
    uint256 public immutable chainId;
    // Name hash
    bytes32 public immutable nameHash;
    // Version hash
    bytes32 public immutable versionHash;

    // Name of a signing domain
    string public name;
    // Version of a signing domain
    string public version;

    // Map of operator address and serviceId => unbond nonce
    mapping(uint256 => uint256) public mapOperatorUnbondNonces;
    // Map of operator address and serviceId => register agents nonce
    mapping(uint256 => uint256) public mapOperatorRegisterAgentsNonces;
    // Mapping operator address => approved hashes status
    mapping(address => mapping(bytes32 => bool)) public mapOperatorApprovedHashes;

    /// @dev Contract constructor.
    /// @param _name Name of a signing domain.
    /// @param _version Version of a signing domain.
    constructor(string memory _name, string memory _version) {
        name = _name;
        version = _version;
        nameHash = keccak256(bytes(_name));
        versionHash = keccak256(bytes(_version));
        chainId = block.chainid;
        domainSeparator = _computeDomainSeparator();
    }

    /// @dev Verifies provided message hash against its signature.
    /// @param operator Operator address.
    /// @param msgHash Message hash.
    /// @param signature Signature bytes associated with the signed message hash.
    function _verifySignedHash(address operator, bytes32 msgHash, bytes memory signature) internal view {
        // Check for the operator zero address
        if (operator == address(0)) {
            revert ZeroOperatorAddress();
        }

        // Check for the signature length
        if (signature.length != 65) {
            revert IncorrectSignatureLength(signature, signature.length, 65);
        }

        // Decode the signature
        uint8 v = uint8(signature[64]);
        // For the correct ecrecover() function execution, the v value must be set to {0,1} + 27
        // Although v in a very rare case can be equal to {2,3} (with a probability of 3.73e-37%)
        // If v is set to just 0 or 1 when signing  by the EOA, it is most likely signed by the ledger and must be adjusted
        if (v < 4 && operator.code.length == 0) {
            // In case of a non-contract, adjust v to follow the standard ecrecover case
            v += 27;
        }
        bytes32 r;
        bytes32 s;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
        }

        address recOperator;
        // Go through signature cases based on the value of v
        if (v == 4) {
            // Contract signature case, where the address of the contract is encoded into r
            recOperator = address(uint160(uint256(r)));

            // Check for the signature validity in the contract
            if (ISignatureValidator(recOperator).isValidSignature(msgHash, signature) != MAGIC_VALUE) {
                revert HashNotValidated(recOperator, msgHash, signature);
            }
        } else if (v == 5) {
            // Case of an approved hash, where the address of the operator is encoded into r
            recOperator = address(uint160(uint256(r)));

            // Hashes have been pre-approved by the operator via a separate message, see operatorApproveHash() function
            if (!mapOperatorApprovedHashes[recOperator][msgHash]) {
                revert HashNotApproved(recOperator, msgHash, signature);
            }
        } else {
            // Case of ecrecover with the message hash for EOA signatures
            recOperator = ecrecover(msgHash, v, r, s);
        }

        // Final check is for the operator address itself
        if (recOperator != operator) {
            revert WrongOperatorAddress(recOperator, operator);
        }
    }

    /// @dev Approves message hash for the operator address.
    /// @param hash Provided message hash to approve.
    function operatorApproveHash(bytes32 hash) external {
        mapOperatorApprovedHashes[msg.sender][hash] = true;
        emit OperatorHashApproved(msg.sender, hash);
    }

    /// @dev Computes domain separator hash.
    /// @return Hash of the domain separator based on its name, version, chain Id and contract address.
    function _computeDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_SEPARATOR_TYPE_HASH,
                nameHash,
                versionHash,
                block.chainid,
                address(this)
            )
        );
    }

    /// @dev Gets the already computed domain separator of recomputes one if the chain Id is different.
    /// @return Original or recomputed domain separator.
    function getDomainSeparator() public view returns (bytes32) {
        return block.chainid == chainId ? domainSeparator : _computeDomainSeparator();
    }

    /// @dev Gets the unbond message hash for the operator.
    /// @param operator Operator address.
    /// @param serviceOwner Service owner address.
    /// @param serviceId Service Id.
    /// @param nonce Nonce for the unbond message from the pair of (operator | service Id).
    /// @return Computed message hash.
    function getUnbondHash(
        address operator,
        address serviceOwner,
        uint256 serviceId,
        uint256 nonce
    ) public view returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                getDomainSeparator(),
                keccak256(
                    abi.encode(
                        UNBOND_TYPE_HASH,
                        operator,
                        serviceOwner,
                        serviceId,
                        nonce
                    )
                )
            )
        );
    }

    /// @dev Gets the register agents message hash for the operator.
    /// @param operator Operator address.
    /// @param serviceOwner Service owner address.
    /// @param serviceId Service Id.
    /// @param agentInstances Agent instance addresses operator is going to register.
    /// @param agentIds Agent Ids corresponding to each agent instance address.
    /// @param nonce Nonce for the register agents message from the pair of (operator | service Id).
    /// @return Computed message hash.
    function getRegisterAgentsHash(
        address operator,
        address serviceOwner,
        uint256 serviceId,
        address[] memory agentInstances,
        uint32[] memory agentIds,
        uint256 nonce
    ) public view returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                getDomainSeparator(),
                keccak256(
                    abi.encode(
                        REGISTER_AGENTS_TYPE_HASH,
                        operator,
                        serviceOwner,
                        serviceId,
                        keccak256(abi.encode(agentInstances, agentIds)),
                        nonce
                    )
                )
            )
        );
    }

    /// @dev Checks if the hash provided by the operator is approved.
    /// @param operator Operator address.
    /// @param hash Message hash.
    /// @return True, if the hash provided by the operator is approved.
    function isOperatorHashApproved(address operator, bytes32 hash) external view returns (bool) {
        return mapOperatorApprovedHashes[operator][hash];
    }

    /// @dev Gets the (operator | service Id) nonce for the unbond message data.
    /// @param operator Operator address.
    /// @param serviceId Service Id.
    /// @return nonce Obtained nonce.
    function getOperatorUnbondNonce(address operator, uint256 serviceId) external view returns (uint256 nonce) {
        // operator occupies first 160 bits
        uint256 operatorService = uint256(uint160(operator));
        // serviceId occupies next 32 bits as serviceId is limited by the 2^32 - 1 value
        operatorService |= serviceId << 160;
        nonce = mapOperatorUnbondNonces[operatorService];
    }

    /// @dev Gets the (operator | service Id) nonce for the register agents message data.
    /// @param operator Operator address.
    /// @param serviceId Service Id.
    /// @return nonce Obtained nonce.
    function getOperatorRegisterAgentsNonce(address operator, uint256 serviceId) external view returns (uint256 nonce) {
        // operator occupies first 160 bits
        uint256 operatorService = uint256(uint160(operator));
        // serviceId occupies next 32 bits as serviceId is limited by the 2^32 - 1 value
        operatorService |= serviceId << 160;
        nonce = mapOperatorRegisterAgentsNonces[operatorService];
    }
}
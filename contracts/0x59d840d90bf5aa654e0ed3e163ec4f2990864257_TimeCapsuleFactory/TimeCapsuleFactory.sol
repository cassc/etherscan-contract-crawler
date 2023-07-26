/**
 *Submitted for verification at Etherscan.io on 2023-07-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)
/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}
library Strings {
    
    function toString(uint256 value) internal pure returns (string memory) {
        // from @openzeppelin String.sol
        unchecked {
            ////
            // uint256 length = Math.log10(value) + 1; =>
            // from @openzeppelin Math.sol
            uint256 length = 0;
            if (value >= 10**64) { value /= 10**64; length += 64; }
            if (value >= 10**32) { value /= 10**32; length += 32; }
            if (value >= 10**16) { value /= 10**16; length += 16; }
            if (value >= 10**8) { value /= 10**8; length += 8; }
            if (value >= 10**4) { value /= 10**4; length += 4; }
            if (value >= 10**2) { value /= 10**2; length += 2; }
            if (value >= 10**1) { length += 1; }
            length++;
            ////

            string memory buffer = new string(length);
            uint256 ptr;
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), "0123456789abcdef"))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }
}
/// @dev SYNONYMS: vault, capsule, timecapsule

interface IFeeSplitter {
    function splitERC20(address tokenAddress) external returns (bool);
}

interface ITimeCapsule {
        function initialize(
        address _newOwner,
        address _factoryAddress,
        IFeeSplitter _feeSplitterContract
    ) external;
}

/**
 * @title TimeCapsuleFactory
 * @notice Responsible for TimeCapsule contract deployment plus storage and use of recovery address hashes.
 */
contract TimeCapsuleFactory {

    struct OwnerCapsuleRecord {
        address capsuleAddress;
        bytes32 recoveryAddressHash;
    }
    mapping(address => OwnerCapsuleRecord) private capsules; // index address => capsule owner address
    mapping(bytes32 => address) private ownerHashes; // index bytes32 => keccack256 of vault owner address

    // validation: a recoveryAddressHash is "validated" when a matching entry exists in hashCapsuleAddresses
    mapping(bytes32 => address) private hashCapsuleAddresses; // index => recovery address hash (for reverse owner lookups)

    address private founder; // NOT AN ADMIN KEY -- Only used to allow contract creator to airdrop free capsules (promotional)
    address private timeCapsuleImplementationAddress;
    IFeeSplitter private NO_EXPECTATIONS; // splits 0.1% fees evenly between three project founders

    constructor(
        address _timeCapsuleImplementationAddress,
        IFeeSplitter _feeSplitterContract
    ) {
        founder = msg.sender;
        timeCapsuleImplementationAddress = _timeCapsuleImplementationAddress;
        NO_EXPECTATIONS = _feeSplitterContract;
    }

    /**
     * Consciously excluding receive/fallback functions
     * receive() external payable { }
     * fallback() external payable { }
     */

    modifier _onlyOwnersCapsule(address _owner) {
        require(
            msg.sender == capsuleAddressOf(_owner),
            "Invalid caller"
        );
        _;
    }

    event TimeCapsuleCreated(
        address owner,
        address capsuleAddress
    );

    event OwnerChanged(
        address capsuleAddress,
        address oldOwner,
        address newOwner
    );

    function predictedCapsuleAddress(address ownerAddress) public view returns (address predictedAddress) {
        predictedAddress = Clones.predictDeterministicAddress(timeCapsuleImplementationAddress, bytes32(abi.encode(ownerAddress)));
    }

    /**
     * Instantiates a new vault.
     * @param _newOwner address of the new Time Caposule's owner
     */
    function _instantiateTimeCapsule(address _newOwner) internal {
        require(
            capsules[_newOwner].capsuleAddress == address(0),
            "Capsule already assigned"
        );

        // _newOwner must not *be* an existing _and_ *validated* recovery address
        require(
           hashCapsuleAddresses[keccak256(abi.encodePacked(_newOwner))] == address(0),
           "Creator address is a validated recovery address"
        );
        /// @dev _recoveryAddressHash may be zero (unset)

        // instantiate new TimeCapsule (vault) contract
        /// @dev we use msg.sender as the salt for a deterministic vault deployment address
        address payable _capsuleAddress = payable(Clones.cloneDeterministic(
            timeCapsuleImplementationAddress, bytes32(abi.encode(msg.sender))
        ));

        try ITimeCapsule(_capsuleAddress).initialize(
            _newOwner,      //  address _newOwner
            address(this),  //  address _factoryAddress
            NO_EXPECTATIONS //  FeeSplitter NO_EXPECTATIONS
        ) {
            OwnerCapsuleRecord memory newCapsule = OwnerCapsuleRecord({
                capsuleAddress: _capsuleAddress,
                recoveryAddressHash: bytes32(0)
            });
            capsules[_newOwner] = newCapsule;
            bytes32 ownerHash = keccak256(abi.encodePacked(_newOwner));
            ownerHashes[ownerHash] = _newOwner;

            emit TimeCapsuleCreated(_newOwner, _capsuleAddress);
        } catch {
            revert("Capsule initialization failed");
        }
    }

    /**
     * Creates a vault with no recovery address.
     */
    function createTimeCapsule() public {
        _instantiateTimeCapsule(msg.sender);
    }

    /**
     * Creates a vault with a recovery address.
     * @param _recoveryAddressHash keccak256 (sha3) hash of recovery address
     */
    function createTimeCapsule(bytes32 _recoveryAddressHash) public {
        _instantiateTimeCapsule(msg.sender);
        capsules[msg.sender].recoveryAddressHash = _recoveryAddressHash;
    }

    /**
     * Returns the contract address of the owner's vault. (Each owner address can only have one vault.)
     * @param _owner address of vault owner
     */
    function capsuleAddressOf(address _owner) public view returns (address capsuleAddress) {
        capsuleAddress = capsules[_owner].capsuleAddress;
    }

    /**
     * Splits a 65 byte (130 nibble) 'raw' signature into R, S, V components.
     * @param _signature 65 byte (130 nibble) 'raw' signature
     * @return r signature R component
     * @return s signature S component
     * @return v signature V component
     */
    function _splitSignature(bytes memory _signature) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }

    /**
     * Recovers the address of the signer of a arbitrary length message.
     * @param _message the signed message
     * @param _signature signature
     */
    function _recoverSignerAddress(
        string memory _message,
        bytes memory _signature
    )
        private
        pure
        returns (address signerAddress)
    {
        if (_signature.length != 65) return address(0);

        bytes32 _messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                Strings.toString(bytes(_message).length),
                bytes(_message)
            )
        );

        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);
        signerAddress = ecrecover(_messageHash, v, r, s);
    }

    /**
     * Sets the vault's recovery address. Reverts if recovery address has been validated.
     * @notice internal function
     * @param _recoveryAddressHash keccak256 hash of recovery address
     */
    function _setRecoveryAddressHash(
        address _owner,
        bytes32 _recoveryAddressHash
    )
        internal
    {
        require(
            isRecoveryHashValidated(_owner) == false,
            "Duplicate validated recovery address"
        );
        capsules[_owner].recoveryAddressHash = _recoveryAddressHash;
    }

    /**
     * @notice internal function
     * @param _owner vault owner addres
     * @param _recoveryAddressHash keccak256 (sha3) hash of the recovery address being signed
     * @param _signature signature
     */
    function _validateRecoveryAddressHash(
        address _owner,
        bytes32 _recoveryAddressHash,
        bytes memory _signature
    )
        internal
    {
        require(
            ownerHashes[_recoveryAddressHash] == address(0),
            "Cannot own a vault"
        );
        require(
            hashCapsuleAddresses[_recoveryAddressHash] == address(0),
            "Already validated"
        );
        address signerAddress = _recoverSignerAddress(
            "CONFIRMING RECOVERY ADDRESS",
            _signature
        );
        require(
            keccak256(abi.encodePacked(signerAddress)) == _recoveryAddressHash,
            "Invalid signature"
        );
        bytes32 _existingRecoveryAddressHash = capsules[_owner].recoveryAddressHash;
        if (hashCapsuleAddresses[_existingRecoveryAddressHash] == _owner) {
            delete hashCapsuleAddresses[_existingRecoveryAddressHash];
        }

        // recoveryHash is "validated" when a matching record exists in hashCapsuleAddresses[]
        hashCapsuleAddresses[_recoveryAddressHash] = _owner;
    }

    /**
     * Sets (or re-sets) and validates the vault's recovery address by having it signed off-chain by
     * the recovery address private keys. NOTE: An unvalidated recovery address may only be set at vault
     * creation. Future setting of the address *requires* that it be validated immediately, using
     * this function.
     * @notice the requirement to separately validate a recovery address is both reduces onboarding
     * friction — and prevents certain style of DOS attack regarding use of another's address.
     * @param _owner vault owner addres
     * @param _recoveryAddressHash keccak256 (sha3) hash of the recovery address being signed
     * @param _signature signature
     */
    function validateRecoveryAddressHash(
        address _owner,
        bytes32 _recoveryAddressHash,
        bytes memory _signature
    )
        public
        _onlyOwnersCapsule(_owner)
    {
        _setRecoveryAddressHash(_owner, _recoveryAddressHash);
        _validateRecoveryAddressHash(
            _owner,
            _recoveryAddressHash,
            _signature
        );
    }

    /**
     * Verifies that the recovery address for the vault is indeed the one the being checked.
     * @param _owner address of vault owner
     * @param _addressHash keccak256 (sha3) hash of the recovery address
     */
    function checkRecoveryAddress(
        address _owner,
        bytes32 _addressHash
    )
        public
        view
        returns (bool confirmed)
    {
        confirmed = _addressHash == capsules[_owner].recoveryAddressHash;
    }

    /**
     * Returns true/false according to recovery address validation status.
     * @param _owner address of the vault owner
     */
    function isRecoveryHashValidated(address _owner)
        public view
        _onlyOwnersCapsule(_owner)
        returns (bool)
    {
        bytes32 _recoveryAddressHash = capsules[_owner].recoveryAddressHash;
        // hashCapsuleAddresses[_recoveryAddressHash] entry should only exist if hash is validated
        return hashCapsuleAddresses[_recoveryAddressHash] == _owner;
    }

    /**
     * Recovers ownership of a vault to the recovery address.
     * @notice Can only be executed by private key associated with recorded recovery address hash
     * @param _oldOwner address of the current (panic state) owner
     * @param _newOwner address of the new owner
     */
    function recoverOwnership(
        address _oldOwner,
        address _newOwner
    )
        public
        _onlyOwnersCapsule(_oldOwner)
    {
        require(
            capsules[_oldOwner].recoveryAddressHash == keccak256(abi.encodePacked(_newOwner)),
            "Invalid caller" // purposely vague revert message
        );

        capsules[_newOwner] = OwnerCapsuleRecord({
            capsuleAddress: msg.sender,
            recoveryAddressHash: bytes32(0)
        });
        delete capsules[_oldOwner];
        delete hashCapsuleAddresses[keccak256(abi.encodePacked(msg.sender))];

        delete ownerHashes[keccak256(abi.encodePacked(_oldOwner))];
        ownerHashes[keccak256(abi.encodePacked(msg.sender))] = msg.sender;

        emit OwnerChanged(
            msg.sender,
            _oldOwner,
            _newOwner
        );
    }
}
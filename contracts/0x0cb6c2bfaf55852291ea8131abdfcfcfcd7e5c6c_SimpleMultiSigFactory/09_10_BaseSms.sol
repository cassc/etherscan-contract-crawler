pragma solidity 0.8.18;

import "../interfaces/IERC1271.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';

// EIP1271 errors
error InvalidSignature(); // -----------------------| 0x8baa579f
error InvalidSignaturesCount(); // -----------------| 0x7be8d111
error IsNotOwner(); // -----------------------------| 0x65b023fd
error NonUniqueOrUnsortedSignatures(); // ----------| 0x55ab471a

// .execute() errors
error InvalidExecutor(); // ------------------------| 0x710c9497
error InnerTransactionFailed(); // -----------------| 0x29df4119

// .setOwners() errors
error InvalidOwnersLength(); // --------------------| 0x518c73ff
error InvalidThreshold(); // -----------------------| 0xaabd5a09
error DuplicateOwnerAdded(); // --------------------| 0x8d0e60ed
error UnauthorizedCaller(); // ---------------------| 0x5c427cd9

abstract contract BaseSms is IERC1271, IERC721Receiver, IERC1155Receiver {
    string public constant VERSION = "1.3.0";

    // EIP712 Precomputed hashes:
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)")
    bytes32 constant EIP712DOMAINTYPE_HASH = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;

    // keccak256("Simple MultiSig")
    bytes32 constant NAME_HASH = 0xb7a0bfa1b79f2443f4d73ebb9259cddbcd510b18be6fc4da7d1aa7b1786e73e6;

    // keccak256("1")
    bytes32 constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    // keccak256("MultiSigTransaction(address destination,uint256 value,bytes data,uint256 nonce,address executor,uint256 gasLimit)")
    bytes32 constant TXTYPE_HASH = 0x3ee892349ae4bbe61dce18f95115b5dc02daf49204cc602458cd4c1f540d56d7;

    // Signature salt, when they create a transaction it's used to verify
    bytes32 constant SALT = 0x251543af6a222378665a76fe38dbceae4871a070b7fdaf5c6c30cf758dc33cc0;

    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 constant internal EIP1271_MAGIC_VALUE = 0x1626ba7e;
    // Following reference implementation from official ERC1271 proposal
    bytes4 constant internal EIP1271_INVALID_SIGNATURE = 0xffffffff;
    uint8 constant internal MAX_OWNERS = 20;

    uint public nonce; // mutable state
    uint public threshold; // mutable state
    mapping(address => bool) isOwner; // mutable state
    address[] public ownersArr; // mutable state

    bytes32 DOMAIN_SEPARATOR; // hash for EIP712, computed from contract address

    event OwnersSet(uint threshold, address[] owners);
    event Execution(address indexed destination, uint value, bytes data, address indexed executor, uint gasLimit);
    event Deposit(address indexed sender, uint value);

    /**
        * Either called from the constructor (Base case) or init function (EIP-1167) to initialize the contract state
    */
    function contractInit(uint threshold_, address[] memory owners_, uint chainId) internal {
        setOwners_(threshold_, owners_);

        DOMAIN_SEPARATOR = keccak256(abi.encode(EIP712DOMAINTYPE_HASH, NAME_HASH, VERSION_HASH, chainId, this, SALT));
    }

    modifier verifyExecutor(address executor) {
        if (executor != msg.sender && executor != address(0)) {
            revert InvalidExecutor();
        }
        _;
    }

    function owners() external view returns (address[] memory) {
        return ownersArr;
    }

    // Note that owners_ must be strictly increasing, in order to prevent duplicates
    function setOwners_(uint threshold_, address[] memory owners_) private {
        if (owners_.length == 0 || owners_.length > MAX_OWNERS) {
            revert InvalidOwnersLength();
        }

        if (threshold_ == 0 || threshold_ > owners_.length) {
            revert InvalidThreshold();
        }

        // remove old owners from map
        for (uint i = 0; i < ownersArr.length; i++) {
            isOwner[ownersArr[i]] = false;
        }

        // add new owners to map
        address lastAdd = address(0);
        for (uint i = 0; i < owners_.length; i++) {
            if (owners_[i] <= lastAdd) {
                revert DuplicateOwnerAdded();
            }
            isOwner[owners_[i]] = true;
            lastAdd = owners_[i];
        }

        // set owners array and threshold
        ownersArr = owners_;
        threshold = threshold_;

        emit OwnersSet(threshold, ownersArr);
    }

    // Requires a quorum of owners to call from this contract using execute
    function setOwners(uint threshold_, address[] memory owners_) public virtual {
        if (msg.sender != address(this)) {
            revert UnauthorizedCaller();
        }
        setOwners_(threshold_, owners_);
    }

    // Note that address recovered from signatures must be strictly increasing, in order to prevent duplicates
    // @deprecated - Use "executeWithSignatures" instead
    function execute(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address destination,
        uint value,
        bytes memory data,
        address executor,
        uint gasLimit
    ) public virtual verifyExecutor(executor) {
        // Combine the legacy signature component arrays into a single bytes array
        bytes memory signatures = packSignatures(sigV, sigR, sigS);

        // Perform the execution, using the combined signatures
        _execute(signatures, destination, value, data, executor, gasLimit);
    }


    /*
        * @notice - Executes the transaction payload with the signatures provided
        * @dev - Note that address recovered from signatures must be strictly increasing, in order to prevent duplicates
    */
    function executeWithSignatures(
        bytes memory signatures,
        address destination,
        uint value,
        bytes memory data,
        address executor, uint gasLimit
    ) public virtual verifyExecutor(executor) {
        _execute(signatures, destination, value, data, executor, gasLimit);
    }


    /*
        * @notice - Helper function to executes the transaction payload with the signatures provided
        * @dev - Note when calling this function directly, the caller is responsible for validating the executor
    */
    function _execute(
        bytes memory signatures,
        address destination,
        uint value,
        bytes memory data,
        address executor,
        uint gasLimit
    ) internal {
        // EIP712 scheme: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
        bytes32 txInputHash = keccak256(
            abi.encode(TXTYPE_HASH, destination, value, keccak256(data), nonce, executor, gasLimit)
        );

        bytes32 totalHash = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, txInputHash));

        // Check the packed signatures are valid via ecrecover
        uint validSigCount = checkNSignatures(totalHash, signatures, threshold);
        bool isValidNSignatures = validSigCount == threshold;
        if (!isValidNSignatures) {
            revert InvalidSignaturesCount();
        }

        // If we make it here all signatures are valid signatures from owners.
        // Checks, effects & interactions pattern to prevent reentrancy
        nonce = nonce + 1;
        bool success = false;

        emit Execution(destination, value, data, executor, gasLimit);

        (success, ) = destination.call{value: value, gas: gasLimit}(data);

        if (!success) {
            revert InnerTransactionFailed();
        }
    }

    // EIP1271 function
    function isValidSignature(bytes32 hash, bytes memory signature) public view override virtual returns (bytes4) {
        uint validSigCount = checkNSignatures(hash, signature, threshold);
        bool isValid = validSigCount == threshold;
        return isValid ? EIP1271_MAGIC_VALUE : EIP1271_INVALID_SIGNATURE;
    }

    /**
       * @notice Packs together the signature arguments into a single bytes array in order of R, S, V
       * @param sigV Array of v values for each signature
       * @param sigR Array of r values for each signature
       * @param sigS Array of s values for each signature
    */
    function packSignatures(uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS) private pure returns (bytes memory signatures) {
        // Combine sigV, sigR, sigS into a single bytes memory signatures
        signatures = new bytes(sigR.length * 65);

        for (uint i = 0; i < sigR.length; i++) {
            assembly {
            // Offset of 32 bytes into signatures array, as it is reserved for the length of bytes
                let signaturesPointer := add(add(signatures, 0x20), mul(i, 65))

            // Initial offset of 32 bytes into sigR (as length is stored in first 32 bytes)
            // Increment offset by 32 bytes for each signature, as each sigR is 32 bytes long
                let sigRPointer := add(add(sigR, 0x20), mul(i, 0x20))
                let sigRValue := mload(sigRPointer)
                mstore(signaturesPointer, sigRValue)

            // For sigS, similar to sigR above, except for storing in the slot (32 bytes) after sigR
                let sigSPointer := add(add(sigS, 0x20), mul(i, 0x20))
                let sigSValue := mload(sigSPointer)
                mstore(add(signaturesPointer, 0x20), sigSValue)

            // For sigV, despite it being a uint8[] -> each slot is still 32 bytes
            // Elements in memory arrays in Solidity always occupy multiples of 32 bytes
                let sigVPointer := add(add(sigV, 0x20), mul(i, 0x20))
            // Bit masking with 0xff is necessary to truncate bytes -> bytes1
                let sigVValue := and(mload(sigVPointer), 0xff)
            // mstore8 as "v" is only one byte
                mstore8(add(signaturesPointer, 0x40), sigVValue)
            }
        }
    }

    /**
     * @notice Checks whether the signature provided is valid for the provided data and hash. Reverts otherwise.
   * @dev Since the EIP-1271 does an external call, be mindful of reentrancy attacks.
   * @param hash Hash of the data (could be either a message hash or transaction hash)
   * @param signatures Signature data that should be verified, contract signature (EIP-1271).
   * @param requiredSignatures Amount of required valid signatures.
   */
    function checkNSignatures(bytes32 hash, bytes memory signatures, uint256 requiredSignatures) internal view returns (uint256 signatureCount) {
        if (signatures.length != requiredSignatures * 65) {
            revert InvalidSignaturesCount();
        }

        uint8 v;
        bytes32 r;
        bytes32 s;

        signatureCount = 0;
        address previousAddress = address(0);

        for (uint i = 0; i < requiredSignatures; i++) {
            (v, r, s) = signatureSplit(signatures, i);

            if (v != 27 && v != 28) {
                revert InvalidSignature();
            }

            address recoveredAddress = ecrecover(hash, v, r, s);

            // Check if address is owner
            if (!isOwner[recoveredAddress]) {
                revert IsNotOwner();
            }

            // Check for duplicate address (sorted -> ascending order)
            if (recoveredAddress <= previousAddress) {
                revert NonUniqueOrUnsortedSignatures();
            }

            previousAddress = recoveredAddress;
            signatureCount += 1;
        }
    }

    /**
       * @notice Splits signature bytes into `uint8 v, bytes32 r, bytes32 s`.
       * @dev Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
       *      The signature format is a compact form of {bytes32 r}{bytes32 s}{uint8 v}
       *      Compact means uint8 is not padded to 32 bytes.
       * @param pos Which signature to read.
       *            A prior bounds check of this parameter should be performed, to avoid out of bounds access.
       * @param signatures Concatenated {r, s, v} signatures.
       * @return v Recovery ID or Safe signature type.
       * @return r Output value r of the signature.
       * @return s Output value s of the signature.
   */
    function signatureSplit(bytes memory signatures, uint256 pos) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
        /**
         * Here we are loading the last 32 bytes, including 31 bytes
         * of 's'. There is no 'mload8' to do this.
         * 'byte' is not working due to the Solidity parser, so lets
         * use the second best option, 'and'
         */
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    /**
        * @dev Shares supported interfaces that this contract supports
    */
    function supportsInterface(bytes4 interfaceID) external pure override returns (bool) {
        return interfaceID == type(IERC721Receiver).interfaceId
        || interfaceID == type(IERC1155Receiver).interfaceId
            || interfaceID == type(IERC165).interfaceId; // Also supporting ERC165 itself
    }

    /**
       * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
       * by `operator` from `from`, this function is called.
    */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
       * @dev Handles the receipt of a single ERC1155 token type. This function is
       * called at the end of a `safeTransferFrom` after the balance has been updated.
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /**
      * @dev Handles the receipt of a multiple ERC1155 token types. This function
      * is called at the end of a `safeBatchTransferFrom` after the balances have
      * been updated.
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
}
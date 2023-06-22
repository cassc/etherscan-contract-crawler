// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721} from "solady/tokens/ERC721.sol";
import {CommitReveal} from "./lib/CommitReveal.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {IERC4906, IERC165} from "./interfaces/IERC4906.sol";

/**
 * @title XXYYZZCore
 * @author emo.eth
 * @notice Core contract for XXYYZZ NFTs. Contains errors, constants, core token information, and helper functions.
 */
abstract contract XXYYZZCore is ERC721, IERC4906, CommitReveal, Ownable {
    error InvalidPayment();
    error InvalidHex();
    error MaximumSupplyExceeded();
    error AlreadyFinalized();
    error OnlyTokenOwner();
    error NoIdsProvided();
    error OwnerMismatch();
    error BatchBurnerNotApprovedForAll();
    error ArrayLengthMismatch();
    error MintClosed();
    error InvalidTimestamp();
    error OnlyFinalized();
    error Unavailable();
    error NoneAvailable();
    error MaxBatchSizeExceeded();

    uint256 public constant MINT_PRICE = 0.005 ether;
    uint256 public constant REROLL_PRICE = 0.00025 ether;
    uint256 public constant FINALIZE_PRICE = 0.005 ether;
    uint256 public constant REROLL_AND_FINALIZE_PRICE = 0.00525 ether;
    uint256 public immutable MAX_SPECIFIC_BATCH_SIZE;

    uint256 constant BYTES3_UINT_SHIFT = 232;
    uint256 constant MAX_UINT24 = 0xFFFFFF;
    uint96 constant FINALIZED = 1;
    uint96 constant NOT_FINALIZED = 0;

    // re-declared from solady ERC721 for custom gas optimizations
    uint256 private constant _ERC721_MASTER_SLOT_SEED = 0x7d8825530a5a2e7a << 192;

    mapping(uint256 tokenId => address finalizer) public finalizers;
    uint128 _numBurned;
    uint128 _numMinted;

    constructor(address initialOwner, uint256 maxBatchSize)
        // lifespan
        CommitReveal(
            1 days,
            // delay – MM/RPC will report a tx will revert until first eligible block is validated,
            // so 48 seconds will result in 60 seconds of delay before the frontend will report
            // that a tx will succeed
            48 seconds
        )
    {
        _initializeOwner(initialOwner);
        MAX_SPECIFIC_BATCH_SIZE = maxBatchSize;
    }

    receive() external payable {
        // send ether – see what happens! :)
    }

    ///////////////////
    // OWNER METHODS //
    ///////////////////

    /**
     * @notice Withdraws all funds from the contract to the current owner. onlyOwner.
     */
    function withdraw() public onlyOwner {
        assembly ("memory-safe") {
            let succ := call(gas(), caller(), selfbalance(), 0, 0, 0, 0)
            // revert with returndata if call failed
            if iszero(succ) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    ///////////////////
    // INFORMATIONAL //
    ///////////////////

    /**
     * @notice Get the total number of tokens in circulation
     */
    function totalSupply() public view returns (uint256) {
        return _numMinted - _numBurned;
    }

    /**
     * @notice Get the total number of tokens minted
     */
    function numMinted() external view returns (uint256) {
        return _numMinted;
    }

    /**
     * @notice Get the total number of tokens burned
     */
    function numBurned() external view returns (uint256) {
        return _numBurned;
    }

    /**
     * @notice Get the name of the token
     */
    function name() public pure override returns (string memory) {
        // note that this is unsafe to call internally, as it abi-encodes the name and
        // performs a low-level return
        assembly {
            mstore(0x20, 0x20)
            mstore(0x46, 0x06585859595a5a)
            return(0x20, 0x80)
        }
    }

    /**
     * @notice Get the symbol of the token
     */
    function symbol() public pure override returns (string memory) {
        // note that this is unsafe to call internally, as it abi-encodes the symbol and
        // performs a low-level return
        assembly {
            mstore(0x20, 0x20)
            mstore(0x46, 0x06585859595a5a)
            return(0x20, 0x80)
        }
    }

    /**
     * @notice Check if a specific token ID has been finalized. Will return true for tokens that were finalized and
     *         then burned. Will not revert if the tokenID does not currently exist. Will revert on invalid tokenIds.
     * @param id The token ID to check
     * @return True if the token ID has been finalized, false otherwise
     */
    function isFinalized(uint256 id) public view returns (bool) {
        _validateId(id);
        return _isFinalized(id);
    }

    ///@inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(ERC721, IERC165)
        returns (bool result)
    {
        assembly {
            let s := shr(224, interfaceId)
            // ERC165: 0x01ffc9a7, ERC721: 0x80ac58cd, ERC721Metadata: 0x5b5e139f. ERC4906: 0x49064906
            result := or(or(or(eq(s, 0x01ffc9a7), eq(s, 0x80ac58cd)), eq(s, 0x5b5e139f)), eq(s, 0x49064906))
        }
    }

    /////////////////
    // COMMITMENTS //
    /////////////////

    /**
     * @notice Get a commitment hash for a given sender, tokenId, and salt. Note that this could expose your desired
     *         ID to the RPC provider. Won't revert if the ID is invalid, but will return an invalid hash.
     * @param sender The address of the account that will mint or reroll the token ID
     * @param id The 6-hex-digit token ID to mint or reroll
     * @param salt The salt to use for the commitment
     */
    function computeCommitment(address sender, uint256 id, bytes32 salt)
        public
        pure
        returns (bytes32 committmentHash)
    {
        assembly ("memory-safe") {
            // shift sender left by 24 bits; id stays in bottom 24
            mstore(0, or(shl(24, sender), and(id, MAX_UINT24)))
            mstore(0x20, salt)
            // start hashing at 0x09 to skip 9 empty bytes (32 - (20 + 3))
            committmentHash := keccak256(0x09, 0x40)
        }
    }

    /**
     * @notice Get a commitment hash for a given sender, array of tokenIds, and salt. This allows for a single
     *         commitment for a batch of IDs, but note that order and length of IDs matters.
     *         If 5 IDs are passed, all 5 must be passed to either batchMintSpecific or batchRerollSpecific, in the
     *         same order. Note that this could expose your desired IDs to the RPC provider.
     *         Won't revert if any IDs are invalid or duplicated.
     * @param sender The address of the account that will mint or reroll the token IDs
     * @param ids The 6-hex-digit token IDs to mint or reroll
     * @param salt The salt to use for the batch commitment
     */
    function computeBatchCommitment(address sender, uint256[] calldata ids, bytes32 salt)
        public
        pure
        returns (bytes32 commitmentHash)
    {
        assembly ("memory-safe") {
            // cache free mem pointer
            let freeMemPtr := mload(0x40)
            // multiply length of elements by 32 bytes for each element
            let numBytes := shl(5, ids.length)
            // copy contents of array to unallocated free memory
            calldatacopy(freeMemPtr, ids.offset, numBytes)
            // hash contents of array, without length
            let arrayHash :=
                keccak256(
                    // start of array contents
                    freeMemPtr,
                    //length of array contents
                    numBytes
                )

            // store sender in first memory slot
            mstore(0, sender)
            // store array hash in second memory slot
            mstore(0x20, arrayHash)
            // clobber free memory pointer with salt
            mstore(0x40, salt)
            // compute commitment hash
            // start hashing at 12 bytes since addresses are 20 bytes
            commitmentHash := keccak256(0x0c, 0x60)
            // restore free memory pointer
            mstore(0x40, freeMemPtr)
        }
    }

    /////////////
    // HELPERS //
    /////////////

    /**
     * @dev Mint a token with a specific hex value and validate it was committed to
     * @param id The 6-hex-digit token ID to mint
     * @param salt The salt to use for the commitment
     */
    function _mintSpecific(uint256 id, bytes32 salt) internal {
        bytes32 computedCommitment = computeCommitment(msg.sender, id, salt);

        // validate ID is valid 6-hex-digit number
        _validateId(id);
        // validate commitment to prevent front-running
        _assertCommittedReveal(computedCommitment);

        // don't allow minting of tokens that were finalized and then burned
        if (_isFinalized(id)) {
            revert AlreadyFinalized();
        }
        _mint(msg.sender, id);
    }

    /**
     * @dev Mint a token with a specific hex value and validate it was committed to
     * @param id The 6-hex-digit token ID to mint
     * @param computedCommitment The commitment hash to validate
     */
    function _mintSpecificWithCommitment(uint256 id, bytes32 computedCommitment) internal {
        // validate ID is valid 6-hex-digit number
        _validateId(id);
        // validate commitment to prevent front-running
        _assertCommittedReveal(computedCommitment);

        // don't allow minting of tokens that were finalized and then burned
        if (_packedOwnershipSlot(id) != 0) {
            revert AlreadyFinalized();
        }
        _mint(msg.sender, id);
    }

    /**
     * @dev Mint a token with a specific hex value without validating it was committed to
     * @param id The 6-hex-digit token ID to mint
     * @return True if the token was minted, false otherwise
     */
    function _mintSpecificUnprotected(uint256 id) internal returns (bool) {
        // validate ID is valid 6-hex-digit number
        _validateId(id);
        // don't allow minting of tokens that exist or were finalized and then burned
        if (_packedOwnershipSlot(id) != 0) {
            // return false indicating a no-op
            return false;
        }
        // otherwise mint the token
        _mint(msg.sender, id);
        return true;
    }

    /**
     * @dev Find the first unminted token ID based on the current number minted and PREVRANDAO
     * @param seed The seed to use for the random number generation – when minting, should be _numMinted, when
     *             re-rolling, should be a function of the caller. In the case of re-rolling, this means that if a single caller makes
     *             multiple re-rolls in the same block, there will be collisions. This is fine, as the extra gas  cost
     *             discourages batch re-rolling with bots or scripts (at least from the same address).
     */
    function _findAvailableHex(uint256 seed) internal view returns (uint256) {
        uint256 tokenId;
        assembly {
            mstore(0, seed)
            mstore(0x20, prevrandao())
            // hash the two values together and then mask to a uint24
            // seed is max an address, so start hashing at 0x0c
            tokenId := and(keccak256(0x0c, 0x40), MAX_UINT24)
        }
        // check for the small chance that the token ID is already minted or finalized – if so, increment until we
        // find one that isn't
        while (_packedOwnershipSlot(tokenId) != 0) {
            // safe to do unchecked math here as it is modulo 2^24
            unchecked {
                tokenId = (tokenId + 1) & MAX_UINT24;
            }
        }
        return tokenId;
    }

    ///@dev Check if an ID is a valid six-hex-digit number
    function _validateId(uint256 xxyyzz) internal pure {
        if (xxyyzz > MAX_UINT24) {
            revert InvalidHex();
        }
    }

    ///@dev Validate msg value is equal to total price
    function _validatePayment(uint256 unitPrice, uint256 quantity) internal view {
        // can't overflow because there are at most uint24 tokens, and existence is checked for each token down the line
        unchecked {
            if (msg.value != (unitPrice * quantity)) {
                revert InvalidPayment();
            }
        }
    }

    /**
     * @dev Refund any overpayment
     * @param unitPrice The price per action (mint, reroll, reroll+finalize)
     * @param availableQuantity The number of tokens (mints, rerolls) that were actually available for purchase
     */
    function _refundOverpayment(uint256 unitPrice, uint256 availableQuantity) internal {
        unchecked {
            // can't underflow because payment was already validated; even if it did, value would be larger than ether
            // supply
            uint256 overpayment = msg.value - (unitPrice * availableQuantity);
            if (overpayment != 0) {
                SafeTransferLib.safeTransferETH(msg.sender, overpayment);
            }
        }
    }

    /**
     * @dev Check if a specific token has been finalized. Does not check if token exists.
     * @param id The 6-hex-digit token ID to check
     */
    function _isFinalized(uint256 id) internal view returns (bool) {
        return _getExtraData(id) == FINALIZED;
    }

    /**
     * @dev Load the raw ownership slot for a given token ID, which contains both the owner and the extra data
     *      (finalization status). This allows for succint checking of whether or not a token is mintable,
     *      i.e., whether it does not currently exist and has not been finalized. It also allows for avoiding
     *      an extra SLOAD in cases when checking both owner/existence and finalization status.
     * @param id The 6-hex-digit token ID to check
     */
    function _packedOwnershipSlot(uint256 id) internal view returns (uint256 result) {
        assembly {
            // since all ids are < uint24, this basically just clears the 0-slot before writing 4 bytes of slot seed
            mstore(0x00, id)
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            result := sload(add(id, add(id, keccak256(0x00, 0x20))))
        }
    }

    function _checkCallerIsOwnerAndNotFinalized(uint256 id) internal view {
        uint256 packedSlot = _packedOwnershipSlot(id);
        // clean and cast to address
        address owner = address(uint160(packedSlot));
        if ((packedSlot) > type(uint160).max) {
            revert AlreadyFinalized();
        }
        // check that caller is owner
        if (owner != msg.sender) {
            revert OnlyTokenOwner();
        }
    }

    /**
     * @dev Check that array lengths match, the batch size is not too large, and that the payment is correct
     * @param a The first array to check
     * @param b The second array to check
     * @param unitPrice The price per action (mint, reroll, reroll+finalize)
     */
    function _validateRerollBatchAndPayment(uint256[] calldata a, uint256[] calldata b, uint256 unitPrice)
        internal
        view
    {
        if (a.length != b.length) {
            revert ArrayLengthMismatch();
        }
        if (a.length > MAX_SPECIFIC_BATCH_SIZE) {
            revert MaxBatchSizeExceeded();
        }
        _validatePayment(a.length, unitPrice);
    }
}
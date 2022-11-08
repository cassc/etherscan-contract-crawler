// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Base64.sol";

/**
 * This is the EcoNFT for verifying an arbitraty claim.
 */
contract EcoID is ERC721("EcoID", "EcoID"), EIP712("EcoID", "1") {
    /**
     * Use for signarture recovery and verification on minting of EcoID
     */
    using ECDSA for bytes32;

    /**
     * Use for tracking the nonces on signatures
     */
    using Counters for Counters.Counter;

    /**
     * The static web url for the nft
     */
    string public constant NFT_EXTERNAL_URL = "https://eco.org/eco-id";

    /**
     * The static description for the nft
     */
    string public constant NFT_DESCRIPTION =
        "Eco IDs are fully decentralized and permissionless identity primitives designed to be simple, versatile and immutable. They are intended to serve as a basic foundation to bootstrap increasingly-complex and custom reputation and governance systems.";

    /**
     * The static image url for all the nft's
     */
    string public constant NFT_IMAGE_URL =
        "https://ipfs.io/ipfs/QmWZFvb88KDos7BYyf52btxPuEEifZN7i5CA2YfC3azS8J";

    /**
     * The static url for contract-level metadata
     */
    string public constant CONTRACT_LEVEL_METADATA_URL =
        "https://ipfs.io/ipfs/QmZ7vpY34jdmDyn8otBMzvX7omn6NWTfdxVFr8RMuAAVPZ";

    /**
     * The default pagination limit for the tokenURI meta that reads from the claim verifiers array
     */
    uint256 public constant META_LIMIT = 50;

    /**
     * The length of a substring for the name field of an nft
     */
    uint256 public constant SUB_NAME_LENGTH = 10;

    /**
     * The hash of the register function signature for the recipient
     */
    bytes32 private constant REGISTER_APPROVE_TYPEHASH =
        keccak256(
            "Register(string claim,uint256 feeAmount,bool revocable,address recipient,address verifier,uint256 deadline,uint256 nonce)"
        );

    /**
     * The hash of the register function signature for the verifier
     */
    bytes32 private constant REGISTER_VERIFIER_TYPEHASH =
        keccak256(
            "Register(string claim,uint256 feeAmount,bool revocable,address recipient,uint256 deadline,uint256 nonce)"
        );

    /**
     * The hash of the register function signature
     */
    bytes32 private constant UNREGISTER_TYPEHASH =
        keccak256(
            "Unregister(string claim,address recipient,address verifier,uint256 deadline,uint256 nonce)"
        );

    /**
     * Event for when the constructor has finished
     */
    event InitializeEcoID();

    /**
     * Event for when a claim is verified for a recipient
     */
    event RegisterClaim(
        string claim,
        uint256 feeAmount,
        bool revocable,
        address indexed recipient,
        address indexed verifier
    );

    /**
     * Event for when a claim is unregistered by the verifier
     */
    event UnregisterClaim(
        string claim,
        address indexed recipient,
        address indexed verifier
    );

    /**
     * Event for when an EcoNFT is minted
     */
    event Mint(address indexed recipient, string claim, uint256 tokenID);

    /**
     * Error for when the deadline for a signature has passed
     */
    error DeadlineExpired();

    /**
     * Error for when the approval signature during registration is invalid
     */
    error InvalidRegistrationApproveSignature();

    /**
     * Error for when the verifier signature during registration is invalid
     */
    error InvalidRegistrationVerifierSignature();

    /**
     * Error for when a registration with the same verifier is attempted on a claim a second time
     */
    error DuplicateVerifier(address verifier);

    /**
     * Error for when a claim has not been verified or doesn't exist for a user
     */
    error UnverifiedClaim();

    /**
     * Error for when trying to deregister a claim that is not revocable
     */
    error UnrevocableClaim();

    /**
     * Error for when trying to deregister and the verifier signature is invalid
     */
    error InvalidVerifierSignature();

    /**
     * Error for when a user trys to mint an NFT for a claim that already has a minted NFT
     */
    error NftAlreadyMinted(uint256 tokenID);

    /**
     * Error for when trying to reference an NFT token that doesn't exist
     */
    error NonExistantToken();

    /**
     * Error for when the fee payment for registration fails
     */
    error FeePaymentFailed();

    /**
     * Error for when trying to register an empty claim
     */
    error EmptyClaim();

    /**
     * Structure for storing a verified claim
     */
    struct VerifiedClaim {
        string claim;
        uint256 tokenID;
        VerifierRecord[] verifiers;
        mapping(address => bool) verifierMap;
    }

    /**
     * Structure for the verifier record
     */
    struct VerifierRecord {
        address verifier;
        bool revocable;
    }

    /**
     * Structure for storing the relation between a tokenID and the address and claim
     * that they are linked to
     */
    struct TokenClaim {
        address recipient;
        string claim;
    }

    /**
     * Stores the last token index minted
     */
    uint256 public _tokenIDIndex = 1;

    /**
     * Mapping the user address with all claims they have
     */
    mapping(address => mapping(string => VerifiedClaim)) public _verifiedClaims;

    /**
     * Mapping the tokenID of minted tokens with the claim they represent. Necessary as we can't fetch the claim
     * directly from the _verifiedClaims for a given tokenID
     */
    mapping(uint256 => TokenClaim) public _tokenClaimIDs;

    /**
     * The mapping that store the current nonce for claim
     */
    mapping(string => Counters.Counter) private _nonces;

    /**
     * The token contract that is used for fee payments to the minter address
     */
    ERC20 public immutable _token;

    /**
     * Constructor that sets the ERC20 and emits an initialization event
     *
     * @param token the erc20 that is used to pay for registrations
     */
    constructor(ERC20 token) {
        _token = token;

        emit InitializeEcoID();
    }

    /**
     * Check if the claim has been verified by the given verifier for the given address
     *
     * @param recipient the address of the associated claim
     * @param claim the claim that should be verified
     * @param verifier the address of the verifier for the claim on the recipient address
     *
     * @return true if the claim is verified, false otherwise
     */
    function isClaimVerified(
        address recipient,
        string calldata claim,
        address verifier
    ) external view returns (bool) {
        return _verifiedClaims[recipient][claim].verifierMap[verifier];
    }

    /**
     * Registers a claim by an approved verifier to the recipient of that claim.
     *
     * @param claim the claim that is beign verified
     * @param feeAmount the fee the recipient is paying the verifier for the verification
     * @param revocable true if the verifier can revoke their verification of the claim in the future
     * @param recipient the address of the recipient of the registered claim
     * @param verifier the address that is verifying the claim
     * @param approveSig signature that proves that the recipient has approved the verifier to register a claim
     * @param verifySig signature that we are validating comes from the verifier address
     */
    function register(
        string calldata claim,
        uint256 feeAmount,
        bool revocable,
        address recipient,
        address verifier,
        uint256 deadline,
        bytes calldata approveSig,
        bytes calldata verifySig
    ) external _validClaim(claim) {
        if (deadline < block.timestamp) {
            revert DeadlineExpired();
        }
        uint256 nonce = _useNonce(claim);
        if (
            !_verifyRegistrationApprove(
                claim,
                feeAmount,
                revocable,
                recipient,
                verifier,
                deadline,
                nonce,
                approveSig
            )
        ) {
            revert InvalidRegistrationApproveSignature();
        }

        if (
            !_verifyRegistrationVerify(
                claim,
                feeAmount,
                revocable,
                recipient,
                verifier,
                deadline,
                nonce,
                verifySig
            )
        ) {
            revert InvalidRegistrationVerifierSignature();
        }

        VerifiedClaim storage vclaim = _verifiedClaims[recipient][claim];
        if (vclaim.verifierMap[verifier]) {
            revert DuplicateVerifier({verifier: verifier});
        }
        vclaim.claim = claim;
        vclaim.verifiers.push(VerifierRecord(verifier, revocable));
        vclaim.verifierMap[verifier] = true;

        if (feeAmount > 0) {
            if (!_token.transferFrom(recipient, verifier, feeAmount)) {
                revert FeePaymentFailed();
            }
        }

        emit RegisterClaim(claim, feeAmount, revocable, recipient, verifier);
    }

    /**
     * Revokes a claim that has been made by the verifier if it was revocable
     *
     * @param claim the claim that was verified
     * @param recipient the address of the recipient of the registered claim
     * @param verifier the address that had verified the claim
     * @param deadline the deadline in milliseconds from epoch that the signature expires
     * @param verifySig signature that we are validating comes from the verifier address
     */
    function unregister(
        string calldata claim,
        address recipient,
        address verifier,
        uint256 deadline,
        bytes calldata verifySig
    ) external _validClaim(claim) {
        if (deadline < block.timestamp) {
            revert DeadlineExpired();
        }
        VerifiedClaim storage vclaim = _verifiedClaims[recipient][claim];
        if (!vclaim.verifierMap[verifier]) {
            revert UnverifiedClaim();
        }

        VerifierRecord storage record = _getVerifierRecord(
            verifier,
            vclaim.verifiers
        );

        if (!record.revocable) {
            revert UnrevocableClaim();
        }

        if (
            !_verifyUnregistration(
                claim,
                recipient,
                verifier,
                deadline,
                _useNonce(claim),
                verifySig
            )
        ) {
            revert InvalidVerifierSignature();
        }

        vclaim.verifierMap[verifier] = false;
        _removeVerifierRecord(verifier, vclaim.verifiers);

        emit UnregisterClaim(claim, recipient, verifier);
    }

    /**
     * Mints the nft token for the claim
     *
     * @param recipient the address of the recipient for the nft
     * @param claim the claim that is being associated to the nft
     *
     * @return tokenID the ID of the nft
     */
    function mintNFT(address recipient, string memory claim)
        external
        returns (uint256 tokenID)
    {
        VerifiedClaim storage vclaim = _verifiedClaims[recipient][claim];
        if (vclaim.verifiers.length == 0) {
            revert UnverifiedClaim();
        }

        if (vclaim.tokenID != 0) {
            revert NftAlreadyMinted({tokenID: vclaim.tokenID});
        }

        tokenID = _tokenIDIndex++;

        vclaim.tokenID = tokenID;
        _tokenClaimIDs[tokenID] = TokenClaim(recipient, claim);
        _safeMint(recipient, tokenID);

        emit Mint(recipient, claim, tokenID);
    }

    /**
     * Constructs and returns the ERC-721 schema metadata as a json object.
     * Calls a pagination for the verifier array that limits to 50.
     * See tokenURICursor if you need to paginate the metadata past that number
     *
     * @param tokenID the id of the nft
     *
     * @return the metadata as a json object
     */
    function tokenURI(uint256 tokenID)
        public
        view
        override
        returns (string memory)
    {
        return tokenURICursor(tokenID, 0, META_LIMIT);
    }

    /**
     * Returns the current nonce for a given claim
     *
     * @param claim the claim to fetch the nonce for
     *
     * @return the nonce
     */
    function nonces(string memory claim) public view returns (uint256) {
        return _nonces[claim].current();
    }

    /**
     * Makes the _domainSeparatorV4() function externally callable for signature generation
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * Constructs and returns the metadata ERC-721 schema json for the NFT.
     * Uses regular cursor pagination in case the verifiers array for the claim is large.
     *
     * @param tokenID the id of the nft
     * @param cursor the pagination cursor for the verifiers array
     * @param limit  the pagination limit for the verifiers array
     *
     * @return meta the metadata as a json array
     */
    function tokenURICursor(
        uint256 tokenID,
        uint256 cursor,
        uint256 limit
    ) public view virtual returns (string memory meta) {
        if (!_exists(tokenID)) {
            revert NonExistantToken();
        }

        TokenClaim storage tokenClaim = _tokenClaimIDs[tokenID];
        VerifiedClaim storage vclaim = _verifiedClaims[tokenClaim.recipient][
            tokenClaim.claim
        ];

        string memory claim = vclaim.claim;
        string memory nameFrag = _getStringSize(claim) > SUB_NAME_LENGTH
            ? string.concat(_substring(claim, 0, SUB_NAME_LENGTH), "...")
            : claim;
        bool hasVerifiers = vclaim.verifiers.length > 0;
        string memory metadataName = string.concat("Eco ID - ", nameFrag);

        meta = _metaPrefix(vclaim.claim, metadataName, hasVerifiers);
        string memory closing = hasVerifiers ? '"}]}' : "]}";
        meta = string.concat(
            meta,
            _metaVerifierArray(vclaim.verifiers, cursor, limit),
            closing
        );

        string memory base = "data:application/json;base64,";
        string memory base64EncodedMeta = Base64.encode(
            bytes(string(abi.encodePacked(meta)))
        );

        meta = string(abi.encodePacked(base, base64EncodedMeta));
    }

    /**
     * Constructs the first portion of the nft metadata
     *
     * @param claim the claim
     * @param name the name of the nft
     * @param hasVerifiers whether the nft has any verifiers
     * @return meta the partially constructed json
     */
    function _metaPrefix(
        string storage claim,
        string memory name,
        bool hasVerifiers
    ) internal pure returns (string memory meta) {
        meta = "{";
        meta = string.concat(
            meta,
            '"description":',
            '"',
            NFT_DESCRIPTION,
            '",'
        );
        meta = string.concat(
            meta,
            '"external_url":',
            '"',
            NFT_EXTERNAL_URL,
            '",'
        );
        meta = string.concat(meta, '"image":', '"', NFT_IMAGE_URL, '",');
        meta = string.concat(meta, '"name":"', name, '",');
        string memory closing = hasVerifiers ? '"},' : '"}';
        meta = string.concat(
            meta,
            '"attributes":[{"trait_type":"Data","value":"',
            claim,
            closing
        );
    }

    /**
     * Constructs the verifier address array portion of the nft metadata
     *
     * @param verifiers the claim being verified
     * @param cursor the pagination cursor for the verifiers array
     * @param limit  the pagination limit for the verifiers array
     *
     * @return meta the partially constructed json
     */
    function _metaVerifierArray(
        VerifierRecord[] storage verifiers,
        uint256 cursor,
        uint256 limit
    ) internal view returns (string memory meta) {
        if (verifiers.length == 0) {
            return meta;
        }
        //get the ending position
        uint256 readEnd = cursor + limit;
        uint256 vl = verifiers.length;
        uint256 end = vl <= readEnd ? vl : readEnd;

        uint256 lastPoint = end - 1;
        for (uint256 i = cursor; i < end; i++) {
            string memory addr = Strings.toHexString(
                uint256(uint160(verifiers[i].verifier)),
                20
            );
            string memory revocable = verifiers[i].revocable ? "true" : "false";

            if (i < lastPoint) {
                meta = string.concat(
                    meta,
                    '{"trait_type":"Verifier","value":"',
                    addr,
                    '","revocable":"',
                    revocable,
                    '"},'
                );
            } else {
                meta = string.concat(
                    meta,
                    '{"trait_type":"Verifier","value": "',
                    addr,
                    '","revocable":"',
                    revocable
                );
            }
        }
    }

    /**
     * Verifies the signature supplied grants the verifier approval by the recipient to modify their claim
     *
     * @param claim the claim being verified
     * @param feeAmount the cost paid to the verifier by the recipient
     * @param revocable true if the verifier can revoke their verification of the claim in the future
     * @param recipient the address of the recipient of a registration
     * @param verifier  the address of the verifying agent
     * @param deadline the deadline in milliseconds from epoch that the signature expires
     * @param approveSig signature that we are validating grants the verifier permission to register the claim to the recipient
     *
     * @return true if the signature is valid, false otherwise
     */
    function _verifyRegistrationApprove(
        string calldata claim,
        uint256 feeAmount,
        bool revocable,
        address recipient,
        address verifier,
        uint256 deadline,
        uint256 nonce,
        bytes calldata approveSig
    ) internal view returns (bool) {
        bytes32 hash = _getApproveHash(
            claim,
            feeAmount,
            revocable,
            recipient,
            verifier,
            deadline,
            nonce
        );
        return hash.recover(approveSig) == recipient;
    }

    /**
     * Verifies the signature supplied belongs to the verifier for a certain claim.
     *
     * @param claim the claim being verified
     * @param feeAmount the cost paid to the verifier by the recipient
     * @param revocable true if the verifier can revoke their verification of the claim in the future
     * @param recipient the address of the recipient of a registration
     * @param verifier  the address of the verifying agent
     * @param deadline the deadline in milliseconds from epoch that the signature expires
     * @param verifierSig signature that we are validating comes from the verifier
     *
     * @return true if the signature is valid, false otherwise
     */
    function _verifyRegistrationVerify(
        string calldata claim,
        uint256 feeAmount,
        bool revocable,
        address recipient,
        address verifier,
        uint256 deadline,
        uint256 nonce,
        bytes calldata verifierSig
    ) internal view returns (bool) {
        bytes32 hash = _getVerificationHash(
            claim,
            feeAmount,
            revocable,
            recipient,
            deadline,
            nonce
        );
        return hash.recover(verifierSig) == verifier;
    }

    /**
     * Verifies the signature supplied belongs to the verifier for the claim.
     *
     * @param claim the claim that was verified
     * @param recipient  the address of the recipient
     * @param verifier  the address of the verifying agent
     * @param deadline the deadline in milliseconds from epoch that the signature expires
     * @param nonce the nonce for the signatures for this claim registration
     * @param signature signature that we are validating comes from the verifier
     * @return true if the signature is valid, false otherwise
     */
    function _verifyUnregistration(
        string calldata claim,
        address recipient,
        address verifier,
        uint256 deadline,
        uint256 nonce,
        bytes calldata signature
    ) internal view returns (bool) {
        bytes32 hash = _getUnregistrationHash(
            claim,
            recipient,
            verifier,
            deadline,
            nonce
        );
        return hash.recover(signature) == verifier;
    }

    /**
     * @dev Disables the transferFrom and safeTransferFrom calls in the parent contract bounding this token to
     * the original address that it was minted for
     */
    function _isApprovedOrOwner(address, uint256)
        internal
        pure
        override
        returns (bool)
    {
        return false;
    }

    /**
     * Hashes the input parameters for the approval signature verification
     *
     * @param claim the claim being attested to
     * @param feeAmount the cost paid to the verifier by the recipient
     * @param revocable true if the verifier can revoke their verification of the claim in the future
     * @param recipient the address of the user that is having a claim registered
     * @param verifier the address of the verifier of the claim
     * @param deadline the deadline in milliseconds from epoch that the signature expires
     * @param nonce the nonce for the signatures for this claim registration
     */
    function _getApproveHash(
        string calldata claim,
        uint256 feeAmount,
        bool revocable,
        address recipient,
        address verifier,
        uint256 deadline,
        uint256 nonce
    ) private view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        REGISTER_APPROVE_TYPEHASH,
                        keccak256(bytes(claim)),
                        feeAmount,
                        revocable,
                        recipient,
                        verifier,
                        deadline,
                        nonce
                    )
                )
            );
    }

    /**
     * Hashes the input parameters for the registration signature verification
     *
     * @param claim the claim being attested to
     * @param feeAmount the cost to register the claim the recipient is willing to pay
     * @param revocable true if the verifier can revoke their verification of the claim in the future
     * @param recipient the address of the user that is having a claim registered
     * @param deadline the deadline in milliseconds from epoch that the signature expires
     * @param nonce the nonce for the signatures for this claim registration
     */
    function _getVerificationHash(
        string calldata claim,
        uint256 feeAmount,
        bool revocable,
        address recipient,
        uint256 deadline,
        uint256 nonce
    ) private view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        REGISTER_VERIFIER_TYPEHASH,
                        keccak256(bytes(claim)),
                        feeAmount,
                        revocable,
                        recipient,
                        deadline,
                        nonce
                    )
                )
            );
    }

    /**
     * Hashes the input parameters for the unregistration signature verification
     *
     * @param claim the claim that was verified
     * @param recipient the address of the user that owns that claim
     * @param verifier  the address of the verifying agent
     * @param deadline the deadline in milliseconds from epoch that the signature expires
     * @param nonce the nonce for the signatures for this claim registration
     */
    function _getUnregistrationHash(
        string calldata claim,
        address recipient,
        address verifier,
        uint256 deadline,
        uint256 nonce
    ) private view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        UNREGISTER_TYPEHASH,
                        keccak256(bytes(claim)),
                        recipient,
                        verifier,
                        deadline,
                        nonce
                    )
                )
            );
    }

    /**
     * Checks that the claim is not empty
     *
     * @param claim the claim to check
     */
    modifier _validClaim(string memory claim) {
        if (bytes(claim).length == 0) {
            revert EmptyClaim();
        }
        _;
    }

    /**
     * Finds the verifier record in the array and returns it, or reverts
     *
     * @param verifier the verified address to search for
     * @param verifierRecords the verifier records array
     */
    function _getVerifierRecord(
        address verifier,
        VerifierRecord[] storage verifierRecords
    ) internal view returns (VerifierRecord storage) {
        for (uint256 i = 0; i < verifierRecords.length; i++) {
            if (verifierRecords[i].verifier == verifier) {
                return verifierRecords[i];
            }
        }
        //should never get here
        revert("invalid verifier");
    }

    /**
     * Removes a verifier from the verifiers array, does not preserve order
     *
     * @param verifier the verifier to remove from the array
     * @param verifierRecords the verifier records array
     */
    function _removeVerifierRecord(
        address verifier,
        VerifierRecord[] storage verifierRecords
    ) internal {
        for (uint256 i = 0; i < verifierRecords.length; i++) {
            if (verifierRecords[i].verifier == verifier) {
                verifierRecords[i] = verifierRecords[
                    verifierRecords.length - 1
                ];
                verifierRecords.pop();
                return;
            }
        }
    }

    /**
     * Returns a substring of the input argument
     */
    function _substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    /**
     * Returns the size of a string in bytes
     *
     * @param str string to check
     */
    function _getStringSize(string memory str) internal pure returns (uint256) {
        return bytes(str).length;
    }

    /**
     * Returns the current nonce for a claim and automatically increament it
     *
     * @param claim the claim to get and increment the nonce for
     *
     * @return current current nonce before incrementing
     */
    function _useNonce(string memory claim) internal returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[claim];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * Function for reading NFT-level metadata
     *
     * Designed to match the OpenSea specification
     */
    function contractURI() public pure returns (string memory) {
        return CONTRACT_LEVEL_METADATA_URL;
    }
}
// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.18;

import {OperatorFilterOS} from "ethier/erc721/OperatorFilterOS.sol";
import {IDelegationRegistry} from
    "delegatecash/delegation-registry/IDelegationRegistry.sol";
import {
    ERC721A,
    ERC721ACommon,
    BaseTokenURI,
    ERC721ACommonBaseTokenURI
} from "ethier/erc721/BaseTokenURI.sol";

import {IMoonbirds} from "moonbirds/IMoonbirds.sol";
import {NestedMerkleClaimableBase} from
    "redeemable-voucher/common/NestedMerkleClaimableBase.sol";
import {IEntropyOracle} from "entropy-oracle/IEntropyOracle.sol";

import {RecordedMinter} from "./RecordedMinter.sol";
import {
    TokenMetadata,
    DefyBirdsTraitMechanics
} from "./DefyBirdsTraitMechanics.sol";
import {ClaimableWithSignature} from "./ClaimableWithSignature.sol";

/**
 * @notice Des Lucrece x PROOF collab: DefyBirds
 * @author David Huber (@cxkoda)
 * @author Toaster
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
contract DefyBirds is
    OperatorFilterOS,
    DefyBirdsTraitMechanics,
    RecordedMinter,
    NestedMerkleClaimableBase,
    ClaimableWithSignature
{
    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Throw if the claim with signed allowances is exhausted.
     */
    error TooManyClaimsWithSignatureRequested(uint256 remaining);

    /**
     * @notice Throw if the owner mint is exhausted.
     */
    error TooManyOwnerMintsRequested(uint256 remaining);

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The delegate.cash delegation registry.
     */
    IDelegationRegistry internal immutable _delegationRegistry;

    /**
     * @notice Maximum number of tokens that can be claimed with signatures.
     */
    uint16 internal constant _MAX_NUM_CLAIMBALE_WITH_SIGNATURE = 1500;

    /**
     * @notice Maximum number of tokens that can be minted by the owner.
     */
    uint16 internal constant _MAX_NUM_OWNER_MINTS = 194;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice Oracle returning entropy for each block.
     */
    IEntropyOracle public entropyOracle;

    /**
     * @notice Number of tokens that can still be claimed with signatures.
     */
    uint16 public numClaimableWithSignature;

    /**
     * @notice Maximum number of tokens that can be claimed with signatures.
     */
    uint16 internal numMintableByOwner;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    struct Config {
        address admin;
        address steerer;
        address payable royaltiesReceiver;
        string baseTokenURI;
        IMoonbirds moonbirds;
        bytes32 nudeBirdsRoot;
        uint256 nudeBirdsProofLength;
        IEntropyOracle oracle;
        IDelegationRegistry delegationRegistry;
    }

    constructor(Config memory cfg)
        ERC721ACommon(
            cfg.admin,
            cfg.steerer,
            "Defybirds",
            "DEFYB",
            cfg.royaltiesReceiver,
            500
        )
        BaseTokenURI(cfg.baseTokenURI)
        NestedMerkleClaimableBase(
            cfg.moonbirds,
            cfg.nudeBirdsRoot,
            cfg.nudeBirdsProofLength,
            false /* mustBeNested -- we are handling nesting checks via the snapshot */
        )
    {
        entropyOracle = cfg.oracle;
        _delegationRegistry = cfg.delegationRegistry;
        numClaimableWithSignature = _MAX_NUM_CLAIMBALE_WITH_SIGNATURE;
        numMintableByOwner = _MAX_NUM_OWNER_MINTS;
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Opens the claim of the airdrop.
     * @dev `nestedBeforeTimestamp` must be set before calling this function.
     */
    function setEntropyOracle(IEntropyOracle oracle)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        entropyOracle = oracle;
    }

    /**
     * @notice Opens the claim of the airdrop.
     * @dev `nestedBeforeTimestamp` must be set before calling this function.
     */
    function ownerMint(address to, uint16 num)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        if (num > numMintableByOwner) {
            revert TooManyOwnerMintsRequested(numMintableByOwner);
        }
        numMintableByOwner -= num;
        _doClaim(to, num);
    }

    /**
     * @notice Opens the claim of the airdrop.
     * @dev `nestedBeforeTimestamp` must be set before calling this function.
     */
    function toggleNestedMerkleClaim(bool toggle)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _toggleNestedMerkleClaim(toggle);
    }

    /**
     * @notice Sets the nested after timestamp.
     * @dev Must be called before opening the claim.
     */
    function setNestedBeforeTimestamp(uint256 nestedBeforeTimestamp_)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _setNestedBeforeTimestamp(nestedBeforeTimestamp_);
    }

    /**
     * @notice Opens the claim of the airdrop.
     * @dev Repeated calls have no effect.
     */
    function toggleClaimWithSignature(bool toggle)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _toggleClaimWithSignature(toggle);
    }

    /**
     * @notice Changes the set of authorised allowance signers.
     */
    function changeAllowlistSigners(
        address[] calldata rm,
        address[] calldata add
    ) external onlyRole(DEFAULT_STEERING_ROLE) {
        _changeAllowlistSigners(rm, add);
    }

    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @notice Overload to fulfill the claim with a nudebird.
     */
    function _doClaimWithNestedMerkle(
        address to,
        uint256 /* moonbird tokenId */
    ) internal virtual override {
        _doClaim(to, 1);
    }

    /**
     * @inheritdoc NestedMerkleClaimableBase
     * @dev Adds token delegation
     */
    function _isAllowedToClaimWithNestedMerkle(
        address operator,
        uint256 tokenId
    ) internal view virtual override returns (bool) {
        address tokenOwner = _moonbirds.ownerOf(tokenId);
        return (operator == tokenOwner)
            || _delegationRegistry.checkDelegateForToken(
                operator, tokenOwner, address(_moonbirds), tokenId
            ) || (operator == _moonbirds.getApproved(tokenId))
            || _moonbirds.isApprovedForAll(tokenOwner, operator);
    }

    /**
     * @notice Overload to fulfill the claim with a valid signed allowance.
     */
    function _doClaimsFromSignature(address to, uint16 num)
        internal
        virtual
        override
    {
        if (num > numClaimableWithSignature) {
            revert TooManyClaimsWithSignatureRequested(
                numClaimableWithSignature
            );
        }
        numClaimableWithSignature -= num;
        _doClaim(to, num);
    }

    /**
     * @notice Fulfilling a claim.
     */
    function _doClaim(address to, uint256 num) internal {
        uint256 startTokenId = _nextTokenId();
        _mintRecorded(to, num);
        entropyOracle.requestEntropy(revealBlockNumber(startTokenId));
    }

    /**
     * @notice The blocknumber at which a given token will be revealed.
     * @dev The entropy provided by `entropyOracle` for this block will be used
     * to randomise the traits.
     */
    function revealBlockNumber(uint256 tokenId) public view returns (uint256) {
        // This is safe because the entropy oracle will only provide entropy
        // after a given block has already been minted.
        return _mintBlockNumber(tokenId);
    }

    /**
     * @notice Generates a random seed for a given token.
     * @dev If the seed is not available yet, this routine returns `0`.
     * @dev Uses block entropy provided by the `entropyOracle`.
     */
    function _seed(uint256 tokenId) internal view override returns (uint256) {
        bytes32 salt = entropyOracle.blockEntropy(revealBlockNumber(tokenId));
        if (salt == 0) {
            return 0;
        }

        return uint256(
            keccak256(abi.encodePacked(salt, _mixHashOfToken(tokenId), tokenId))
        );
    }

    // =========================================================================
    //                           Inheritance
    // =========================================================================

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721ACommon, ERC721ACommonBaseTokenURI)
        returns (bool)
    {
        return ERC721ACommonBaseTokenURI.supportsInterface(interfaceId);
    }

    function _extraData(address from, address to, uint24 previousExtraData)
        internal
        view
        virtual
        override(ERC721A, RecordedMinter)
        returns (uint24)
    {
        return RecordedMinter._extraData(from, to, previousExtraData);
    }

    function _baseURI()
        internal
        view
        virtual
        override(ERC721A, ERC721ACommonBaseTokenURI)
        returns (string memory)
    {
        return ERC721ACommonBaseTokenURI._baseURI();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, DefyBirdsTraitMechanics)
        returns (string memory)
    {
        return DefyBirdsTraitMechanics.tokenURI(tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        OperatorFilterOS.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
        onlyAllowedOperatorApproval(operator)
    {
        OperatorFilterOS.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
        onlyAllowedOperator(from)
    {
        OperatorFilterOS.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
        onlyAllowedOperator(from)
    {
        OperatorFilterOS.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
        onlyAllowedOperator(from)
    {
        OperatorFilterOS.safeTransferFrom(from, to, tokenId, data);
    }
}
// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.18;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {SafeCast} from "openzeppelin-contracts/utils/math/SafeCast.sol";
import {IDelegationRegistry} from
    "delegatecash/delegation-registry/IDelegationRegistry.sol";

import {
    ERC721A,
    ERC721ACommon,
    BaseTokenURI,
    ERC721ACommonBaseTokenURI
} from "ethier/erc721/BaseTokenURI.sol";
import {OperatorFilterOS} from "ethier/erc721/OperatorFilterOS.sol";

import {ClaimableWithSignature} from "./ClaimableWithSignature.sol";
import {
    ClaimableWithToken,
    ClaimableWithDelegatedToken
} from "./ClaimableWithDelegatedToken.sol";

/**
 * @notice PACE x PROOF: Archive of Feelings by Mika Tajima
 * @author David Huber (@cxkoda)
 * @author Toaster
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
contract ArchiveOfFeelings is
    ERC721ACommonBaseTokenURI,
    OperatorFilterOS,
    ClaimableWithSignature,
    ClaimableWithDelegatedToken
{
    using Address for address payable;

    // =========================================================================
    //                           Types
    // =========================================================================

    /**
     * @notice The various stages of the contract used to enable/disable various
     * contract features.
     */
    enum Stage {
        Closed,
        ProofCollective,
        Allowlist,
        Public
    }

    /**
     * @notice Used to mint a batch of tokens in `ownerMint`.
     */
    struct MintBatch {
        address to;
        uint8 num;
    }

    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if the purchasable pool of tokens is exhausted.
     */
    error TooManyPurchasesRequested(uint256 remaining);

    /**
     * @notice Thrown if the owner mintable pool is exhausted.
     */
    error TooManyOwnerMintsRequested(uint256 remaining);

    /**
     * @notice Thrown if the user attempts to purchase more than the per-wallet
     * cap permits them to.
     */
    error WalletLimitExhausted(uint256 remaining);

    /**
     * @notice Thrown if a user attempts to use a method that is only enable for
     * a certain stage.
     */
    error WrongStage(Stage want);

    /**
     * @notice Thrown if the payment submitted by a purchases is incorrect.
     */
    error WrongPayment(uint256 want);

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The maximum number of tokens.
     */
    uint16 internal constant _MAX_TOTAL_SUPPLY = 1152;

    /**
     * @notice The maximum number of tokens that can be minted by the contract
     * steerer.
     */
    uint16 internal constant _MAX_NUM_OWNER_MINTS = 48;

    /**
     * @notice The maximum number of tokens that can be purchased.
     */
    uint16 internal constant _MAX_NUM_SELLABLE =
        _MAX_TOTAL_SUPPLY - _MAX_NUM_OWNER_MINTS;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The current stage of the contract.
     * @dev Enables/disables certain contract features.
     */
    Stage public stage;

    /**
     * @notice The number of tokens that can still be purchased.
     */
    uint16 public numSellable;

    /**
     * @notice The number of tokens that can still be minted by the contract
     * steerer.
     */
    uint16 internal _numMintableByOwner;

    /**
     * @notice The number of tokens that can be minted by each wallet during the
     * public minting phase.
     */
    uint16 public publicMintingCap;

    /**
     * @notice The primary revenue receiver.
     */
    address payable public primaryReceiver;

    /**
     * @notice Keeps track of the number of mint of each wallet in the public
     * minting phase.
     */
    mapping(address => uint256) public numPublicMints;

    /**
     * @notice The price to purchase a single token.
     */
    uint256 internal _price;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(
        address admin,
        address steerer,
        address payable primaryReceiver_,
        address payable royaltiesReceiver,
        string memory baseTokenURI_,
        IERC721 proofCollective,
        IDelegationRegistry delegationRegistry
    )
        ERC721ACommon(
            admin,
            steerer,
            "Archive of Feelings by Mika Tajima",
            "AOF",
            royaltiesReceiver,
            750
        )
        BaseTokenURI(baseTokenURI_)
        ClaimableWithDelegatedToken(proofCollective, delegationRegistry)
    {
        _numMintableByOwner = _MAX_NUM_OWNER_MINTS;
        numSellable = _MAX_NUM_SELLABLE;
        primaryReceiver = primaryReceiver_;
        publicMintingCap = 5;
        _price = 0.1 ether;
    }

    // =========================================================================
    //                           Minting
    // =========================================================================

    /**
     * @notice The price to purchase a single token.
     */
    function price() public view returns (uint256) {
        return _price;
    }

    /**
     * @notice Ensures that a method can only be called during a certain stage.
     */
    modifier onlyDuring(Stage stage_) {
        if (stage != stage_) {
            revert WrongStage(stage_);
        }
        _;
    }

    /**
     * @notice Checks if a given number of tokens can be purchased in the
     * current execution context.
     * @dev Intended to be called by the purchase routines. Reverts if the
     * purchase cannot be performed.
     */
    function _beforePurchase(uint256 num) internal {
        if (num > numSellable) {
            revert TooManyPurchasesRequested(numSellable);
        }

        uint256 cost = num * price();
        if (cost != msg.value) {
            revert WrongPayment(cost);
        }
    }

    /**
     * @notice Executes a purchase.
     * @dev Intended to be called by the purchase routines, after checking its
     * validity.
     */
    function _doPurchase(address to, uint256 num) internal {
        numSellable -= SafeCast.toUint16(num);
        primaryReceiver.sendValue(msg.value);
        _mint(to, num);
    }

    // =========================================================================
    //                       Phase 1 - Proof Collective
    // =========================================================================

    /**
     * @inheritdoc ClaimableWithToken
     * @dev Revert on incorrect stage.
     */
    function _beforeClaimWithTokens(address, uint256[] calldata tokenIds)
        internal
        virtual
        override
        onlyDuring(Stage.ProofCollective)
    {
        _beforePurchase(tokenIds.length);
    }

    /**
     * @inheritdoc ClaimableWithToken
     */
    function _doClaimFromTokens(address to, uint256 num)
        internal
        virtual
        override
    {
        _doPurchase(to, num);
    }

    // =========================================================================
    //                       Phase 2 - Premint Allowlist
    // =========================================================================

    /**
     * @inheritdoc ClaimableWithSignature
     * @dev Revert on incorrect stage.
     */
    function _beforeClaimWithSignature(Claim calldata claim)
        internal
        virtual
        override
        onlyDuring(Stage.Allowlist)
    {
        _beforePurchase(claim.num);
    }

    /**
     * @inheritdoc ClaimableWithSignature
     */
    function _doClaimFromSignature(address to, uint256 num)
        internal
        virtual
        override
    {
        _doPurchase(to, num);
    }

    // =========================================================================
    //                       Phase 3 - Public Mint
    // =========================================================================

    /**
     * @notice Minting interface for the public phase.
     * @dev Revert on incorrect stage or if the per-wallet limit is exhausted.
     */
    function mintPublic(uint16 num) external payable onlyDuring(Stage.Public) {
        _beforePurchase(num);

        uint256 numPurchasesAfter = numPublicMints[msg.sender] + num;
        if (numPurchasesAfter > publicMintingCap) {
            revert WalletLimitExhausted(
                publicMintingCap - numPublicMints[msg.sender]
            );
        }
        numPublicMints[msg.sender] = numPurchasesAfter;

        _doPurchase(msg.sender, num);
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Allows the contract steerer to mint the reserved allocation
     */
    function ownerMint(MintBatch[] calldata batches)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        uint16 total;
        for (uint256 i; i < batches.length; ++i) {
            total += batches[i].num;
        }
        if (total > _numMintableByOwner) {
            revert TooManyOwnerMintsRequested(_numMintableByOwner);
        }
        _numMintableByOwner -= total;

        for (uint256 i; i < batches.length; ++i) {
            _mint(batches[i].to, batches[i].num);
        }
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

    /**
     * @notice Changes the current stage of the contract.
     */
    function setStage(Stage stage_) external onlyRole(DEFAULT_STEERING_ROLE) {
        stage = stage_;
    }

    /**
     * @notice Changes the per-wallet minting cap for the public minting phase.
     */
    function setPublicMintingCap(uint16 publicMintingCap_)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        publicMintingCap = publicMintingCap_;
    }

    /**
     * @notice Changes the primary revenue receiver.
     */
    function setPrimaryReceiver(address payable primaryReceiver_)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        primaryReceiver = primaryReceiver_;
    }

    /**
     * @notice Changes the sales price.
     */
    function setPrice(uint256 newPrice)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _price = newPrice;
    }

    // =========================================================================
    //                        Inheritance resolution
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

    function _baseURI()
        internal
        view
        virtual
        override(ERC721A, ERC721ACommonBaseTokenURI)
        returns (string memory)
    {
        return ERC721ACommonBaseTokenURI._baseURI();
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
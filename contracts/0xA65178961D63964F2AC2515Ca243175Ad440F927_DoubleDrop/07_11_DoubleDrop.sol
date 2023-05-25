// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "./IDoubleDropNFT.sol";
import "./IDoubleDrop.sol";
import "./IProvenance.sol";
import "./SignedRedeemer.sol";

/// @title The Hashmasks Double Drop
/// @author fancyrats.io
/**
 * @notice Holders of Hashmasks NFTs can redeem Hashmasks Elementals, Derivatives, or burn their masks to get both!
 * Holders can only choose one redemption option per Hashmask NFT.
 * Once a selection is made, that NFT cannot be used to redeem again! Choose wisely!
 */
/**
 * @dev Hashmasks holders must set approval for this contract in order to "burn".
 * The original Hashmasks contract does not have burn functionality, so we move masks into the 0xdEaD wallet.
 * Elementals and Derivatives contracts must be deployed and addresses set prior to activating redemption.
 */
contract DoubleDrop is IDoubleDrop, Ownable, SignedRedeemer {
    event ElementalsRedeemed(uint256[] indexed tokenIds, address indexed redeemer);
    event DerivativesRedeemed(uint256[] indexed tokenIds, address indexed redeemer);
    event HashmasksBurned(uint256[] indexed tokenIds, address indexed redeemer);

    address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    bool public isActive;
    bool public contractsInitialized;

    uint256 public elementalsProvenance;

    mapping(uint256 => bool) public redeemedHashmasks;

    IERC721 public hashmasks;
    IDoubleDropNFT public derivatives;
    IDoubleDropNFT public elementals;

    constructor(address signer_) Ownable() SignedRedeemer(signer_) {}

    /// @notice Redeem Hashmasks Elementals NFTs
    /// @dev Resulting Elementals will have matching token IDs.
    /// @param signature Signed message from our website that validates token ownership
    /// @param tokenIds Ordered array of Hashmasks NFT ids used to claim the Elementals.
    function redeemElementals(bytes calldata signature, uint256[] calldata tokenIds)
        public
        isValidRedemption(signature, tokenIds)
    {
        emit ElementalsRedeemed(tokenIds, msg.sender);
        elementals.redeem(tokenIds, msg.sender);
    }

    /// @notice Redeem Hashmasks Derivatives NFTs
    /// @dev Resulting Derivatives will have matching token IDs.
    /// @param signature Signed message from our website that validates token ownership
    /// @param tokenIds Ordered array of Hashmasks NFT ids used to claim the Derivatives.
    function redeemDerivatives(bytes calldata signature, uint256[] calldata tokenIds)
        public
        isValidRedemption(signature, tokenIds)
    {
        emit DerivativesRedeemed(tokenIds, msg.sender);
        derivatives.redeem(tokenIds, msg.sender);
    }

    /**
     * @notice Burns Hashmasks and redeems one elemental and one derivative per Hashmask burned.
     * Requires this contract to be approved as an operator for the Hashmasks tokens provided.
     * CAUTION: ONLY APPROVE OR SETAPPROVALFORALL FROM THEHASHMASKS.COM
     * CAUTION: THIS ACTION IS PERMANENT. Holders will not be able to retrieve their burned Hashmask NFTs.
     */
    /**
     * @dev Resulting Derivatives and Elementals will have matching token IDs.
     *  Approval must be managed on the frontend.
     */
    /// @param signature Signed message from our website that validates token ownership
    /// @param tokenIds Ordered array of Hashmasks NFT ids to burn and use for double redemption
    function burnMasksForDoubleRedemption(bytes calldata signature, uint256[] calldata tokenIds)
        public
        isValidRedemption(signature, tokenIds)
    {
        emit HashmasksBurned(tokenIds, msg.sender);
        emit ElementalsRedeemed(tokenIds, msg.sender);
        emit DerivativesRedeemed(tokenIds, msg.sender);

        _burnMasks(tokenIds);
        elementals.redeem(tokenIds, msg.sender);
        derivatives.redeem(tokenIds, msg.sender);
    }

    /**
     * @notice Sets the Derivatives and Elementals contract addresses for redemption.
     * Caller must be contract owner.
     * CAUTION: ADDRESSES CAN ONLY BE SET ONCE.
     */
    /// @dev derivativesAddress and elementalsAddress must conform to IDoubleDropNFT
    /// @param hashmasksAddress The Hashmasks NFT contract address
    /// @param derivativesAddress The Hashmasks Derivatives NFT contract address
    /// @param elementalsAddress The Hashmasks Elementals NFT contract address
    function setTokenContracts(address hashmasksAddress, address derivativesAddress, address elementalsAddress)
        public
        onlyOwner
    {
        if (contractsInitialized) revert ContractsAlreadyInitialized();
        if (hashmasksAddress == address(0) || derivativesAddress == address(0) || elementalsAddress == address(0)) {
            revert ContractsCannotBeNull();
        }

        contractsInitialized = true;
        hashmasks = IERC721(hashmasksAddress);
        derivatives = IDoubleDropNFT(derivativesAddress);
        elementals = IDoubleDropNFT(elementalsAddress);
    }

    /**
     * @notice Asks the ProvenanceGenerator for a random number
     * Caller must be contract owner
     * Can only be set once
     */
    /// @dev Provenance implementation uses chainlink, so that will need setup first
    /// @param generatorAddress Contract conforming to IProvenance
    function setRandomProvenance(address generatorAddress) public onlyOwner {
        if (elementalsProvenance != 0) revert ElementalsProvenanceAlreadySet();
        if (generatorAddress == address(0)) revert ProvenanceContractCannotBeNull();

        IProvenance provenanceGenerator = IProvenance(generatorAddress);
        elementalsProvenance = provenanceGenerator.getRandomProvenance();

        if (elementalsProvenance == 0) revert ElementalsProvenanceNotSet();
    }

    /**
     * @notice Sets the known signer address used by the redemption backend to validate ownership
     * Caller must be contract owner.
     */
    /// @dev signer is responsible for signing redemption messages on the backend
    /// @param signer_ public address to expected to sign redemption signatures
    function setSigner(address signer_) public onlyOwner {
        _setSigner(signer_);
    }

    /**
     * @notice Turn on/off Double Drop redemption.
     * Starts out paused.
     * Caller must be contract owner.
     */
    /// @dev setTokenContracts must be called prior to activating.
    /// @param isActive_ updated redemption active status. false to pause. true to resume.
    function setIsActive(bool isActive_) public onlyOwner {
        if (address(hashmasks) == address(0) || address(derivatives) == address(0) || address(elementals) == address(0))
        {
            revert ContractsNotInitialized();
        }
        if (elementalsProvenance == 0) revert ElementalsProvenanceNotSet();
        isActive = isActive_;
    }

    function _burnMasks(uint256[] calldata tokenIds) private {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            hashmasks.safeTransferFrom(msg.sender, BURN_ADDRESS, tokenIds[i]);
        }
    }

    modifier isValidRedemption(bytes calldata signature, uint256[] calldata tokenIds) {
        if (!isActive) revert RedemptionNotActive();
        if (!validateSignature(signature, tokenIds, msg.sender)) revert InvalidSignature();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (hashmasks.ownerOf(tokenIds[i]) != msg.sender) revert NotTokenOwner();
            if (redeemedHashmasks[tokenIds[i]]) revert TokenAlreadyRedeemed();
            redeemedHashmasks[tokenIds[i]] = true;
        }
        _;
    }
}
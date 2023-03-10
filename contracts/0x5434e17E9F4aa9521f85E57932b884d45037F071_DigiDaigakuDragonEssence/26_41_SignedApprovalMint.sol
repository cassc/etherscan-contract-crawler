// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMintTokenBase.sol";
import "./SequentialMintBase.sol";
import "../access/InitializableOwnable.sol";
import "../../initializable/ISignedApprovalInitializer.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error AddressAlreadyMinted();
error InvalidSignature();
error MaxQuantityMustBeGreaterThanZero();
error MintExceedsMaximumAmountBySignedApproval();
error SignedClaimsAreDecommissioned();
error SignerAlreadyInitialized();
error SignerCannotBeInitializedAsAddressZero();
error SignerIsAddressZero();


/**
* @title SignedApprovalMint
* @author Limit Break, Inc.
* @notice A contract mix-in that may optionally be used with extend ERC-721 tokens with Signed Approval minting capabilities, allowing an approved signer to issue a limited amount of mints.
* @dev Inheriting contracts must implement `_mintToken` and implement EIP-165 support as shown:
*
* function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureNFT, IERC165) returns (bool) {
*     return
*     interfaceId == type(ISignedApproverInitializer).interfaceId ||
*     super.supportsInterface(interfaceId);
*  }
*
*/
abstract contract SignedApprovalMint is InitializableOwnable, SafeMintTokenBase, SequentialMintBase, EIP712, ISignedApprovalInitializer {

    /// @dev Returns true if signed claims have been decommissioned, false otherwise.
    bool private _signedClaimsDecommissioned;

    /// @dev The address of the signer for approved mints.
    address private _approvalSigner;

    /// @dev The maximum amount of mints done by the approval signer
    /// NOTE: This is an aggregate of all signers, updating signer will not reset or modify this amount.
    uint256 private _maxQuantityMintable;

    /// @dev The amount minted by all signers.
    /// NOTE: This is an aggregate of all signers, updating signer will not reset or modify this amount.
    uint256 private _mintedAmount;

    /// @dev Mapping of addresses who have already minted 
    mapping(address => bool) private addressMinted;

    /// @dev Emitted when signatures are decommissioned
    event SignedClaimsDecommissioned();

    /// @dev Emitted when a signed mint is claimed
    event SignedMintClaimed(address indexed minter, uint256 startTokenId, uint256 endTokenId);

    /// @dev Emitted when a signer is updated
    event SignerUpdated(address oldSigner, address newSigner); 

    /// @notice Allows a user to claim/mint one or more tokens as approved by the approved signer
    ///
    /// Throws when a signature is invalid.
    /// Throws when the quantity provided does not match the quantity on the signature provided.
    /// Throws when the address has already claimed a token.
    /// Throws if safe mint receiver is not an EOA or a contract that can receive tokens.
    function claimSignedMint(bytes calldata signature, uint256 quantity) external {
        if (addressMinted[_msgSender()]) {
            revert AddressAlreadyMinted();
        }

        if (_approvalSigner == address(0)) { 
            revert SignerIsAddressZero();
        }

        _requireSignedClaimsActive();

        uint256 newTotal = _mintedAmount + quantity;
        if (newTotal > _maxQuantityMintable) {
            revert MintExceedsMaximumAmountBySignedApproval();
        }

        _mintedAmount = newTotal;

        bytes32 hash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("Approved(address wallet,uint256 quantity)"),
                    _msgSender(),
                    quantity
                )
            )
        );

        if (_approvalSigner != ECDSA.recover(hash, signature)) {
            revert InvalidSignature();
        }

        addressMinted[_msgSender()] = true;

        uint256 tokenIdToMint = getNextTokenId();

        emit SignedMintClaimed(_msgSender(), tokenIdToMint, tokenIdToMint + quantity - 1);

        unchecked {
            _advanceNextTokenIdCounter(quantity);

            for(uint256 i = 0; i < quantity; ++i) {
                _safeMintToken(_msgSender(), tokenIdToMint + i);
            }
        }
    }

    /// @notice Decommissions signed approvals
    /// This is a permanent decommissioning, once this is set, no further signatures can be claimed
    ///
    /// Throws if caller is not owner
    /// Throws if already decommissioned
    function decommissionSignedApprovals() external onlyOwner {
        _requireSignedClaimsActive();
        _signedClaimsDecommissioned = true;
        emit SignedClaimsDecommissioned();
    }

    /// @dev Initializes the signer address for signed approvals
    /// This cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    ///
    /// Throws when called by non-owner of contract.
    /// Throws when the signer has already been initialized.
    /// Throws when the provided signer is address(0).
    /// Throws when maxQuantity = 0
    function initializeSigner(address signer, uint256 maxQuantity) public override onlyOwner {
        if(_approvalSigner != address(0)) {
            revert SignerAlreadyInitialized();
        }
        if(signer == address(0)) {
            revert SignerCannotBeInitializedAsAddressZero();
        }
        if(maxQuantity == 0) {
            revert MaxQuantityMustBeGreaterThanZero();
        }
        _initializeNextTokenIdCounter();
        _approvalSigner = signer;
        _maxQuantityMintable = maxQuantity;
    }

    /// @dev Allows signer to update the signer address
    /// This allows the signer to set new signer to address(0) to prevent future allowed mints
    /// NOTE: Setting signer to address(0) is irreversible - approvals will be disabled permanently and all outstanding signatures will be invalid.
    ///
    /// Throws when caller is not owner
    /// Throws when current signer is address(0)
    function setSigner(address newSigner) public onlyOwner {
        if(_signedClaimsDecommissioned) {
            revert SignedClaimsAreDecommissioned();
        }

        emit SignerUpdated(_approvalSigner, newSigner);
        _approvalSigner = newSigner;
    }

    /// @notice Returns true if the provided account has already minted, false otherwise
    function hasMintedBySignedApproval(address account) public view returns (bool) {
        return addressMinted[account];
    }

    /// @notice Returns the address of the approved signer
    function approvalSigner() public view returns (address) {
        return _approvalSigner;
    }

    /// @notice Returns the maximum amount mintable by approved signers
    function maxQuantityMintable() public view returns (uint256) {
        return _maxQuantityMintable;
    }

    /// @notice Returns the current amount minted by approved signers
    function mintedAmount() public view returns (uint256) {
        return _mintedAmount;
    }

    /// @notice Returns true if signed claims have been decommissioned, false otherwise
    function signedClaimsDecommissioned() public view returns (bool) {
        return _signedClaimsDecommissioned;
    }

    /// @dev Internal function used to revert if signed claims are decommissioned.
    function _requireSignedClaimsActive() internal view {
        if(_signedClaimsDecommissioned) {
            revert SignedClaimsAreDecommissioned();
        }
    }
}
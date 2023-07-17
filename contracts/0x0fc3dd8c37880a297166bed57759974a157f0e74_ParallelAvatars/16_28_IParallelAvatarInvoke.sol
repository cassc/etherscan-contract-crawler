// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IParallelAvatarInvoke is IERC2981 {
    /**
     * @notice Throw if the max supply exceeds uint64, a limit
     *         due to the storage of bit-packed variables in ERC721A.
     */
    error CannotExceedMaxSupplyOfUint64(uint256 newMaxSupply);

    /**
     * @dev Revert with an error when attempting to set the provenance
     *      hash after the mint has started.
     */
    error ProvenanceHashCannotBeSetAfterMintStarted();

    /**
     * @dev Revert if the royalty basis points is greater than 10_000.
     */
    error InvalidRoyaltyBasisPoints(uint256 basisPoints);

    /**
     * @dev Revert if the royalty address is being set to the zero address.
     */
    error RoyaltyAddressCannotBeZeroAddress();

    /**
     * @dev Revert if not owner.
     */
    error OnlyOwner();

    /**
     * @dev Revert Invoke is disabled.
     */
    error ContractDisabled();

    /**
     * @dev Revert verifier is not set.
     */
    error VerifierNotSet();

    /**
     * @dev Revert if Invoke eth receiver call did not succeed.
     */
    error EthTransferFailed();

    /**
     * @dev Revert if trying to update a baseURI that's already locked.
     */
    error LockedBaseURI();

    /**
     * @dev Revert if trying to set a zero address.
     */
    error ZeroAddress();

    /**
     * @dev Emit an event for token metadata reveals/updates,
     *      according to EIP-4906.
     *
     * @param _fromTokenId The start token id.
     * @param _toTokenId   The end token id.
     */
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /**
     * @dev Emit an event when baseURI gets locked.
     *
     */
    event BaseURILocked();

    /**
     * @dev Emit an event for prime address updates.
     *
     * @param newPrimeAddress the new prime address.
     */
    event PrimeAddressSet(address indexed newPrimeAddress);

    /**
     * @dev Emit an event when the URI for the collection-level metadata
     *      is updated.
     */
    event ContractURIUpdated(string newContractURI);

    /**
     * @dev Emit an event when the disabled state gets set.
     */
    event IsDisabledSet(bool newDisabledState);

    /**
     * @dev Emit an event when the max token supply is updated.
     */
    event MaxSupplyUpdated(uint256 newMaxSupply);

    /**
     * @dev Emit an event with the previous and new provenance hash after
     *      being updated.
     */
    event ProvenanceHashUpdated(bytes32 previousHash, bytes32 newHash);

    /**
     * @dev Emit an event when the royalties info is updated.
     */
    event RoyaltyInfoUpdated(address receiver, uint256 bps);

    /**
     * @notice A struct defining royalty info for the contract.
     */
    struct RoyaltyInfo {
        address royaltyAddress;
        uint96 royaltyBps;
    }

    /**
     * @notice Sets the base URI for the token metadata and emits an event.
     *
     * @param tokenURI The new base URI to set.
     */
    function setBaseURI(string calldata tokenURI) external;

    /**
     * @notice Lock the baseURI forever.
     *
     */
    function lockBaseURI() external;

    /**
     * @notice Sets the prime address for contract.
     *
     * @param prime The new prime address.
     */
    function setPrime(address prime) external;

    /**
     * @notice Sets the contract URI for contract metadata.
     *
     * @param newContractURI The new contract URI.
     */
    function setContractURI(string calldata newContractURI) external;

    /**
     * @notice Sets the contract disabled state.
     *
     * @param disabled The new disabled state.
     */
    function setDisabled(bool disabled) external;

    /**
     * @notice Sets the provenance hash and emits an event.
     *
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it has not been
     *         modified after mint started.
     *
     *         This function will revert after the first item has been minted.
     *
     * @param newProvenanceHash The new provenance hash to set.
     */
    function setProvenanceHash(bytes32 newProvenanceHash) external;

    /**
     * @notice Sets the address and basis points for royalties.
     *
     * @param newInfo The struct to configure royalties.
     */
    function setRoyaltyInfo(RoyaltyInfo calldata newInfo) external;

    /**
     * @notice Returns the base URI for token metadata.
     */
    function baseURI() external view returns (string memory);

    /**
     * @notice Returns the contract URI.
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Returns the max token supply.
     */
    function maxSupply() external view returns (uint256);

    /**
     * @notice Returns the provenance hash.
     *         The provenance hash is used for random reveals, which
     *         is a hash of the ordered metadata to show it is unmodified
     *         after mint has started.
     */
    function provenanceHash() external view returns (bytes32);

    /**
     * @notice Returns the address that receives royalties.
     */
    function royaltyAddress() external view returns (address);

    /**
     * @notice Returns the royalty basis points out of 10_000.
     */
    function royaltyBasisPoints() external view returns (uint256);
}
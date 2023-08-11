// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IOlimpoPass {
    /* Mint Struct */
    struct MintPhases {
        string phaseName;
        uint256 mintPrice;
        address[] allowlist;
        bool isActive;
    }

    /**
     * @dev Emitted when `tokenId` is minted.
     */
    event Minted(address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when the minting phase is created.
     */
    event PhaseCreated(uint256 indexed phaseId, string phaseName);

    /**
     * @dev Emitted when the minting phase is deleted.
     */
    event PhaseDeleted(uint256 indexed phaseId);

    /**
     * @dev Emitted when the phase active status changes.
     */
    event PhaseActivity(
        uint256 indexed phaseId,
        string phaseName,
        bool isActive
    );

    /**
     * @dev Create a new `Mint Phase` regarding the input parameters and right
     * conditions for the allowlist.
     *
     * `id` starts at 0 and increments every new phase. This helps coordinating
     * the launch sequence with more ease.
     *
     * The phase is created with a `name`, `price` and an `allowlist`.
     * The `allowlist` is an array of addresses that are allowed to mint tokens
     * in the given phase. The `price` is the amount of ETH that the user has
     * to pay to mint a token.
     *
     * Notice that: phases can be switched on and off. This is done by the
     * `changePhaseActiveState` function. Phases can also be deleted by the
     * `deletePhase` function in case there are invalid inputs or compromised
     * wallets in the allowlist.
     *
     * Requirements:
     *
     * - `msg.sender` must be the contract admin.
     * - `_name` must not be empty to avoid non-existent phases.
     *
     * Emits a {PhaseCreated} event.
     */
    function createMintingPhase(
        string calldata _name,
        uint256 _price,
        address[] memory _addresses
    ) external;

    /**
     * @dev Deletes an existing phase regarding the given `phaseId`.
     *
     * This external function allows the contract admin to delete a minting
     * phase. The phase is deleted based on the provided `phaseId`.
     *
     * Notice that this feature is a storage management decision. To avoid
     * having phases that doesn`t not consent to the launch sequence.
     *
     * IMPORTANT! Watch when deleting phases. This action will remove the
     * phase from the array, but if data is already stored in the deleted
     * phase id mappings, it will remain there. This means that the phase
     * deletion will not remove the data from the mappings. Please do not
     * delete phases if you have already minted tokens in that phase. You
     * should deactivate the phase instead, or create an empty phase as
     * replacement.
     *
     * Requirements:
     *
     * - `msg.sender` must be the contract admin.
     * - `_id` must be a valid phase.
     *
     * Emits a {PhaseDeleted} event.
     */
    function deletePhase(uint256 _id) external;

    /**
     * @dev Changes the active state of a phase regarding the given `phaseId`.
     *
     * This external function allows the contract admin to trigger the active
     * state of a minting phase. The phase is deleted based on the provided
     * `phaseId`.
     *
     * This function will be activated by the contract admin when each launch
     * sequence is ready to rock or ready to kick its boots.
     *
     * Requirements:
     *
     * - `msg.sender` must be the contract admin.
     * - `_id` must be a valid phase.
     *
     * Emits a {PhaseDeleted} event.
     */
    function changePhaseActiveState(uint256 _id) external;

    /**
     * @dev Returns the current phase struct information.
     *
     * Requirements:
     *
     * - Phase `_id` must exist.
     */
    function getPhase(uint256 _id) external view returns (MintPhases memory);

    /**
     * @dev Returns a boolean value if the address `_addr` has already
     * minted a token in the phase `_id`.
     *
     * Requirements:
     *
     * - Phase `_id` must exist.
     */
    function getMintedStatus(
        uint256 _id,
        address _addr
    ) external view returns (bool);

    /**
     * @dev Returns royalty info registered within the ERC-2981 standard.
     *
     * Notice that the ERC-2981 don't have a direct way to get the royalty
     * info once it's stored in the contract. This function is a hardcoded
     * workaround.
     */
    function getRoyaltyInfo() external view returns (address, uint96);

    /**
     * @dev Withdraw funds from the contract to fixed contracts.
     */
    function withdraw() external payable;
}
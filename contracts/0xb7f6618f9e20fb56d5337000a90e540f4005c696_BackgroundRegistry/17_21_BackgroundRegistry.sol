// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {IMoonbirds} from "moonbirds/IMoonbirds.sol";

import {MoonbirdAuthBase} from "moonbirds-inchain/MoonbirdAuth.sol";
import {ProofBackgroundRegistry} from "moonbirds-inchain/ProofBackgroundRegistry.sol";
import {IEligibilityConstraint} from "moonbirds-inchain/eligibility/IEligibilityConstraint.sol";

import {Features, FeaturesLib} from "moonbirds-inchain/gen/Features.sol";

/**
 * @notice Registry that allows Moonbird holders to toggle various backgrounds
 * on their Moonbirds.
 */
contract BackgroundRegistry is MoonbirdAuthBase, Ownable {
    using FeaturesLib for Features;

    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if somebody else than the Moonbird owner tries to set its
     * background.
     */
    error OnlyMoonbirdOwner();

    /**
     * @notice Thrown if a holder tries to set background settings after the
     * registry was closed.
     */
    error RegistryClosed();

    // =========================================================================
    //                           Events
    // =========================================================================

    /**
     * @notice Emitted whenever a holder changes their settings in the registry.
     */
    event BackgroundSettingChanged(
        uint256 indexed tokenId,
        uint96 indexed backgroundId
    );

    // =========================================================================
    //                           Types
    // =========================================================================

    /**
     * @notice Entries of the background registry.
     */
    struct RegistryEntry {
        // The moonbird owner at the time of setting.
        // Used to automatically negate entries on transfer.
        address owner;
        // The chosen background.
        uint96 backgroundId;
    }

    /**
     * @notice Used by the user to specify the setting that they want.
     */
    struct BackgroundSetting {
        uint256 tokenId;
        uint96 backgroundId;
    }

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The moonbird token.
     */
    IMoonbirds internal immutable _moonbirds;

    /**
     * @notice The previous registry for the PROOF background.
     * @dev If the current registry contains no entry for a given moonbird, we
     * will also check for entries in this registry.
     */
    ProofBackgroundRegistry internal immutable _registryV1;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice Stores the settings for each moonbird.
     * @dev Enabled backgrounds in the registry do not mean that they will
     * necessarily be shown in the final artwork. See also
     * `getActiveBackground`.
     */
    mapping(uint256 => RegistryEntry) internal _entries;

    /**
     * @notice List containing the criteria for the eligibility of a token for
     * a given backgroundId.
     * @dev The `backgroundId` is the index of the list.
     * @dev `backgroundId=0` corresponds to the standard background. Constraints
     * will be ignored.
     * @dev `backgroundId=1` corresponds to the PROOF background.
     * @dev Zero addresses correspond to deactivated backgrounds.
     */
    IEligibilityConstraint[] public eligibilityConstraints;

    /**
     * @notice Flag to toggle the fallback to the old registry if there are no
     * entries in the current one.
     */
    bool internal _useRegistryV1Fallback;

    /**
     * @notice Toggle to allow holders to set backgrounds for their Moonbirds.
     */
    bool public isOpen;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(IMoonbirds moonbirds_, ProofBackgroundRegistry registryV1_)
        MoonbirdAuthBase(moonbirds_, "BackgroundRegistry", "1.0")
    {
        _moonbirds = moonbirds_;
        _registryV1 = registryV1_;
        _useRegistryV1Fallback = true;

        eligibilityConstraints.push(IEligibilityConstraint(address(0)));
    }

    // =========================================================================
    //                                Getters
    // =========================================================================

    /**
     * @notice Retrieves the settings for a specific moonbird.
     * @dev Does not check if the token exists. Returns zero as default.
     */
    function getEntry(uint256 tokenId)
        external
        view
        returns (RegistryEntry memory)
    {
        return _entries[tokenId];
    }

    /**
     * @notice Retrieves the setting for a specific moonbird, with fallback to
     * the previous registry if no entry is found in the current one.
     */
    function getEntryWithFallback(uint256 tokenId)
        public
        view
        returns (RegistryEntry memory)
    {
        RegistryEntry memory entry = _entries[tokenId];

        // Fall back to the previous registry if no entry is set
        if (entry.owner == address(0) && _useRegistryV1Fallback) {
            ProofBackgroundRegistry.RegistryEntry memory oldEntry = _registryV1
                .getEntry(tokenId);

            entry.owner = oldEntry.proofer;
            entry.backgroundId = oldEntry.useProofBackground ? 1 : 0;
        }

        return entry;
    }

    // =========================================================================
    //                           Background activation
    // =========================================================================

    /**
     * @notice Returns the backgroundId that is currently active for a given
     * Moonbird.
     * @dev Next to the stored settings this also depends on a few other dynamic
     * conditions (see inlined comments below).
     */
    function getActiveBackground(uint256 tokenId) public view returns (uint96) {
        RegistryEntry memory entry = getEntryWithFallback(tokenId);

        // Don't show background if the MB was transferred to someone else
        if (_moonbirds.ownerOf(tokenId) != entry.owner) {
            return 0;
        }

        // Use default background if the token is not eligible to use the
        // selected one.
        if (!isTokenEligibleForBackground(tokenId, entry.backgroundId)) {
            return 0;
        }

        return entry.backgroundId;
    }

    /**
     * @notice Returns an array of all backgroundIds a given moonbird is
     * eligible for.
     */
    function getAllEligibleBackgrounds(uint256 tokenId)
        public
        view
        returns (uint96[] memory)
    {
        uint256 len = eligibilityConstraints.length;
        uint96[] memory activeBackgrounds = new uint96[](len);

        uint256 cursor;
        for (uint96 idx; idx < len; ++idx) {
            if (isTokenEligibleForBackground(tokenId, idx)) {
                activeBackgrounds[cursor++] = idx;
            }
        }

        assembly {
            // Shrink length to actual size
            mstore(activeBackgrounds, cursor)
        }

        return activeBackgrounds;
    }

    /**
     * @notice Checks if a given moonbird is eligible for a given backgroundId.
     * @dev Always eligible for `backgroundId=0` (native background)
     */
    function isTokenEligibleForBackground(uint256 tokenId, uint96 backgroundId)
        public
        view
        returns (bool)
    {
        if (backgroundId == 0) {
            return true;
        }

        if (backgroundId >= eligibilityConstraints.length) {
            return false;
        }

        IEligibilityConstraint constraint = eligibilityConstraints[
            backgroundId
        ];
        if (address(constraint) == address(0)) {
            return false;
        }
        return constraint.isEligible(tokenId);
    }

    // =========================================================================
    //                           Background setting
    // =========================================================================

    /**
     * @notice Toggles the backgroundId preference for a given Moonbird.
     * @dev Enabling the background here, does not mean that it will necessarily
     * be shown in the final artwork. See also `getActiveBackground`,
     * particularly `isTokenEligibleForBackground`.
     * @dev Reverts if the caller is not the Moonbird owner.
     * @dev We deliberately also allow non-sensical settings here to save gas
     * and catch it accordingly in `getActiveBackground`.
     */
    function setBackgrounds(BackgroundSetting[] calldata settings)
        external
        onlyIfOpen
    {
        for (uint256 i; i < settings.length; ++i) {
            _setBackgroundByOwner(
                settings[i].tokenId,
                settings[i].backgroundId
            );
        }
    }

    /**
     * @notice Toggles the PROOF background preference for a given Moonbird via
     * a delegated wallet.
     * @dev The caller has to be authorised by the moonbird owner.
     * @dev See also `setProofBackground`.
     */
    function setBackgroundsWithSignature(
        BackgroundSetting[] calldata settings,
        bytes calldata signature
    ) external onlyIfOpen {
        for (uint256 i; i < settings.length; ++i) {
            _setBackgroundWithSignature(
                settings[i].tokenId,
                settings[i].backgroundId,
                signature
            );
        }
    }

    // =========================================================================
    //                            Steering
    // =========================================================================

    /**
     * @notice Adds a new the contraint for a new background.
     */
    function addNewBackgroundConstraint(IEligibilityConstraint constraint)
        public
        onlyOwner
    {
        eligibilityConstraints.push(constraint);
    }

    /**
     * @notice Sets the constraint for an existing background.
     */
    function setBackgroundConstraint(
        uint96 backgroundId,
        IEligibilityConstraint constraint
    ) public onlyOwner {
        eligibilityConstraints[backgroundId] = constraint;
    }

    /**
     * @notice Toggles the lookup on the previous registry for tokens without
     * entry in the current one.
     */
    function setRegistryV1Fallback(bool isEnabled) public onlyOwner {
        _useRegistryV1Fallback = isEnabled;
    }

    /**
     * @notice Opens/closes the registry for user interactions.
     */
    function setOpen(bool open) external onlyOwner {
        isOpen = open;
    }

    // =========================================================================
    //                            Internals
    // =========================================================================

    /**
     * @notice Ensures that the caller owns the moonbird before storing the
     * background settings.
     * @dev Reverts otherwise.
     */
    function _setBackgroundByOwner(uint256 tokenId, uint96 backgroundId)
        internal
    {
        if (_moonbirds.ownerOf(tokenId) != msg.sender) {
            revert OnlyMoonbirdOwner();
        }

        _entries[tokenId] = RegistryEntry({
            owner: msg.sender,
            backgroundId: backgroundId
        });

        emit BackgroundSettingChanged(tokenId, backgroundId);
    }

    /**
     * @notice Ensures that the caller is authorised by the moonbirds owner
     * before storing the background settings.
     * @dev Reverts otherwise.
     */
    function _setBackgroundWithSignature(
        uint256 tokenId,
        uint96 backgroundId,
        bytes calldata signature
    ) internal onlyMoonbirdOwnerAuthorisedSender(tokenId, signature) {
        _entries[tokenId] = RegistryEntry({
            owner: _moonbirds.ownerOf(tokenId),
            backgroundId: backgroundId
        });

        emit BackgroundSettingChanged(tokenId, backgroundId);
    }

    modifier onlyIfOpen() {
        if (!isOpen) {
            revert RegistryClosed();
        }
        _;
    }
}
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "@iden3/contracts/interfaces/IState.sol";

/**
 * @title ILightweightStateV2
 * @notice The LightweightStateV2 contract is designed to hold information about the identities states and GIST roots that is migrated from the Polygon network.
 * The data is migrated using timestamp signatures from the Rarimo network validators, which makes the migration much more secure
 */
interface ILightweightStateV2 is IState {
    /**
     * @notice Enumeration with identifiers of methods that are used in signature verification
     * @param None the nonexistent method ID
     * @param AuthorizeUpgrade the method ID for upgrade function
     * @param ChangeSourceStateContract the method ID for changeSourceState contract function
     */
    enum MethodId {
        None,
        AuthorizeUpgrade,
        ChangeSourceStateContract
    }

    /**
     * @notice Structure that stores information about a particular identity state
     * @param id the identity ID
     * @param state the identity state hash for which the information is stored
     * @param replacedByState the state hash that replaced the current hash
     * @param createdAtTimestamp the timestamp when the state was created
     * @param createdAtBlock the block number when the state was created
     */
    struct StateData {
        uint256 id;
        uint256 state;
        uint256 replacedByState;
        uint256 createdAtTimestamp;
        uint256 createdAtBlock;
    }

    /**
     * @notice Structure that stores information about a particular GIST root
     * @param root the GIST root for which the information is stored
     * @param replacedByRoot the GIST root that replaced the current root
     * @param createdAtTimestamp the timestamp when the GIST root was created
     * @param createdAtBlock the block number when the GIST root was created
     */
    struct GistRootData {
        uint256 root;
        uint256 replacedByRoot;
        uint256 createdAtTimestamp;
        uint256 createdAtBlock;
    }

    /**
     * @notice Structure that stores information about a specific identity
     * @param lastState the actual identity state
     * @param statesData the mapping with information about all user's states
     */
    struct IdentityInfo {
        uint256 lastState;
        mapping(uint256 => StateData) statesData;
    }

    /**
     * @notice Event that emitted during the transition of a signed state
     * @param newGistRoot the new GIST root
     * @param identityId the identifier of the identity for which the state was transited
     * @param newIdentityState the new identity state
     * @param prevIdentityState the previous identity state
     * @param prevGistRoot the previous GIST root
     */
    event SignedStateTransited(
        uint256 newGistRoot,
        uint256 identityId,
        uint256 newIdentityState,
        uint256 prevIdentityState,
        uint256 prevGistRoot
    );

    /**
     * @notice Function for changing source state contract with signature from Rarimo validators
     * @param newSourceStateContract_ the new address for the source state contract
     * @param signature_ the signature from Rarimo validators
     */
    function changeSourceStateContract(
        address newSourceStateContract_,
        bytes calldata signature_
    ) external;

    /**
     * @notice Function to change the address of the signer that is used in signature verification
     * @param newSignerPubKey_ the new signer public key
     * @param signature_ the signature from Rarimo validators
     */
    function changeSigner(bytes calldata newSignerPubKey_, bytes calldata signature_) external;

    /**
     * @notice Function for transiting information about a specific identity's state from the Polygon network
     * @param prevState_ the previous identity state from the one whose information is passed on
     * @param prevGist_ the previous GIST root from the one whose information is passed on
     * @param stateData_ the information about the state to be saved
     * @param gistData_ the information about the GSIT to be saved
     * @param proof_ the proof of entry of the relevant leaf into Merkle Tree together with signature from Rarimo validators
     */
    function signedTransitState(
        uint256 prevState_,
        uint256 prevGist_,
        StateData calldata stateData_,
        GistRootData calldata gistData_,
        bytes calldata proof_
    ) external;

    /**
     * @notice Function that returns the address of the source state contract
     * @return The source state contract address
     */
    function sourceStateContract() external view returns (address);

    /**
     * @notice Function that returns the current GIST root
     * @return The current GIST root
     */
    function getGISTRoot() external view returns (uint256);

    /**
     * @notice Function that returns the info about current GIST root
     * @return The current GIST root info
     */
    function getCurrentGISTRootInfo() external view returns (GistRootInfo memory);

    /**
     * @notice Function that checks whether information about a specific identity exists or not
     * @param identityId_ the identity ID to be checked
     * @return true if identity exists, otherwise false
     */
    function idExists(uint256 identityId_) external view returns (bool);

    /**
     * @notice Function that checks whether a particular state exists for a particular identity
     * @param identityId_ the identity ID to check
     * @param state_ the state to check
     * @return true if state exists, otherwise false
     */
    function stateExists(uint256 identityId_, uint256 state_) external view returns (bool);
}
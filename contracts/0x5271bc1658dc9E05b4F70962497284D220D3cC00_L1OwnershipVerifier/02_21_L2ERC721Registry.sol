// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {
    CrossDomainMessenger
} from "@eth-optimism/contracts-bedrock/contracts/universal/CrossDomainMessenger.sol";
import {
    IOptimismMintableERC721
} from "@eth-optimism/contracts-periphery/contracts/universal/op-erc721/IOptimismMintableERC721.sol";
import { TwoStepOwnableUpgradeable } from "../access/TwoStepOwnableUpgradeable.sol";

/**
 * @title L2ERC721Registry
 * @notice An upgradeable registry of L2 ERC721 contracts that are recognized as legitimate L2
 *         representations of L1 ERC721 contracts. For each L1 contract, there is a single default
 *         L2 contract as well as a list of approved L2 contracts (which includes the default
 *         contract). The default L2 contract is recognized as the canonical L2 representation of
 *         the L1 ERC721, and the list of approved L2 contracts are also recognized as legitimate.
 */
contract L2ERC721Registry is TwoStepOwnableUpgradeable {
    /**
     * @notice Emitted when an L2 ERC721 is set to be the default contract for an L1 ERC721.
     *
     * @param l1ERC721 Address of the L1 ERC721.
     * @param l2ERC721 Address of the default L2 ERC721.
     * @param caller   Address of the caller.
     */
    event DefaultL2ERC721Set(
        address indexed l1ERC721,
        address indexed l2ERC721,
        address indexed caller
    );

    /**
     * @notice Emitted when an L2 ERC721 is set to be an approved contract for an L1 ERC721.
     *
     * @param l1ERC721 Address of the L1 ERC721.
     * @param l2ERC721 Address of the approved L2 ERC721.
     * @param caller   Address of the caller.
     */
    event L2ERC721Approved(
        address indexed l1ERC721,
        address indexed l2ERC721,
        address indexed caller
    );

    /**
     * @notice Emitted when an L2 ERC721 has its approval removed.
     *
     * @param l1ERC721 Address of the L1 ERC721 that corresponds to this L2 ERC721.
     * @param l2ERC721 Address of the approved L2 ERC721.
     * @param caller   Address of the caller.
     */
    event L2ERC721ApprovalRemoved(
        address indexed l1ERC721,
        address indexed l2ERC721,
        address indexed caller
    );

    /**
     * @notice Emitted when ownership is claimed for an L1 ERC721.
     *
     * @param owner    Address of the L1 ERC721's owner.
     * @param l1ERC721 Address of the L1 ERC721.
     */
    event L1ERC721OwnershipClaimed(address indexed owner, address indexed l1ERC721);

    /**
     * @notice Emitted when a new L1OwnershipVerifier address is set.
     *
     * @param newVerifier Address of the new L1OwnershipVerifier contract.
     */
    event L1OwnershipVerifierSet(address indexed newVerifier);

    /**
     * @notice Address of the L1OwnershipVerifier contract.
     */
    address public l1OwnershipVerifier;

    /**
     * @notice L2CrossDomainMessenger contract.
     */
    CrossDomainMessenger public l2Messenger;

    /**
     * @notice Maps an owner's address to the L1 ERC721 address that it owns. Note that this mapping
     *         may be outdated if an L1 ERC721 contract changes owners.
     */
    mapping(address => address) public l1ERC721Owners;

    /**
     * @notice Maps an L1 ERC721 address to its default L2 ERC721 address.
     */
    mapping(address => address) internal defaultL2ERC721s;

    /**
     * @notice Maps an L1 ERC721 to an array of approved L2 ERC721 addresses. The array includes the
     *         default L2 contract for the L1 ERC721, if it exists.
     */
    mapping(address => address[]) internal approvedL2ERC721s;

    /**
     * @notice Maps an approved L2 ERC721 address to its index in the `approvedL2ERC721s` mapping.
     */
    mapping(address => uint256) internal l2Indexes;

    /**
     * @notice Modifier that allows only the owner of this contract or the owner of the specified L1
     *         ERC721 to call a function.
     *
     * @param _l1ERC721 Address of the L1 ERC721.
     */
    modifier onlyRegistryOwnerOrL1ERC721Owner(address _l1ERC721) {
        require(
            msg.sender == owner() || l1ERC721Owners[msg.sender] == _l1ERC721,
            "L2ERC721Registry: caller is not registry owner or l1 erc721 owner"
        );
        _;
    }

    /**
     * @notice Ensures that the caller is a cross-chain message from the L1OwnershipVerifier.
     */
    modifier onlyL1OwnershipVerifier() {
        require(
            msg.sender == address(l2Messenger) &&
                l2Messenger.xDomainMessageSender() == l1OwnershipVerifier,
            "L2ERC721Registry: function can only be called from the l1 ownership verifier"
        );
        _;
    }

    /**
     * @notice Initializer. Only callable once.
     *
     * @param _l1OwnershipVerifier Address of the L1OwnershipVerifier contract.
     * @param _l2Messenger         Address of the L2CrossDomainMessenger.
     */
    function initialize(address _l1OwnershipVerifier, address _l2Messenger) external initializer {
        l1OwnershipVerifier = _l1OwnershipVerifier;
        l2Messenger = CrossDomainMessenger(_l2Messenger);

        // Initialize inherited contract
        __TwoStepOwnable_init();
    }

    /**
     * @notice Sets the default L2 ERC721 for the given L1 ERC721. This adds the L2 ERC721 to the
     *         list of approved L2 contracts for the given L1 contract if it is not already in the
     *         list, so there is no need to call `approveL2ERC721` in addition to this function for
     *         newly added contracts. Only callable by the owner of this contract or the owner of
     *         the L1 ERC721 contract. Note that the L2 ERC721 must implement
     *         IOptimismMintableERC721, since the interface is required to interact with the L2
     *         Bridge.
     *
     * @param _l1ERC721 Address of the L1 ERC721 that corresponds to the L2 ERC721.
     * @param _l2ERC721 Address of the L2 ERC721 to set as the default contract for the L1 ERC721.
     */
    function setDefaultL2ERC721(address _l1ERC721, address _l2ERC721)
        external
        onlyRegistryOwnerOrL1ERC721Owner(_l1ERC721)
    {
        require(_l1ERC721 != address(0), "L2ERC721Registry: l1 erc721 cannot be address(0)");
        require(_l2ERC721 != address(0), "L2ERC721Registry: l2 erc721 cannot be address(0)");
        require(
            getL1ERC721(_l2ERC721) == _l1ERC721,
            "L2ERC721Registry: l1 erc721 is not the remote address of the l2 erc721"
        );
        require(
            defaultL2ERC721s[_l1ERC721] != _l2ERC721,
            "L2ERC721Registry: l2 erc721 is already the default contract"
        );

        defaultL2ERC721s[_l1ERC721] = _l2ERC721;

        // Add the L2 ERC721 to the approved list if it is not already present.
        if (!isApprovedL2ERC721(_l1ERC721, _l2ERC721)) {
            _approveL2ERC721(_l1ERC721, _l2ERC721);
        }

        emit DefaultL2ERC721Set(_l1ERC721, _l2ERC721, msg.sender);
    }

    /**
     * @notice Adds a given L2 ERC721 to the list of approved contracts for the given L1 ERC721.
     *         Only callable by the owner of this contract or the owner of the L1 ERC721 contract.
     *         Note that this does not set the L2 ERC721 to be the default contract for the L1
     *         ERC721. That can be done by calling `setDefaultL2ERC721`. Also note that the L2
     *         ERC721 must implement IOptimismMintableERC721, since this interface is required to
     *         interact with the L2 Bridge.
     *
     * @param _l1ERC721 Address of the L1 ERC721 that corresponds to the L2 ERC721.
     * @param _l2ERC721 Address of the L2 ERC721 to approve.
     */
    function approveL2ERC721(address _l1ERC721, address _l2ERC721)
        external
        onlyRegistryOwnerOrL1ERC721Owner(_l1ERC721)
    {
        require(_l1ERC721 != address(0), "L2ERC721Registry: l1 erc721 cannot be address(0)");
        require(_l2ERC721 != address(0), "L2ERC721Registry: l2 erc721 cannot be address(0)");
        require(
            getL1ERC721(_l2ERC721) == _l1ERC721,
            "L2ERC721Registry: l1 erc721 is not the remote address of the l2 erc721"
        );
        require(
            !isApprovedL2ERC721(_l1ERC721, _l2ERC721),
            "L2ERC721Registry: l2 erc721 is already approved for the l1 erc721"
        );

        _approveL2ERC721(_l1ERC721, _l2ERC721);

        emit L2ERC721Approved(_l1ERC721, _l2ERC721, msg.sender);
    }

    /**
     * @notice Removes a given L2 ERC721 from the list of approved contracts for the given L1
     *         ERC721. If the L2 ERC721 to remove is the default contract for the L1 ERC721, this
     *         status will be removed as well. Only callable by the owner of this contract or the
     *         owner of the L1 ERC721 contract.
     *
     * @param _l1ERC721 Address of the L1 ERC721 that corresponds to the L2 ERC721.
     * @param _l2ERC721 Address of the L2 ERC721 to remove.
     */
    function removeL2ERC721Approval(address _l1ERC721, address _l2ERC721)
        external
        onlyRegistryOwnerOrL1ERC721Owner(_l1ERC721)
    {
        require(
            isApprovedL2ERC721(_l1ERC721, _l2ERC721),
            "L2ERC721Registry: l2 erc721 is not an approved contract for the l1 erc721"
        );

        // If the L2 ERC721 is the default L2 contract for this L1 ERC721, then remove its status as
        // the default contract.
        if (_l2ERC721 == defaultL2ERC721s[_l1ERC721]) {
            defaultL2ERC721s[_l1ERC721] = address(0);
        }

        // Get the array of approved L2 ERC721s for this L1 ERC721.
        address[] storage approved = approvedL2ERC721s[_l1ERC721];

        // To prevent a gap in the array, we store the last address in the index of the address to
        // delete, and then delete the last slot (swap and pop).

        uint256 lastIndex = approved.length - 1;
        uint256 targetIndex = l2Indexes[_l2ERC721];

        // If the address to delete is the last element in the list, the swap operation is
        // unnecessary.
        if (targetIndex != lastIndex) {
            address lastL2ERC721 = approved[lastIndex];

            // Move the last element to the slot of the address to delete
            approved[targetIndex] = lastL2ERC721;
            // Update the indexes mapping to reflect this change
            l2Indexes[lastL2ERC721] = targetIndex;
        }

        // Delete the contents at the last position of the array
        approved.pop();
        // Updates the indexes mapping to reflect the deletion
        delete l2Indexes[_l2ERC721];

        emit L2ERC721ApprovalRemoved(_l1ERC721, _l2ERC721, msg.sender);
    }

    /**
     * @notice Returns true if the L2 ERC721 is an approved contract, or the default contract, for
     *         the given L1 ERC721.
     *
     * @param _l1ERC721 Address of the L1 ERC721 that corresponds to the L2 ERC721.
     * @param _l2ERC721 Address of the L2 ERC721.
     *
     * @return True if the L2 ERC721 is in the approved list for the L1 ERC721.
     */
    function isApprovedL2ERC721(address _l1ERC721, address _l2ERC721) public view returns (bool) {
        address[] storage approved = approvedL2ERC721s[_l1ERC721];
        if (approved.length == 0) {
            return false;
        }
        return _l2ERC721 == approved[l2Indexes[_l2ERC721]];
    }

    /**
     * @notice Get the address of the default L2 ERC721 for the given L1 ERC721. The default L2
     *         contract is recognized as the single canonical L2 representation for the L1 ERC721.
     *         Note that this returns address(0) if there is no default L2 contract assigned to the
     *         given L1 contract. This also returns address(0) if the given L2 ERC721 is in the list
     *         of approved L2 contracts for the L1 ERC721, but is not the default contract.
     *
     * @param _l1ERC721 Address of the L1 ERC721.
     *
     * @return Address of the default L2 ERC721 for the L1 ERC721. Address(0) if it does not exist.
     */
    function getDefaultL2ERC721(address _l1ERC721) external view returns (address) {
        return defaultL2ERC721s[_l1ERC721];
    }

    /**
     * @notice Get the list of approved L2 ERC721s for a given L1 ERC721. Note that this list
     *         includes the default L2 contract for the given L1 contract.
     *
     * @param _l1ERC721 Address of the L1 ERC721 contract.
     *
     * @return Array of approved L2 ERC721s for the L1 ERC721. Returns an empty array if the L1
     *         contract has no approved L2 contracts.
     */
    function getApprovedL2ERC721s(address _l1ERC721) external view returns (address[] memory) {
        return approvedL2ERC721s[_l1ERC721];
    }

    /**
     * @notice Returns the L1 ERC721 address for the given L2 ERC721. This reverts if the L2 ERC721
     *         does not have a `remoteToken` function.
     *
     * @param _l2ERC721 Address of the L2 ERC721.
     *
     * @return Address of the L1 representation of the L2 ERC721.
     */
    function getL1ERC721(address _l2ERC721) public view returns (address) {
        return IOptimismMintableERC721(_l2ERC721).remoteToken();
    }

    /**
     * @notice Allows the owner of an L1 ERC721 to claim ownership rights over the L1 contract and
     *         its L2 representations in this registry. This allows the owner to set the default L2
     *         address and the list of approved L2 addresses for their L1 ERC721 in this contract.
     *         Must be called via the L1OwnershipVerifier contract on L1.
     *
     * @param owner_    Address of the new owner for the L1 ERC721.
     * @param _l1ERC721 Address of the L1 ERC721 being claimed.
     */
    function claimL1ERC721Ownership(address owner_, address _l1ERC721)
        external
        onlyL1OwnershipVerifier
    {
        l1ERC721Owners[owner_] = _l1ERC721;

        emit L1ERC721OwnershipClaimed(owner_, _l1ERC721);
    }

    /**
     * @notice Allows the owner of this contract to set a new L1OwnershipVerifier contract.
     *
     * @param _l1OwnershipVerifier Address of the new L1OwnershipVerifier.
     */
    function setL1OwnershipVerifier(address _l1OwnershipVerifier) external onlyOwner {
        l1OwnershipVerifier = _l1OwnershipVerifier;

        emit L1OwnershipVerifierSet(_l1OwnershipVerifier);
    }

    /**
     * @notice Approves an L2 ERC721 for a given L1 ERC721 by adding it to an array. Skips contracts
     *         that have already been added to the list.
     *
     * @param _l1ERC721 Address of the L1 ERC721 that corresponds to the L2 ERC721.
     * @param _l2ERC721 Address of the L2 ERC721 to approve.
     */
    function _approveL2ERC721(address _l1ERC721, address _l2ERC721) internal {
        address[] storage approved = approvedL2ERC721s[_l1ERC721];
        l2Indexes[_l2ERC721] = approved.length;
        approved.push(_l2ERC721);
    }
}
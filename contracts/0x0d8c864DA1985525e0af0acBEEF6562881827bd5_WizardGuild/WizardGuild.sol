/**
 *Submitted for verification at Etherscan.io on 2019-10-17
*/

pragma solidity >=0.5.6 <0.6.0;

/// @title Shared constants used throughout the Cheeze Wizards contracts
contract WizardConstants {
    // Wizards normally have their affinity set when they are first created,
    // but for example Exclusive Wizards can be created with no set affinity.
    // In this case the affinity can be set by the owner.
    uint8 internal constant ELEMENT_NOTSET = 0; //000
    // A neutral Wizard has no particular strength or weakness with specific
    // elements.
    uint8 internal constant ELEMENT_NEUTRAL = 1; //001
    // The fire, water and wind elements are used both to reflect an affinity
    // of Elemental Wizards for a specific element, and as the moves a
    // Wizard can make during a duel.
    // Note that if these values change then `moveMask` and `moveDelta` in
    // ThreeAffinityDuelResolver would need to be updated accordingly.
    uint8 internal constant ELEMENT_FIRE = 2; //010
    uint8 internal constant ELEMENT_WATER = 3; //011
    uint8 internal constant ELEMENT_WIND = 4; //100
    uint8 internal constant MAX_ELEMENT = ELEMENT_WIND;
}



/// @title ERC165Query example
/// @notice see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
contract ERC165Query {
    bytes4 constant _INTERFACE_ID_INVALID = 0xffffffff;
    bytes4 constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    function doesContractImplementInterface(
        address _contract,
        bytes4 _interfaceId
    )
        internal
        view
        returns (bool)
    {
        uint256 success;
        uint256 result;

        (success, result) = noThrowCall(_contract, _INTERFACE_ID_ERC165);
        if ((success == 0) || (result == 0)) {
            return false;
        }

        (success, result) = noThrowCall(_contract, _INTERFACE_ID_INVALID);
        if ((success == 0) || (result != 0)) {
            return false;
        }

        (success, result) = noThrowCall(_contract, _interfaceId);
        if ((success == 1) && (result == 1)) {
            return true;
        }
        return false;
    }

    function noThrowCall(
        address _contract,
        bytes4 _interfaceId
    )
        internal
        view
        returns (
            uint256 success,
            uint256 result
        )
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, _interfaceId);

        // solhint-disable-next-line no-inline-assembly
        assembly { // solium-disable-line security/no-inline-assembly
            let encodedParams_data := add(0x20, encodedParams)
            let encodedParams_size := mload(encodedParams)

            let output := mload(0x40)    // Find empty storage location using "free memory pointer"
            mstore(output, 0x0)

            success := staticcall(
                30000,                   // 30k gas
                _contract,               // To addr
                encodedParams_data,
                encodedParams_size,
                output,
                0x20                     // Outputs are 32 bytes long
            )

            result := mload(output)      // Load the result
        }
    }
}








/**
 * @title IERC165
 * @dev https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}



/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}




/// @title ERC165Interface
/// @dev https://eips.ethereum.org/EIPS/eip-165
interface ERC165Interface {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///      uses less than 30,000 gas.
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}



/// Utility library of inline functions on address payables.
/// Modified from original by OpenZeppelin.
contract Address {
    /// @notice Returns whether the target address is a contract.
    /// @dev This function will return false if invoked during the constructor of a contract,
    /// as the code is not actually created until after the constructor finishes.
    /// @param account address of the account to check
    /// @return whether the target address is a contract
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) } // solium-disable-line security/no-inline-assembly
        return size > 0;
    }
}




/// @title Wizard Non-Fungible Token
/// @notice The basic ERC-721 functionality for storing Cheeze Wizard NFTs.
///     Derived from: https://github.com/OpenZeppelin/openzeppelin-solidity/tree/v2.2.0
contract WizardNFT is ERC165Interface, IERC721, WizardConstants, Address {

    /// @notice Emitted when a wizard token is created.
    event WizardConjured(uint256 wizardId, uint8 affinity, uint256 innatePower);

    /// @notice Emitted when a Wizard's affinity is set. This only applies for
    ///         Exclusive Wizards who can have the ELEMENT_NOT_SET affinity,
    ///         and should only happen once for each Wizard.
    event WizardAffinityAssigned(uint256 wizardId, uint8 affinity);

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;

    /// @dev The base Wizard structure.
    /// Designed to fit in two words.
    struct Wizard {
        // NOTE: Changing the order or meaning of any of these fields requires an update
        //   to the _createWizard() function which assumes a specific order for these fields.
        uint8 affinity;
        uint88 innatePower;
        address owner;
        bytes32 metadata;
    }

    // Mapping from Wizard ID to Wizard struct
    mapping (uint256 => Wizard) public wizardsById;

    // Mapping from Wizard ID to address approved to control them
    mapping (uint256 => address) private wizardApprovals;

    // Mapping from owner address to number of owned Wizards
    mapping (address => uint256) internal ownedWizardsCount;

    // Mapping from owner to Wizard controllers
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /// @dev 0x80ac58cd ===
    ///    bytes4(keccak256('balanceOf(address)')) ^
    ///    bytes4(keccak256('ownerOf(uint256)')) ^
    ///    bytes4(keccak256('approve(address,uint256)')) ^
    ///    bytes4(keccak256('getApproved(uint256)')) ^
    ///    bytes4(keccak256('setApprovalForAll(address,bool)')) ^
    ///    bytes4(keccak256('isApprovedForAll(address,address)')) ^
    ///    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    ///    bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
    ///    bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///      uses less than 30,000 gas.
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return
            interfaceId == this.supportsInterface.selector || // ERC165
            interfaceId == _INTERFACE_ID_ERC721; // ERC721
    }

    /// @notice Gets the number of Wizards owned by the specified address.
    /// @param owner Address to query the balance of.
    /// @return uint256 representing the amount of Wizards owned by the address.
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return ownedWizardsCount[owner];
    }

    /// @notice Gets the owner of the specified Wizard
    /// @param wizardId ID of the Wizard to query the owner of
    /// @return address currently marked as the owner of the given Wizard
    function ownerOf(uint256 wizardId) public view returns (address) {
        address owner = wizardsById[wizardId].owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /// @notice Approves another address to transfer the given Wizard
    /// The zero address indicates there is no approved address.
    /// There can only be one approved address per Wizard at a given time.
    /// Can only be called by the Wizard owner or an approved operator.
    /// @param to address to be approved for the given Wizard
    /// @param wizardId ID of the Wizard to be approved
    function approve(address to, uint256 wizardId) public {
        address owner = ownerOf(wizardId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        wizardApprovals[wizardId] = to;
        emit Approval(owner, to, wizardId);
    }

    /// @notice Gets the approved address for a Wizard, or zero if no address set
    /// Reverts if the Wizard does not exist.
    /// @param wizardId ID of the Wizard to query the approval of
    /// @return address currently approved for the given Wizard
    function getApproved(uint256 wizardId) public view returns (address) {
        require(_exists(wizardId), "ERC721: approved query for nonexistent token");
        return wizardApprovals[wizardId];
    }

    /// @notice Sets or unsets the approval of a given operator.
    /// An operator is allowed to transfer all Wizards of the sender on their behalf.
    /// @param to operator address to set the approval
    /// @param approved representing the status of the approval to be set
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /// @notice Tells whether an operator is approved by a given owner.
    /// @param owner owner address which you want to query the approval of
    /// @param operator operator address which you want to query the approval of
    /// @return bool whether the given operator is approved by the given owner
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @notice Transfers the ownership of a given Wizard to another address.
    /// Usage of this method is discouraged, use `safeTransferFrom` whenever possible.
    /// Requires the msg.sender to be the owner, approved, or operator.
    /// @param from current owner of the Wizard.
    /// @param to address to receive the ownership of the given Wizard.
    /// @param wizardId ID of the Wizard to be transferred.
    function transferFrom(address from, address to, uint256 wizardId) public {
        require(_isApprovedOrOwner(msg.sender, wizardId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, wizardId);
    }

    /// @notice Safely transfers the ownership of a given Wizard to another address
    /// If the target address is a contract, it must implement `onERC721Received`,
    /// which is called upon a safe transfer, and return the magic value
    /// `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
    /// the transfer is reverted.
    /// Requires the msg.sender to be the owner, approved, or operator.
    /// @param from current owner of the Wizard.
    /// @param to address to receive the ownership of the given Wizard.
    /// @param wizardId ID of the Wizard to be transferred.
    function safeTransferFrom(address from, address to, uint256 wizardId) public {
        safeTransferFrom(from, to, wizardId, "");
    }

    /// @notice Safely transfers the ownership of a given Wizard to another address
    /// If the target address is a contract, it must implement `onERC721Received`,
    /// which is called upon a safe transfer, and return the magic value
    /// `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
    /// the transfer is reverted.
    /// Requires the msg.sender to be the owner, approved, or operator
    /// @param from current owner of the Wizard.
    /// @param to address to receive the ownership of the given Wizard.
    /// @param wizardId ID of the Wizard to be transferred.
    /// @param _data bytes data to send along with a safe transfer check
    function safeTransferFrom(address from, address to, uint256 wizardId, bytes memory _data) public {
        transferFrom(from, to, wizardId);
        require(_checkOnERC721Received(from, to, wizardId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /// @notice Returns whether the specified Wizard exists.
    /// @param wizardId ID of the Wizard to query the existence of..
    /// @return bool whether the Wizard exists.
    function _exists(uint256 wizardId) internal view returns (bool) {
        address owner = wizardsById[wizardId].owner;
        return owner != address(0);
    }

    /// @notice Returns whether the given spender can transfer a given Wizard.
    /// @param spender address of the spender to query
    /// @param wizardId ID of the Wizard to be transferred
    /// @return bool whether the msg.sender is approved for the given Wizard,
    /// is an operator of the owner, or is the owner of the Wizard.
    function _isApprovedOrOwner(address spender, uint256 wizardId) internal view returns (bool) {
        require(_exists(wizardId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(wizardId);
        return (spender == owner || getApproved(wizardId) == spender || isApprovedForAll(owner, spender));
    }

    /** @dev Internal function to create a new Wizard; reverts if the Wizard ID is taken.
     *       NOTE: This function heavily depends on the internal format of the Wizard struct
     *       and should always be reassessed if anything about that structure changes.
     *  @param wizardId ID of the new Wizard.
     *  @param owner The address that will own the newly conjured Wizard.
     *  @param innatePower The power level associated with the new Wizard.
     *  @param affinity The elemental affinity of the new Wizard.
     */
    function _createWizard(uint256 wizardId, address owner, uint88 innatePower, uint8 affinity) internal {
        require(owner != address(0), "ERC721: mint to the zero address");
        require(!_exists(wizardId), "ERC721: token already minted");
        require(wizardId > 0, "No 0 token allowed");
        require(innatePower > 0, "Wizard power must be non-zero");

        // Create the Wizard!
        wizardsById[wizardId] = Wizard({
            affinity: affinity,
            innatePower: innatePower,
            owner: owner,
            metadata: 0
        });

        ownedWizardsCount[owner]++;

        // Tell the world!
        emit Transfer(address(0), owner, wizardId);
        emit WizardConjured(wizardId, affinity, innatePower);
    }

    /// @notice Internal function to burn a specific Wizard.
    /// Reverts if the Wizard does not exist.
    /// Deprecated, use _burn(uint256) instead.
    /// @param owner owner of the Wizard to burn.
    /// @param wizardId ID of the Wizard being burned
    function _burn(address owner, uint256 wizardId) internal {
        require(ownerOf(wizardId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(wizardId);

        ownedWizardsCount[owner]--;
        // delete the entire object to recover the most gas
        delete wizardsById[wizardId];

        // required for ERC721 compatibility
        emit Transfer(owner, address(0), wizardId);
    }

    /// @notice Internal function to burn a specific Wizard.
    /// Reverts if the Wizard does not exist.
    /// @param wizardId ID of the Wizard being burned
    function _burn(uint256 wizardId) internal {
        _burn(ownerOf(wizardId), wizardId);
    }

    /// @notice Internal function to transfer ownership of a given Wizard to another address.
    /// As opposed to transferFrom, this imposes no restrictions on msg.sender.
    /// @param from current owner of the Wizard.
    /// @param to address to receive the ownership of the given Wizard
    /// @param wizardId ID of the Wizard to be transferred
    function _transferFrom(address from, address to, uint256 wizardId) internal {
        require(ownerOf(wizardId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(wizardId);

        ownedWizardsCount[from]--;
        ownedWizardsCount[to]++;

        wizardsById[wizardId].owner = to;

        emit Transfer(from, to, wizardId);
    }

    /// @notice Internal function to invoke `onERC721Received` on a target address.
    /// The call is not executed if the target address is not a contract
    /// @param from address representing the previous owner of the given Wizard
    /// @param to target address that will receive the Wizards.
    /// @param wizardId ID of the Wizard to be transferred
    /// @param _data bytes optional data to send along with the call
    /// @return bool whether the call correctly returned the expected magic value
    function _checkOnERC721Received(address from, address to, uint256 wizardId, bytes memory _data)
        internal returns (bool)
    {
        if (!isContract(to)) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, wizardId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /// @notice Private function to clear current approval of a given Wizard.
    /// @param wizardId ID of the Wizard to be transferred
    function _clearApproval(uint256 wizardId) private {
        if (wizardApprovals[wizardId] != address(0)) {
            wizardApprovals[wizardId] = address(0);
        }
    }
}





contract WizardGuildInterfaceId {
    bytes4 internal constant _INTERFACE_ID_WIZARDGUILD = 0x41d4d437;
}

/// @title The public interface of the Wizard Guild
/// @notice The methods listed in this interface (including the inherited ERC-721 interface),
///         make up the public interface of the Wizard Guild contract. Any contracts that wish
///         to make use of Cheeze Wizard NFTs (such as Cheeze Wizards Tournaments!) should use
///         these methods to ensure they are working correctly with the base NFTs.
contract WizardGuildInterface is IERC721, WizardGuildInterfaceId {

    /// @notice Returns the information associated with the given Wizard
    ///         owner - The address that owns this Wizard
    ///         innatePower - The innate power level of this Wizard, set when minted and entirely
    ///               immutable
    ///         affinity - The Elemental Affinity of this Wizard. For most Wizards, this is set
    ///               when they are minted, but some exclusive Wizards are minted with an affinity
    ///               of 0 (ELEMENT_NOTSET). A Wizard with an NOTSET affinity should NOT be able
    ///               to participate in Tournaments. Once the affinity of a Wizard is set to a non-zero
    ///               value, it can never be changed again.
    ///         metadata - A 256-bit hash of the Wizard's metadata, which is stored off chain. This
    ///               contract doesn't specify format of this hash, nor the off-chain storage mechanism
    ///               but, let's be honest, it's probably an IPFS SHA-256 hash.
    ///
    ///         NOTE: Series zero Wizards have one of four Affinities:  Neutral (1), Fire (2), Water (3)
    ///               or Air (4, sometimes called "Wind" in the code). Future Wizard Series may have
    ///               additional Affinities, and clients of this API should be prepared for that
    ///               eventuality.
    function getWizard(uint256 id) external view returns (address owner, uint88 innatePower, uint8 affinity, bytes32 metadata);

    /// @notice Sets the affinity for a Wizard that doesn't already have its elemental affinity chosen.
    ///         Only usable for Exclusive Wizards (all non-Exclusives must have their affinity chosen when
    ///         conjured.) Even Exclusives can't change their affinity once it's been chosen.
    ///
    ///         NOTE: This function can only be called by the series minter, and (therefore) only while the
    ///         series is open. A Wizard that has no affinity when a series is closed will NEVER have an Affinity.
    ///         BTW- This implies that a minter is responsible for either never minting ELEMENT_NOTSET
    ///         Wizards, or having some public mechanism for a Wizard owner to set the Affinity after minting.
    /// @param wizardId The id of the wizard
    /// @param newAffinity The new affinity of the wizard
    function setAffinity(uint256 wizardId, uint8 newAffinity) external;

    /// @notice A function to be called that conjures a whole bunch of Wizards at once! You know how
    ///         there's "a pride of lions", "a murder of crows", and "a parliament of owls"? Well, with this
    ///         here function you can conjure yourself "a stench of Cheeze Wizards"!
    ///
    ///         Unsurprisingly, this method can only be called by the registered minter for a Series.
    /// @param powers the power level of each wizard
    /// @param affinities the Elements of the wizards to create
    /// @param owner the address that will own the newly created Wizards
    function mintWizards(
        uint88[] calldata powers,
        uint8[] calldata affinities,
        address owner
        ) external returns (uint256[] memory wizardIds);

    /// @notice A function to be called that conjures a series of Wizards in the reserved ID range.
    /// @param wizardIds the ID values to use for each Wizard, must be in the reserved range of the current Series
    /// @param affinities the Elements of the wizards to create
    /// @param powers the power level of each wizard
    /// @param owner the address that will own the newly created Wizards
    function mintReservedWizards(
        uint256[] calldata wizardIds,
        uint88[] calldata powers,
        uint8[] calldata affinities,
        address owner
        ) external;

    /// @notice Sets the metadata values for a list of Wizards. The metadata for a Wizard can only be set once,
    ///         can only be set by the COO or Minter, and can only be set while the Series is still open. Once
    ///         a Series is closed, the metadata is locked forever!
    /// @param wizardIds the ID values of the Wizards to apply metadata changes to.
    /// @param metadata the raw metadata values for each Wizard. This contract does not define how metadata
    ///         should be interpreted, but it is likely to be a 256-bit hash of a complete metadata package
    ///         accessible via IPFS or similar.
    function setMetadata(uint256[] calldata wizardIds, bytes32[] calldata metadata) external;

    /// @notice Returns true if the given "spender" address is allowed to manipulate the given token
    ///         (either because it is the owner of that token, has been given approval to manage that token)
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);

    /// @notice Verifies that a given signature represents authority to control the given Wizard ID,
    ///         reverting otherwise. It handles three cases:
    ///             - The simplest case: The signature was signed with the private key associated with
    ///               an external address that is the owner of this Wizard.
    ///             - The signature was generated with the private key associated with an external address
    ///               that is "approved" for working with this Wizard ID. (See the Wizard Guild and/or
    ///               the ERC-721 spec for more information on "approval".)
    ///             - The owner or approval address (as in cases one or two) is a smart contract
    ///               that conforms to ERC-1654, and accepts the given signature as being valid
    ///               using its own internal logic.
    ///
    ///        NOTE: This function DOES NOT accept a signature created by an address that was given "operator
    ///               status" (as granted by ERC-721's setApprovalForAll() functionality). Doing so is
    ///               considered an extreme edge case that can be worked around where necessary.
    /// @param wizardId The Wizard ID whose control is in question
    /// @param hash The message hash we are authenticating against
    /// @param sig the signature data; can be longer than 65 bytes for ERC-1654
    function verifySignature(uint256 wizardId, bytes32 hash, bytes calldata sig) external view;

    /// @notice Convenience function that verifies signatures for two wizards using equivalent logic to
    ///         verifySignature(). Included to save on cross-contract calls in the common case where we
    ///         are verifying the signatures of two Wizards who wish to enter into a Duel.
    /// @param wizardId1 The first Wizard ID whose control is in question
    /// @param wizardId2 The second Wizard ID whose control is in question
    /// @param hash1 The message hash we are authenticating against for the first Wizard
    /// @param hash2 The message hash we are authenticating against for the first Wizard
    /// @param sig1 the signature data corresponding to the first Wizard; can be longer than 65 bytes for ERC-1654
    /// @param sig2 the signature data corresponding to the second Wizard; can be longer than 65 bytes for ERC-1654
    function verifySignatures(
        uint256 wizardId1,
        uint256 wizardId2,
        bytes32 hash1,
        bytes32 hash2,
        bytes calldata sig1,
        bytes calldata sig2) external view;
}



/// @title Contract that manages addresses and access modifiers for certain operations.
/// @author Dapper Labs Inc. (https://www.dapperlabs.com)
contract AccessControl {

    /// @dev The address of the master administrator account that has the power to
    ///      update itself and all of the other administrator addresses.
    ///      The CEO account is not expected to be used regularly, and is intended to
    ///      be stored offline (i.e. a hardware device kept in a safe).
    address public ceoAddress;

    /// @dev The address of the "day-to-day" operator of various privileged
    ///      functions inside the smart contract. Although the CEO has the power
    ///      to replace the COO, the CEO address doesn't actually have the power
    ///      to do "COO-only" operations. This is to discourage the regular use
    ///      of the CEO account.
    address public cooAddress;

    /// @dev The address that is allowed to move money around. Kept separate from
    ///      the COO because the COO address typically lives on an internet-connected
    ///      computer.
    address payable public cfoAddress;

    // Events to indicate when access control role addresses are updated.
    event CEOTransferred(address previousCeo, address newCeo);
    event COOTransferred(address previousCoo, address newCoo);
    event CFOTransferred(address previousCfo, address newCfo);

    /// @dev The AccessControl constructor sets the `ceoAddress` to the sender account. Also
    ///      initializes the COO and CFO to the passed values (CFO is optional and can be address(0)).
    /// @param newCooAddress The initial COO address to set
    /// @param newCfoAddress The initial CFO to set (optional)
    constructor(address newCooAddress, address payable newCfoAddress) public {
        _setCeo(msg.sender);
        setCoo(newCooAddress);

        if (newCfoAddress != address(0)) {
            setCfo(newCfoAddress);
        }
    }

    /// @notice Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress, "Only CEO");
        _;
    }

    /// @notice Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress, "Only COO");
        _;
    }

    /// @notice Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress, "Only CFO");
        _;
    }

    function checkControlAddress(address newController) internal view {
        require(newController != address(0) && newController != ceoAddress, "Invalid CEO address");
    }

    /// @notice Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param newCeo The address of the new CEO
    function setCeo(address newCeo) external onlyCEO {
        checkControlAddress(newCeo);
        _setCeo(newCeo);
    }

    /// @dev An internal utility function that updates the CEO variable and emits the
    ///      transfer event. Used from both the public setCeo function and the constructor.
    function _setCeo(address newCeo) private {
        emit CEOTransferred(ceoAddress, newCeo);
        ceoAddress = newCeo;
    }

    /// @notice Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param newCoo The address of the new COO
    function setCoo(address newCoo) public onlyCEO {
        checkControlAddress(newCoo);
        emit COOTransferred(cooAddress, newCoo);
        cooAddress = newCoo;
    }

    /// @notice Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param newCfo The address of the new CFO
    function setCfo(address payable newCfo) public onlyCEO {
        checkControlAddress(newCfo);
        emit CFOTransferred(cfoAddress, newCfo);
        cfoAddress = newCfo;
    }
}




/// @title Signature utility library
library SigTools {

    /// @notice Splits a signature into r & s values, and v (the verification value).
    /// @dev Note: This does not verify the version, but does require signature length = 65
    /// @param signature the packed signature to be split
    function _splitSignature(bytes memory signature) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        // Check signature length
        require(signature.length == 65, "Invalid signature length");

        // We need to unpack the signature, which is given as an array of 65 bytes (like eth.sign)
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }

        if (v < 27) {
            v += 27; // Ethereum versions are 27 or 28 as opposed to 0 or 1 which is submitted by some signing libs
        }

        // check for valid version
        // removed for now, done in another function
        //require((v == 27 || v == 28), "Invalid signature version");

        return (r, s, v);
    }
}



contract ERC1654 {

    /// @dev bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 public constant ERC1654_VALIDSIGNATURE = 0x1626ba7e;

    /// @dev Should return whether the signature provided is valid for the provided data
    /// @param hash 32-byte hash of the data that is signed
    /// @param _signature Signature byte array associated with _data
    ///  MUST return the bytes4 magic value 0x1626ba7e when function passes.
    ///  MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
    ///  MUST allow external calls
    function isValidSignature(
        bytes32 hash,
        bytes calldata _signature)
        external
        view
        returns (bytes4);
}



/// @title The master organization behind all Cheeze Wizardry. The source of all them Wiz.
contract WizardGuild is AccessControl, WizardNFT, WizardGuildInterface, ERC165Query {

    /// @notice Emitted when a new Series is opened or closed.
    event SeriesOpen(uint64 seriesIndex, uint256 reservedIds);
    event SeriesClose(uint64 seriesIndex);

    /// @notice Emitted when metadata is associated with a Wizard
    event MetadataSet(uint256 indexed wizardId, bytes32 metadata);

    /// @notice The index of the current Series (zero-based). When no Series is open, this value
    ///         indicates the index of the _upcoming_ Series. (i.e. it is incremented when the
    ///         Series is closed. This makes it easier to bootstrap the first Series.)
    uint64 internal seriesIndex;

    /// @notice The address which is allowed to mint new Wizards in the current Series. When this
    ///         is set to address(0), there is no open Series.
    address internal seriesMinter;

    /// @notice The index number of the next Wizard to be created (Neutral or Elemental).
    ///         NOTE: There is a subtle distinction between a Wizard "ID" and a Wizard "index".
    ///               We use the term "ID" to refer to a value that includes the Series number in the
    ///               top 64 bits, while the term "index" refers to the Wizard number _within_ its
    ///               Series. This is especially confusing when talking about Wizards in the first
    ///               Series (Series 0), because the two values are identical in that case!
    ///
    ///               |---------------|--------------------------|
    ///               |           Wizard ID (256 bits)           |
    ///               |---------------|--------------------------|
    ///               |  Series Index |      Wizard Index        |
    ///               |   (64 bits)   |       (192 bits)         |
    ///               |---------------|--------------------------|
    uint256 internal nextWizardIndex;

    function getNextWizardIndex() external view returns (uint256) {
        return nextWizardIndex;
    }

    // NOTE: uint256(-1) maps to a value with all bits set, both the << and >> operators will fill
    // in with zeros when acting on an unsigned value. So, "uint256(-1) << 192" resolves to "a bunch
    /// of ones, followed by 192 zeros"
    uint256 internal constant SERIES_OFFSET = 192;
    uint256 internal constant SERIES_MASK = uint256(-1) << SERIES_OFFSET;
    uint256 internal constant INDEX_MASK = uint256(-1) >> 64;

    // The ERC1654 function selector value
    bytes4 internal constant ERC1654_VALIDSIGNATURE = 0x1626ba7e;

    /// @notice The Guild constructor.
    /// @param _cooAddress The COO has the ability to create new Series and to update
    ///         the metadata on the currently open Series (if any). It has no other special
    ///         abilities, and (in particular), ALL Wizards in a closed series can never be
    ///         modified or deleted. If the CEO and COO values are ever set to invalid addresses
    ///        (such as address(1)), then no new Series can ever be created, either.
    constructor(address _cooAddress) public AccessControl(_cooAddress, address(0)) {
    }

    /// @notice Require that a Tournament Series is currently open. For example closing
    ///         a Series does not make sense if none is open.
    /// @dev While in other contracts we use separate checking functions to avoid having the same
    ///      string inlined in multiple places, given this modifier is scarcely used it doesn't seem
    ///      worth the per-call gas cost here.
    modifier duringSeries() {
        require(seriesMinter != address(0), "No series is currently open");
        _;
    }

    /// @notice Require that the caller is the minter of the current series. This implicitely
    ///         requires that a Series is open, or the minter address would be invalid (can never
    ///         be matched).
    /// @dev While in other contracts we use separate checking functions to avoid having the same
    ///      string inlined in multiple places, given this modifier is scarcely used it doesn't seem
    ///      worth the per-call gas cost here.
    modifier onlyMinter() {
        require(msg.sender == seriesMinter, "Only callable by minter");
        _;
    }

    /// @notice Open a new Series of Cheeze Wizards! Can only be called by the COO when no Series is open.
    /// @param minter The address which is allowed to mint Wizards in this series. This contract does not
    ///         assume that the minter is a smart contract, but it will presumably be in the vast majority
    ///         of the cases. A minter has absolute control over the creation of new Wizards in an open
    ///         Series, but CAN NOT manipulate a Series after it has been closed, and CAN NOT manipulate
    ///         any Wizards that don't belong to its own Series. (Even if the same minting address is used
    ///         for multiple Series, the Minter only has power over the currently open Series.)
    /// @param reservedIds The number of IDs (from 1 to reservedIds, inclusive) that are reserved for minting
    ///         reserved Wizards. (We use the term "reserved" here, instead of Exclusive, because there
    ///         are times -- such as during the importation of the Presale -- when we need to reserve a
    ///         block of IDs for Wizards that aren't what a user would think of as "exclusive". In Series
    ///         0, the reserved IDs will include all Exclusive Wizards and Presale Wizards. In other Series
    ///         it might also be the case that the set of "reserved IDs" doesn't exactly match the set of
    ///         "exclusive" IDs.)
    function openSeries(address minter, uint256 reservedIds) external onlyCOO returns (uint64 seriesId) {
        require(seriesMinter == address(0), "A series is already open");
        require(minter != address(0), "Minter address cannot be 0");

        if (seriesIndex == 0) {
            // The last wizard sold in the unpasteurized Tournament at the time the Presale contract
            // was destroyed is 6133.
            //
            // The unpasteurized Tournament contract is the Tournament contract that doesn't have the
            // "Same Wizard" check in the resolveTimedOutDuel function.

            // The wizards, which were minted in the unpasteurized Tournament before the Presale contract
            // was destroyed, will be minted again in the new Tournament contract with their ID reserved.
            //
            // So the reason the reservedIds is hardcoded here is to ensure:
            // 1) The next Wizard minted will have its ID continued from this above wizard ID.
            // 2) The Presale wizards and some wizards minted in the unpasteurized Tournament contract,
            //    can be minted in this contract with their ID reserved.
            require(reservedIds == 6133, "Invalid reservedIds for 1st series");
        } else {
            require(reservedIds < 1 << 192, "Invalid reservedIds");
        }

        // NOTE: The seriesIndex is updated when the Series is _closed_, not when it's opened.
        //  (The first Series is Series #0.) So in this function, we just leave the seriesIndex alone.

        seriesMinter = minter;
        nextWizardIndex = reservedIds + 1;

        emit SeriesOpen(seriesIndex, reservedIds);

        return seriesIndex;
    }

    /// @notice Closes the current Wizard Series. Once a Series has been closed, it is forever sealed and
    ///         no more Wizards in that Series can ever be minted! Can only be called by the COO when a Series
    ///         is open.
    ///
    ///    NOTE: A series can be closed by the COO or the Minter. (It's assumed that some minters will
    ///          know when they are done, and others will need to be shut off manually by the COO.)
    function closeSeries() external duringSeries {
        require(
            msg.sender == seriesMinter || msg.sender == cooAddress,
            "Only Minter or COO can close a Series");

        seriesMinter = address(0);
        emit SeriesClose(seriesIndex);

        // Set up the next series.
        seriesIndex += 1;
        nextWizardIndex = 0;
    }

    /// @notice ERC-165 Query Function.
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == _INTERFACE_ID_WIZARDGUILD || super.supportsInterface(interfaceId);
    }

    /// @notice Returns the information associated with the given Wizard
    ///         owner - The address that owns this Wizard
    ///         innatePower - The innate power level of this Wizard, set when minted and entirely
    ///               immutable
    ///         affinity - The Elemental Affinity of this Wizard. For most Wizards, this is set
    ///               when they are minted, but some exclusive Wizards are minted with an affinity
    ///               of 0 (ELEMENT_NOTSET). A Wizard with an NOTSET affinity should NOT be able
    ///               to participate in Tournaments. Once the affinity of a Wizard is set to a non-zero
    ///               value, it can never be changed again.
    ///         metadata - A 256-bit hash of the Wizard's metadata, which is stored off chain. This
    ///               contract doesn't specify format of this hash, nor the off-chain storage mechanism
    ///               but, let's be honest, it's probably an IPFS SHA-256 hash.
    ///
    ///         NOTE: Series zero Wizards have one of four Affinities:  Neutral (1), Fire (2), Water (3)
    ///               or Air (4, sometimes called "Wind" in the code). Future Wizard Series may have
    ///               additional Affinities, and clients of this API should be prepared for that
    ///               eventuality.
    function getWizard(uint256 id) public view returns (address owner, uint88 innatePower, uint8 affinity, bytes32 metadata) {
        Wizard memory wizard = wizardsById[id];
        require(wizard.owner != address(0), "Wizard does not exist");
        (owner, innatePower, affinity, metadata) = (wizard.owner, wizard.innatePower, wizard.affinity, wizard.metadata);
    }

    /// @notice A function to be called that conjures a whole bunch of Wizards at once! You know how
    ///         there's "a pride of lions", "a murder of crows", and "a parliament of owls"? Well, with this
    ///         here function you can conjure yourself "a stench of Cheeze Wizards"!
    ///
    ///         Unsurprisingly, this method can only be called by the registered minter for a Series.
    /// @dev This function DOES NOT CALL onERC721Received() as required by the ERC-721 standard. It is
    ///         REQUIRED that the Minter calls onERC721Received() after calling this function. The following
    ///         code snippet should suffice:
    ///                 // Ensure the Wizard is being assigned to an ERC-721 aware address (either an external address,
    ///                 // or a smart contract that implements onERC721Received()). We must call onERC721Received for
    ///                 // each token created because it's allowed for an ERC-721 receiving contract to reject the
    ///                 // transfer based on the properties of the token.
    ///                 if (isContract(owner)) {
    ///                     for (uint256 i = 0; i < wizardIds.length; i++) {
    ///                         bytes4 retval = IERC721Receiver(owner).onERC721Received(owner, address(0), wizardIds[i], "");
    ///                         require(retval == _ERC721_RECEIVED, "Contract owner didn't accept ERC721 transfer");
    ///                     }
    ///                 }
    ///        Although it would be convenient for mintWizards to call onERC721Received, it opens us up to potential
    ///        reentrancy attacks if the Minter needs to do more state updates after mintWizards() returns.
    /// @param powers the power level of each wizard
    /// @param affinities the Elements of the wizards to create
    /// @param owner the address that will own the newly created Wizards
    function mintWizards(
        uint88[] calldata powers,
        uint8[] calldata affinities,
        address owner
    ) external onlyMinter returns (uint256[] memory wizardIds)
    {
        require(affinities.length == powers.length, "Inconsistent parameter lengths");

        // allocate result array
        wizardIds = new uint256[](affinities.length);

        // We take this storage variables, and turn it into a local variable for the course
        // of this loop to save about 5k gas per wizard.
        uint256 tempWizardId = (uint256(seriesIndex) << SERIES_OFFSET) + nextWizardIndex;

        for (uint256 i = 0; i < affinities.length; i++) {
            wizardIds[i] = tempWizardId;
            tempWizardId++;

            _createWizard(wizardIds[i], owner, powers[i], affinities[i]);
        }

        nextWizardIndex = tempWizardId & INDEX_MASK;
    }

    /// @notice A function to be called that mints a Series of Wizards in the reserved ID range, can only
    ///         be called by the Minter for this Series.
    /// @dev This function DOES NOT CALL onERC721Received() as required by the ERC-721 standard. It is
    ///         REQUIRED that the Minter calls onERC721Received() after calling this function. See the note
    ///         above on mintWizards() for more info.
    /// @param wizardIds the ID values to use for each Wizard, must be in the reserved range of the current Series.
    /// @param powers the power level of each Wizard.
    /// @param affinities the Elements of the Wizards to create.
    /// @param owner the address that will own the newly created Wizards.
    function mintReservedWizards(
        uint256[] calldata wizardIds,
        uint88[] calldata powers,
        uint8[] calldata affinities,
        address owner
    )
    external onlyMinter
    {
        require(
            wizardIds.length == affinities.length &&
            wizardIds.length == powers.length, "Inconsistent parameter lengths");

        for (uint256 i = 0; i < wizardIds.length; i++) {
            uint256 currentId = wizardIds[i];

            require((currentId & SERIES_MASK) == (uint256(seriesIndex) << SERIES_OFFSET), "Wizards not in current series");
            require((currentId & INDEX_MASK) > 0, "Wizards id cannot be zero");

            // Ideally, we would compare the requested Wizard index against the reserved range directly. However,
            // it's a bit wasteful to spend storage on a reserved range variable when we can combine some known
            // true facts instead:
            //         - nextWizardIndex is initialized to reservedRange + 1 when the Series was opened
            //         - nextWizardIndex is only incremented when a new Wizard is created
            //         - therefore, the only empty Wizard IDs less than nextWizardIndex are in the reserved range.
            //         - _conjureWizard() will abort if we try to reuse an ID.
            // Combining all of the above, we know that, if the requested index is less than the next index, it
            // either points to a reserved slot or an occupied slot. Trying to reuse an occupied slot will fail,
            // so just checking against nextWizardIndex is sufficient to ensure we're pointing at a reserved slot.
            require((currentId & INDEX_MASK) < nextWizardIndex, "Wizards not in reserved range");

            _createWizard(currentId, owner, powers[i], affinities[i]);
        }
    }

    /// @notice Sets the metadata values for a list of Wizards. The metadata for a Wizard can only be set once,
    ///         can only be set by the COO or Minter, and can only be set while the Series is still open. Once
    ///         a Series is closed, the metadata is locked forever!
    /// @param wizardIds the ID values of the Wizards to apply metadata changes to.
    /// @param metadata the raw metadata values for each Wizard. This contract does not define how metadata
    ///         should be interpreted, but it is likely to be a 256-bit hash of a complete metadata package
    ///         accessible via IPFS or similar.
    function setMetadata(uint256[] calldata wizardIds, bytes32[] calldata metadata) external duringSeries {
        require(msg.sender == seriesMinter || msg.sender == cooAddress, "Only Minter or COO can set metadata");
        require(wizardIds.length == metadata.length, "Inconsistent parameter lengths");

        for (uint256 i = 0; i < wizardIds.length; i++) {
            uint256 currentId = wizardIds[i];
            bytes32 currentMetadata = metadata[i];

            require((currentId & SERIES_MASK) == (uint256(seriesIndex) << SERIES_OFFSET), "Wizards not in current series");

            require(wizardsById[currentId].metadata == bytes32(0), "Metadata already set");

            require(currentMetadata != bytes32(0), "Invalid metadata");

            wizardsById[currentId].metadata = currentMetadata;

            emit MetadataSet(currentId, currentMetadata);
        }
    }

    /// @notice Sets the affinity for a Wizard that doesn't already have its elemental affinity chosen.
    ///         Only usable for Exclusive Wizards (all non-Exclusives must have their affinity chosen when
    ///         conjured.) Even Exclusives can't change their affinity once it's been chosen.
    ///
    ///         NOTE: This function can only be called by the Series minter, and (therefore) only while the
    ///         Series is open. A Wizard that has no affinity when a Series is closed will NEVER have an Affinity.
    /// @param wizardId The ID of the Wizard to update affinity of.
    /// @param newAffinity The new affinity of the Wizard.
    function setAffinity(uint256 wizardId, uint8 newAffinity) external onlyMinter {
        require((wizardId & SERIES_MASK) == (uint256(seriesIndex) << SERIES_OFFSET), "Wizard not in current series");

        Wizard storage wizard = wizardsById[wizardId];

        require(wizard.affinity == ELEMENT_NOTSET, "Affinity can only be chosen once");

        // set the affinity
        wizard.affinity = newAffinity;

        // Tell the world this wizards now has an affinity!
        emit WizardAffinityAssigned(wizardId, newAffinity);
    }

    /// @notice Returns true if the given "spender" address is allowed to manipulate the given token
    ///         (either because it is the owner of that token, has been given approval to manage that token)
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool) {
        return _isApprovedOrOwner(spender, tokenId);
    }

    /// @notice Verifies that a given signature represents authority to control the given Wizard ID,
    ///         reverting otherwise. It handles three cases:
    ///             - The simplest case: The signature was signed with the private key associated with
    ///               an external address that is the owner of this Wizard.
    ///             - The signature was generated with the private key associated with an external address
    ///               that is "approved" for working with this Wizard ID. (See the Wizard Guild and/or
    ///               the ERC-721 spec for more information on "approval".)
    ///             - The owner or approval address (as in cases one or two) is a smart contract
    ///               that conforms to ERC-1654, and accepts the given signature as being valid
    ///               using its own internal logic.
    ///
    ///        NOTE: This function DOES NOT accept a signature created by an address that was given "operator
    ///               status" (as granted by ERC-721's setApprovalForAll() functionality). Doing so is
    ///               considered an extreme edge case that can be worked around where necessary.
    /// @param wizardId The Wizard ID whose control is in question
    /// @param hash The message hash we are authenticating against
    /// @param sig the signature data; can be longer than 65 bytes for ERC-1654
    function verifySignature(uint256 wizardId, bytes32 hash, bytes memory sig) public view {
        // First see if the signature belongs to the owner (the most common case)
        address owner = ownerOf(wizardId);

        if (_validSignatureForAddress(owner, hash, sig)) {
            return;
        }

        // Next check if the signature belongs to the approved address
        address approved = getApproved(wizardId);

        if (_validSignatureForAddress(approved, hash, sig)) {
            return;
        }

        revert("Invalid signature");
    }

    /// @notice Convenience function that verifies signatures for two wizards using equivalent logic to
    ///         verifySignature(). Included to save on cross-contract calls in the common case where we
    ///         are verifying the signatures of two Wizards who wish to enter into a Duel.
    /// @param wizardId1 The first Wizard ID whose control is in question
    /// @param wizardId2 The second Wizard ID whose control is in question
    /// @param hash1 The message hash we are authenticating against for the first Wizard
    /// @param hash2 The message hash we are authenticating against for the first Wizard
    /// @param sig1 the signature data corresponding to the first Wizard; can be longer than 65 bytes for ERC-1654
    /// @param sig2 the signature data corresponding to the second Wizard; can be longer than 65 bytes for ERC-1654
    function verifySignatures(
        uint256 wizardId1,
        uint256 wizardId2,
        bytes32 hash1,
        bytes32 hash2,
        bytes calldata sig1,
        bytes calldata sig2) external view
    {
        verifySignature(wizardId1, hash1, sig1);
        verifySignature(wizardId2, hash2, sig2);
    }

    /// @notice An internal function that checks if a given signature is a valid signature for a
    ///         specific address on a particular hash value. Checks for ERC-1654 compatibility
    ///         first (where the possibleSigner is a smart contract that implements its own
    ///         signature validation), and falls back to ecrecover() otherwise.
    function _validSignatureForAddress(address possibleSigner, bytes32 hash, bytes memory signature)
        internal view returns(bool)
    {
        if (possibleSigner == address(0)) {
            // The most basic Bozo check: The zero address can never be a valid signer!
            return false;
        } else if (Address.isContract(possibleSigner)) {
            // If the address is a contract, it either implements ERC-1654 (and will validate the signature
            // itself), or we have no way of confirming that this signature matches this address. In other words,
            // if this address is a contract, there's no point in "falling back" to ecrecover().
            if (doesContractImplementInterface(possibleSigner, ERC1654_VALIDSIGNATURE)) {
                // cast to ERC1654
                ERC1654 tso = ERC1654(possibleSigner);
                bytes4 result = tso.isValidSignature(keccak256(abi.encodePacked(hash)), signature);
                if (result == ERC1654_VALIDSIGNATURE) {
                    return true;
                }
            }

            return false;
        } else {
            // Not a contract, check for a match against an external address
            // assume EIP 191 signature here
            (bytes32 r, bytes32 s, uint8 v) = SigTools._splitSignature(signature);
            address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s);

            // Note: Signer could be address(0) here, but we already checked that possibleSigner isn't zero
            return (signer == possibleSigner);
        }
    }

}
// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "limit-break-contracts/contracts/initializable/IAdventureERC721Initializer.sol";
import "limit-break-contracts/contracts/initializable/IERC721Initializer.sol";
import "limit-break-contracts/contracts/initializable/IMaxSupplyInitializer.sol";
import "limit-break-contracts/contracts/initializable/IOwnableInitializer.sol";
import "limit-break-contracts/contracts/initializable/IRoyaltiesInitializer.sol";
import "limit-break-contracts/contracts/initializable/IURIInitializer.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

error CallerDoesNotHaveAdminRole(address caller);
error CallerDoesNotHaveKeyMakerRole(address caller);
error ReferenceContractIsNotAnAdventureERC721Initializer();
error ReferenceContractIsNotAnERC721Initializer();

/**
 * @title AdventureKeyMaker
 * @author Limit Break, Inc.
 * @notice Allows approved key makers to create new Adventure Keys.
 * See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
contract AdventureKeyMaker is AccessControlEnumerable {

    struct Settings {
        uint256 maxSimultaneousQuests;
        uint256 maxSupply;
        address royaltyReceiver;
        uint96 royaltyFeeNumerator;
        string name;
        string symbol;
        string baseURI;
        string suffixURI;
    }

    /// @dev Value defining the `Key Maker Role`.
    bytes32 public constant KEY_MAKER_ROLE = keccak256("KEY_MAKER_ROLE");

    /// @dev Emitted when a new Adventure ERC721 token has been cloned.
    event AdventureKeyMade(address key);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Allows the current contract admin to transfer the `Admin Role` to a new address.
    /// Throws if the caller is not the current admin.
    ///
    /// Postconditions:
    /// The new admin has been granted the `Admin Role`.
    /// The caller/former admin has had `Admin Role` revoked.
    function transferAdminRole(address newAdmin) external {
        if(!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert CallerDoesNotHaveAdminRole(_msgSender());
        }

        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Makes a new Adventure Key
    /// Throws when the caller has not been granted the `Key Maker Role`.
    /// Throws when the specified reference contract does not implement the {IERC721Initializer} interface.
    /// Throws when the specified reference contract does not implement the {IAdventureERC721Initializer} interface.
    ///
    /// Postconditions:
    /// A new Adventure ERC721 token has been cloned and initialized.
    /// The new Adventure ERC721 token contract is owned by the specified `contractOwner` value.
    /// An `AdventureERC721Cloned` event has been emitted.
    function makeAdventureKey(
        address referenceContract, 
        address contractOwner,
        Settings calldata settings) 
        external returns (address) {
        if(!hasRole(KEY_MAKER_ROLE, _msgSender())) {
            revert CallerDoesNotHaveKeyMakerRole(_msgSender());
        }

        IERC165 referenceContractIntrospection = IERC165(referenceContract);

        if(!referenceContractIntrospection.supportsInterface(type(IERC721Initializer).interfaceId)) {
            revert ReferenceContractIsNotAnERC721Initializer();
        }

        if(!referenceContractIntrospection.supportsInterface(type(IAdventureERC721Initializer).interfaceId)) {
            revert ReferenceContractIsNotAnAdventureERC721Initializer();
        }

        address key = Clones.clone(referenceContract);

        emit AdventureKeyMade(key);

        IOwnableInitializer(key).initializeOwner(address(this));
        IERC721Initializer(key).initializeERC721(settings.name, settings.symbol);
        IAdventureERC721Initializer(key).initializeAdventureERC721(settings.maxSimultaneousQuests);

        if(referenceContractIntrospection.supportsInterface(type(IMaxSupplyInitializer).interfaceId)) {
            IMaxSupplyInitializer(key).initializeMaxSupply(settings.maxSupply);
        }

        if(referenceContractIntrospection.supportsInterface(type(IRoyaltiesInitializer).interfaceId)) {
            IRoyaltiesInitializer(key).initializeRoyalties(settings.royaltyReceiver, settings.royaltyFeeNumerator);
        }

        if(referenceContractIntrospection.supportsInterface(type(IURIInitializer).interfaceId)) {
            IURIInitializer(key).initializeURI(settings.baseURI, settings.suffixURI);
        }
        
        IOwnableInitializer(key).transferOwnership(contractOwner);

        return key;
    }
}
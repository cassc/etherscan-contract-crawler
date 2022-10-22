// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IAchievements.sol";
import "limit-break-contracts/contracts/token/ERC1155/SoulboundERC1155.sol";
import "limit-break-contracts/contracts/token/ERC1155/formatters/InitializableReadOnlyURIFormatter.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

error CallerDidNotReserveTheAchievementId(address caller, uint256 achievementId);
error CallerDoesNotHaveAdminRole(address caller);
error CallerDoesNotHaveMinterRole(address caller);
error CallerDidNotReserveTheAchievementIdAndIsNotAnAdmin(address caller, uint256 achievementId);
error CannotSetMetadataURIFormatterForUnreservedAchievementId();
error CannotTransferAdminRoleToSelf();
error CannotTransferAdminRoleToZeroAddress();
error IdHasNotBeenReserved();
error InputArraySizeCannotBeZero();
error MintingIdZeroIsNotAllowed();
error RevokingMinterRoleIsNotPermitted();

/**
 * @title Achievements
 * @author Limit Break, Inc.
 * @notice Soulbound ERC-1155 Multi-Token To Track Player Achievements
 */
contract Achievements is SoulboundERC1155, AccessControlEnumerable, IAchievements {
    
    /// @dev Value defining the `Minter Role`.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev The reference implementation for default URI formatters created when reserving achievement ids
    address immutable public defaultURIFormatterReference;

    /// @dev The achievement id that was most recently reserved
    uint256 public lastAchievementId;

    /// @dev Maps an achievement id to the address of the minter that created the reservation
    mapping (uint256 => address) public achievementIdReservations;

    /// @dev Mapping from token ID to a URI formatter contract
    mapping (uint256 => IERC1155MetadataURIFormatter) public uriFormatters;

    /// @dev Emitted when a new achievement id is reserved.
    event ReserveAchievementId(address indexed minter, uint256 indexed achievementId);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        // Creates a reference implementation for URI formatters created when reserving achievement ids
        defaultURIFormatterReference = address(new InitializableReadOnlyURIFormatter());
    }

    /// @notice Allows the current contract admin to transfer the `Admin Role` to a new address.
    /// Throws if newAdmin is the zero-address
    /// Throws if the caller is not the current admin.
    /// Throws if the caller is an admin and tries to transfer admin to itself.
    ///
    /// Postconditions:
    /// The new admin has been granted the `Admin Role`.
    /// The caller/former admin has had `Admin Role` revoked.
    function transferAdminRole(address newAdmin) external {
        if(newAdmin == address(0)) {
            revert CannotTransferAdminRoleToZeroAddress();
        }

        if(newAdmin == _msgSender()) {
            revert CannotTransferAdminRoleToSelf();
        }

        if(!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert CallerDoesNotHaveAdminRole(_msgSender());
        }

        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
    }

    /// @notice Sets the metadata URI formatter for the specified token type id
    /// Throws if id equals 0.
    /// Throws if id has not yet been reserved.
    /// Throws when called by account that is not the contract owner or the account that reserved the id.
    /// Throws when the specified URI formatter does not implement the {IERC1155MetadataURIFormatter} interface.
    /// Throws if the specified URI formatter throws when generating a URI.
    ///
    /// Postconditions:
    /// The URI formatter has been linked to the token type id.
    /// A URI event has been emitted with the new URI of the token type id.
    function setMetadataURIFormatter(uint256 id, address uriFormatterAddress) external {
        if(id == 0 || id > lastAchievementId) {
            revert CannotSetMetadataURIFormatterForUnreservedAchievementId();
        }

        if(achievementIdReservations[id] != _msgSender() && !hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert CallerDidNotReserveTheAchievementIdAndIsNotAnAdmin(_msgSender(), id);
        }

        if(!IERC165(uriFormatterAddress).supportsInterface(type(IERC1155MetadataURIFormatter).interfaceId)) {
            revert InvalidMetadataFormatterContract();
        }

        IERC1155MetadataURIFormatter uriFormatter = IERC1155MetadataURIFormatter(uriFormatterAddress);
        uriFormatters[id] = uriFormatter;

        emit URI(uriFormatter.uri(), id);
    }

    /// @notice Reserves an achievement id and associates the achievement id with a single allowed minter.
    /// Initializes the URI formatter for the reserved token id using a simple, inexpensive InitializableReadOnlyURIFormatter created via cloning.
    /// Throws if caller has not been granted MINTER_ROLE permissions.
    function reserveAchievementId(string calldata metadataURI) external returns (uint256) {
        _requireCallerHasMinterRole();

        uint256 reservedAchievementId = ++lastAchievementId;
        achievementIdReservations[reservedAchievementId] = _msgSender();

        emit ReserveAchievementId(_msgSender(), reservedAchievementId);

        InitializableReadOnlyURIFormatter formatter = InitializableReadOnlyURIFormatter(Clones.clone(defaultURIFormatterReference));
        formatter.initializeURI(metadataURI);

        uriFormatters[reservedAchievementId] = formatter;
        emit URI(formatter.uri(), reservedAchievementId);

        return reservedAchievementId;
    }

    /// @notice Mints an achievement of type `id` to the `to` address.
    /// Throws if the caller did not reserve the specified achievement `id`
    /// Throws if the specified achievement `id` has not been reserved
    /// Throws if attempting to mint to the zero address.
    function mint(address to, uint256 id, uint256 amount) external {
        _requireCallerReservedAchievementId(id);
        _mint(to, id, amount);
    }

    /// @notice Batch mints achievements to the `to` address.
    /// Throws if the caller did not reserve the specified achievement `id`
    /// Throws if the specified achievement `id` has not been reserved
    /// Throws if attempting to mint to the zero address.
    /// Throws if the ids and amounts arrays don't have the same size.
    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts) external {
        if(ids.length == 0 || amounts.length == 0) {
            revert InputArraySizeCannotBeZero();
        }

        unchecked {
            for (uint256 i = 0; i < ids.length; ++i) {
                _requireCallerReservedAchievementId(ids[i]);
            }
        }

        _mintBatch(to, ids, amounts);
    }

    /// @notice Returns a distinct URI for a given token type id, generated by an external URI formatter contract
    /// Throws when no URI Formatter has been specified
    function uri(uint256 id) public view virtual override(SoulboundERC1155, IERC1155MetadataURI) returns (string memory) {
        IERC1155MetadataURIFormatter uriFormatter = uriFormatters[id];
        if(address(uriFormatter) == address(0)) {
            revert NoMetadataFormatterFoundForSpecifiedId();
        }

        return uriFormatter.uri();
    }

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override(SoulboundERC1155, AccessControlEnumerable, IERC165) returns (bool) {
        return
        interfaceId == type(IAchievements).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /// @dev Validates the the caller has MINTER_ROLE
    function _requireCallerHasMinterRole() internal view {
        if(!hasRole(MINTER_ROLE, _msgSender())) {
            revert CallerDoesNotHaveMinterRole(_msgSender());
        }
    }

    /// @dev Validates the the caller was the same account that reserved the achievement id
    function _requireCallerReservedAchievementId(uint256 id) internal view {
        if(achievementIdReservations[id] != _msgSender()) {
            revert CallerDidNotReserveTheAchievementId(_msgSender(), id);
        }
    }
}
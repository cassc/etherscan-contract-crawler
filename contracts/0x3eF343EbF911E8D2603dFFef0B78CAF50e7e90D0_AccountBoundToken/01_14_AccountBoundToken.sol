// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IAccountBoundToken} from "../interfaces/IAccountBoundToken.sol";

/// @title AccountBoundToken
/// @author Clique
/// @custom:coauthor Ollie (eillo.eth)
/// @custom:coauthor Depetrol
contract AccountBoundToken is
    IAccountBoundToken,
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable
{
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ROLE CONSTANTS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    mapping(address => mapping(uint256 => string)) public _credentialURL; // account => id => credentialURL

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Restricts function callers to ABT holder or admin.
    /// @param account The account of the function caller.
    /// @param id The id of the ABT.
    modifier onlyHolderOrOwner(address account, uint256 id) {
        // function caller must be the account and an ABT owner, or admin.
        if (
            (msg.sender != account || ownerOf(msg.sender, id) == false) &&
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) == false
        ) {
            revert AccessRestricted(msg.sender);
        }
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 CONSTRUCTOR & INITIALIZER                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initialize function, to be called by the proxy delegating calls to this implementation.
    /// @notice Initializes the ABT, AccessControl and sets the roles to the deployer.
    function initialize() public initializer {
        __ERC1155_init("");
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ISSUER_ROLE, msg.sender);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    EXTERNAL FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Sets the URI, following ERC1155 standard.
    /// @param uri The URI to be set.
    function setURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(uri);
    }

    /// @inheritdoc IAccountBoundToken
    function issue(
        address account,
        uint256 id,
        string memory credentialURL
    ) external override onlyRole(ISSUER_ROLE) {
        if (ownerOf(account, id)) revert AlreadyIssued(account, id);
        _credentialURL[account][id] = credentialURL;
        _mint(account, id, 1, "");
        emit UpdateCredential(account, id, credentialURL);
    }

    /// @inheritdoc IAccountBoundToken
    function update(
        address account,
        uint256 id,
        string memory credentialURL
    ) external override onlyRole(ISSUER_ROLE) {
        if (_isRevoked(account, id)) revert Revoked(account, id);
        _credentialURL[account][id] = credentialURL;
        emit UpdateCredential(account, id, credentialURL);
    }

    /// @inheritdoc IAccountBoundToken
    function burn(
        address account,
        uint256 id
    ) external override onlyHolderOrOwner(account, id) {
        if (_isRevoked(account, id)) revert Revoked(account, id);
        _credentialURL[account][id] = "Revoked";
        _burn(account, id, 1);
        emit UpdateCredential(account, id, _credentialURL[account][id]);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     PUBLIC FUNCTIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @inheritdoc IAccountBoundToken
    function ownerOf(
        address account,
        uint256 tokenId
    ) public view override returns (bool) {
        return balanceOf(account, tokenId) != 0;
    }

    // @notice ABT is non-transferable
    function setApprovalForAll(
        address operator,
        bool approved
    ) public view virtual override {
        revert AccountBound();
    }

    // @notice ABT is non-transferable
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual override returns (bool) {
        revert AccountBound();
    }

    /// @inheritdoc ERC1155Upgradeable
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice checks if an ABT with the given account and id is revoked.
    /// @param account The account of the ABT owner.
    /// @param id The id of the ABT.
    function _isRevoked(
        address account,
        uint256 id
    ) internal view returns (bool) {
        bytes32 credentialHash = keccak256(
            abi.encode(_credentialURL[account][id])
        );
        bytes32 revokedHash = keccak256(abi.encode("Revoked"));
        return credentialHash == revokedHash;
    }

    // @notice ABT is non-transferable
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        if (!(from == address(0) || to == address(0))) revert AccountBound();
    }

    /// @notice Emits Attest event when a token is minted and Revoke when it
    ///         is burned.
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        if (from == address(0)) {
            emit Attest(to, ids[0]);
        }
        if (to == address(0)) {
            emit Revoke(address(0), ids[0]);
        }
    }
}
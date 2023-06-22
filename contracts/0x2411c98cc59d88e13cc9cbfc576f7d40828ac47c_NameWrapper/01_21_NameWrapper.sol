//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import {ERC1155Fuse, IERC165, OperationProhibited} from "./ERC1155Fuse.sol";
import {Controllable} from "./Controllable.sol";
import {INameWrapper, CANNOT_UNWRAP, CANNOT_BURN_FUSES, CANNOT_TRANSFER, CANNOT_SET_RESOLVER, CANNOT_SET_TTL, PARENT_CANNOT_CONTROL} from "./INameWrapper.sol";
import {INameWrapperUpgrade} from "./INameWrapperUpgrade.sol";
import {IMetadataService} from "./IMetadataService.sol";
import {BDNS} from "../registry/BDNS.sol";
import {IBaseRegistrar} from "../ethregistrar/IBaseRegistrar.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BytesUtils} from "./BytesUtils.sol";
import {ERC20Recoverable} from "../utils/ERC20Recoverable.sol";

error Unauthorised(bytes32 node, address addr);
error IncorrectTokenType();
error LabelMismatch(bytes32 labelHash, bytes32 expectedLabelhash);
error LabelTooShort();
error LabelTooLong(string label);
error IncorrectTargetOwner(address owner);
error CannotUpgrade();

contract NameWrapper is
    Ownable,
    ERC1155Fuse,
    INameWrapper,
    Controllable,
    IERC721Receiver,
    ERC20Recoverable
{
    using BytesUtils for bytes;
    BDNS public immutable override bdns;
    IBaseRegistrar public immutable override registrar;
    IMetadataService public override metadataService;
    mapping(bytes32 => bytes) public override names;
    string public constant name = "NameWrapper";

    bytes32 private constant ROOT_NODE = 0;

    INameWrapperUpgrade public upgradeContract;
    uint64 private constant MAX_EXPIRY = type(uint64).max;

    constructor(
        BDNS _bdns,
        IBaseRegistrar _registrar,
        IMetadataService _metadataService
    ) {
        bdns = _bdns;
        registrar = _registrar;
        metadataService = _metadataService;

        /* Burn PARENT_CANNOT_CONTROL and CANNOT_UNWRAP fuses for ROOT_NODE */
        _setData(
            uint256(ROOT_NODE),
            address(0),
            uint32(PARENT_CANNOT_CONTROL | CANNOT_UNWRAP),
            MAX_EXPIRY
        );
        names[ROOT_NODE] = "\x00";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Fuse, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(INameWrapper).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /* ERC1155 Fuse */

    /**
     * @notice Gets the owner of a name
     * @param id Label as a string of the root domain to wrap
     * @return owner The owner of the name
     */

    function ownerOf(uint256 id)
        public
        view
        override(ERC1155Fuse, INameWrapper)
        returns (address owner)
    {
        return super.ownerOf(id);
    }

    /**
     * @notice Gets the data for a name
     * @param id Label as a string of the root domain to wrap
     * @return address The owner of the name
     * @return uint32 Fuses of the name
     * @return uint64 Expiry of when the fuses expire for the name
     */

    function getData(uint256 id)
        public
        view
        override(ERC1155Fuse, INameWrapper)
        returns (
            address,
            uint32,
            uint64
        )
    {
        return super.getData(id);
    }

    /* Metadata service */

    /**
     * @notice Set the metadata service. Only the owner can do this
     * @param _metadataService The new metadata service
     */

    function setMetadataService(IMetadataService _metadataService)
        public
        onlyOwner
    {
        metadataService = _metadataService;
    }

    /**
     * @notice Get the metadata uri
     * @param tokenId The id of the token
     * @return string uri of the metadata service
     */

    function uri(uint256 tokenId) public view override returns (string memory) {
        return metadataService.uri(tokenId);
    }

    /**
     * @notice Set the address of the upgradeContract of the contract. only admin can do this
     * @dev The default value of upgradeContract is the 0 address. Use the 0 address at any time
     * to make the contract not upgradable.
     * @param _upgradeAddress address of an upgraded contract
     */

    function setUpgradeContract(INameWrapperUpgrade _upgradeAddress)
        public
        onlyOwner
    {
        if (address(upgradeContract) != address(0)) {
            registrar.setApprovalForAll(address(upgradeContract), false);
            bdns.setApprovalForAll(address(upgradeContract), false);
        }

        upgradeContract = _upgradeAddress;

        if (address(upgradeContract) != address(0)) {
            registrar.setApprovalForAll(address(upgradeContract), true);
            bdns.setApprovalForAll(address(upgradeContract), true);
        }
    }

    /**
     * @notice Checks if msg.sender is the owner or approved by the owner of a name
     * @param node namehash of the name to check
     */

    modifier onlyTokenOwner(bytes32 node) {
        if (!isTokenOwnerOrApproved(node, msg.sender)) {
            revert Unauthorised(node, msg.sender);
        }

        _;
    }

    /**
     * @notice Checks if owner or approved by owner
     * @param node namehash of the name to check
     * @param addr which address to check permissions for
     * @return whether or not is owner or approved
     */

    function isTokenOwnerOrApproved(bytes32 node, address addr)
        public
        view
        override
        returns (bool)
    {
        address owner = ownerOf(uint256(node));
        return owner == addr || isApprovedForAll(owner, addr);
    }

    /**
     * @notice Wraps a root domain, creating a new token and sending the original ERC721 token to this contract
     * @dev Can be called by the owner of the name on the root registrar or an authorised caller on the registrar
     * @param label Label as a string of the root domain to wrap
     * @param wrappedOwner Owner of the name in this contract
     * @param fuses Initial fuses to set
     * @param expiry When the fuses will expire
     * @param resolver Resolver contract address
     * @return Normalised expiry of when the fuses expire
     */

    function wrap(
        string calldata label,
        address wrappedOwner,
        uint32 fuses,
        uint64 expiry,
        address resolver
    ) public override returns (uint64) {
        uint256 tokenId = uint256(keccak256(bytes(label)));
        address registrant = registrar.ownerOf(tokenId);
        if (
            registrant != msg.sender &&
            !registrar.isApprovedForAll(registrant, msg.sender)
        ) {
            revert Unauthorised(
                _makeNode(ROOT_NODE, bytes32(tokenId)),
                msg.sender
            );
        }

        // transfer the token from the user to this contract
        registrar.transferFrom(registrant, address(this), tokenId);

        // transfer the BDNS record back to the new owner (this contract)
        registrar.reclaim(tokenId, address(this));

        return _wrapROOT(label, wrappedOwner, fuses, expiry, resolver);
    }

    /**
     * @dev Registers a new root second-level domain and wraps it.
     *      Only callable by authorised controllers.
     * @param label The label to register (Eg, 'foo' for 'foo').
     * @param wrappedOwner The owner of the wrapped name.
     * @param duration The duration, in seconds, to register the name for.
     * @param resolver The resolver address to set on the BDNS registry (optional).
     * @param fuses Initial fuses to set
     * @param expiry When the fuses will expire
     * @return registrarExpiry The expiry date of the new name on the root registrar, in seconds since the Unix epoch.
     */

    function registerAndWrap(
        string calldata label,
        address wrappedOwner,
        uint256 duration,
        address resolver,
        uint32 fuses,
        uint64 expiry
    ) external override onlyController returns (uint256 registrarExpiry) {
        uint256 tokenId = uint256(keccak256(bytes(label)));
        registrarExpiry = registrar.register(tokenId, address(this), duration);
        _wrapROOT(label, wrappedOwner, fuses, expiry, resolver);
    }

    /**
     * @notice Renews a root second-level domain.
     * @dev Only callable by authorised controllers.
     * @param tokenId The hash of the label to register (eg, `keccak256('foo')`, for 'foo').
     * @param duration The number of seconds to renew the name for.
     * @return expires The expiry date of the name on the root registrar, in seconds since the Unix epoch.
     */

    function renew(
        uint256 tokenId,
        uint256 duration,
        uint32 fuses,
        uint64 expiry
    ) external override onlyController returns (uint256 expires) {
        bytes32 node = _makeNode(ROOT_NODE, bytes32(tokenId));

        expires = registrar.renew(tokenId, duration);
        if (isWrapped(node)) {
            (address owner, uint32 oldFuses, uint64 oldExpiry) = getData(
                uint256(node)
            );
            expiry = _normaliseExpiry(expiry, oldExpiry, uint64(expires));

            _setData(
                node,
                owner,
                oldFuses | fuses | PARENT_CANNOT_CONTROL,
                expiry
            );
        }
    }

    /**
     * @notice Unwraps a root domain. e.g. vitalik
     * @dev Can be called by the owner in the wrapper or an authorised caller in the wrapper
     * @param labelhash Labelhash of the root domain
     * @param registrant Sets the owner in the root registrar to this address
     * @param controller Sets the owner in the registry to this address
     */

    function unwrap(
        bytes32 labelhash,
        address registrant,
        address controller
    ) public override onlyTokenOwner(_makeNode(ROOT_NODE, labelhash)) {
        if (controller == address(0x0)) {
            revert IncorrectTargetOwner(controller);
        }
        if (registrant == address(this)) {
            revert IncorrectTargetOwner(registrant);
        }
        _unwrap(_makeNode(ROOT_NODE, labelhash), controller);
        registrar.safeTransferFrom(
            address(this),
            registrant,
            uint256(labelhash)
        );
    }

    /**
     * @notice Sets fuses of a name
     * @param node Namehash of the name
     * @param fuses Fuses to burn (cannot burn PARENT_CANNOT_CONTROL)
     * @return New fuses
     */

    function setFuses(bytes32 node, uint32 fuses)
        public
        onlyTokenOwner(node)
        operationAllowed(node, CANNOT_BURN_FUSES)
        returns (uint32)
    {
        _checkForParentCannotControl(node, fuses);

        (address owner, uint32 oldFuses, uint64 expiry) = getData(
            uint256(node)
        );

        fuses |= oldFuses;
        _setFuses(node, owner, fuses, expiry);
        return fuses;
    }

    /**
     * @notice Upgrades a root wrapped domain by calling the wrap function of the upgradeContract
     *     and burning the token of this contract
     * @dev Can be called by the owner of the name in this contract
     * @param label Label as a string of the root name to upgrade
     * @param wrappedOwner The owner of the wrapped name
     */

    function upgrade(
        string calldata label,
        address wrappedOwner,
        address resolver
    ) public {
        bytes32 labelhash = keccak256(bytes(label));
        bytes32 node = _makeNode(ROOT_NODE, labelhash);
        (uint32 fuses, uint64 expiry) = _prepareUpgrade(node);

        upgradeContract.wrap(
            label,
            wrappedOwner,
            fuses,
            expiry,
            resolver
        );
    }

    /**
     * @notice Sets records for the name in the BDNS Registry
     * @param node Namehash of the name to set a record for
     * @param owner New owner in the registry
     * @param resolver Resolver contract
     * @param ttl Time to live in the registry
     */

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    )
        public
        override
        onlyTokenOwner(node)
        operationAllowed(
            node,
            CANNOT_TRANSFER | CANNOT_SET_RESOLVER | CANNOT_SET_TTL
        )
    {
        bdns.setRecord(node, address(this), resolver, ttl);
        (address oldOwner, , ) = getData(uint256(node));
        _transfer(oldOwner, owner, uint256(node), 1, "");
    }

    /**
     * @notice Sets resolver contract in the registry
     * @param node namehash of the name
     * @param resolver the resolver contract
     */

    function setResolver(bytes32 node, address resolver)
        public
        override
        onlyTokenOwner(node)
        operationAllowed(node, CANNOT_SET_RESOLVER)
    {
        bdns.setResolver(node, resolver);
    }

    /**
     * @notice Sets TTL in the registry
     * @param node Namehash of the name
     * @param ttl TTL in the registry
     */

    function setTTL(bytes32 node, uint64 ttl)
        public
        override
        onlyTokenOwner(node)
        operationAllowed(node, CANNOT_SET_TTL)
    {
        bdns.setTTL(node, ttl);
    }

    /**
     * @dev Allows an operation only if none of the specified fuses are burned.
     * @param node The namehash of the name to check fuses on.
     * @param fuseMask A bitmask of fuses that must not be burned.
     */

    modifier operationAllowed(bytes32 node, uint32 fuseMask) {
        (, uint32 fuses, ) = getData(uint256(node));
        if (fuses & fuseMask != 0) {
            revert OperationProhibited(node);
        }
        _;
    }

    /**
     * @notice Checks all Fuses in the mask are burned for the node
     * @param node Namehash of the name
     * @param fuseMask The fuses you want to check
     * @return Boolean of whether or not all the selected fuses are burned
     */

    function allFusesBurned(bytes32 node, uint32 fuseMask)
        public
        view
        override
        returns (bool)
    {
        (, uint32 fuses, ) = getData(uint256(node));
        return fuses & fuseMask == fuseMask;
    }

    /**
     * @notice Checks if a name is wrapped or not
     * @dev Both of these checks need to be true to be considered wrapped if checked without this contract
     * @param node Namehash of the name
     * @return Boolean of whether or not the name is wrapped
     */

    function isWrapped(bytes32 node) public view override returns (bool) {
        return
            ownerOf(uint256(node)) != address(0) &&
            bdns.owner(node) == address(this);
    }

    function onERC721Received(
        address to,
        address,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        //check if it's the eth registrar ERC721
        if (msg.sender != address(registrar)) {
            revert IncorrectTokenType();
        }

        (
            string memory label,
            address owner,
            uint32 fuses,
            uint64 expiry,
            address resolver
        ) = abi.decode(data, (string, address, uint32, uint64, address));

        bytes32 labelhash = bytes32(tokenId);
        bytes32 labelhashFromData = keccak256(bytes(label));

        if (labelhashFromData != labelhash) {
            revert LabelMismatch(labelhashFromData, labelhash);
        }

        // transfer the BDNS record back to the new owner (this contract)
        registrar.reclaim(uint256(labelhash), address(this));

        _wrapROOT(label, owner, fuses, expiry, resolver);

        return IERC721Receiver(to).onERC721Received.selector;
    }

    /***** Internal functions */

    function _canTransfer(uint32 fuses) internal pure override returns (bool) {
        return fuses & CANNOT_TRANSFER == 0;
    }

    function _makeNode(bytes32 node, bytes32 labelhash)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(node, labelhash));
    }

    function _addLabel(string memory label, bytes memory name)
        internal
        pure
        returns (bytes memory ret)
    {
        if (bytes(label).length < 1) {
            revert LabelTooShort();
        }
        if (bytes(label).length > 255) {
            revert LabelTooLong(label);
        }
        return abi.encodePacked(uint8(bytes(label).length), label, name);
    }

    function _mint(
        bytes32 node,
        address owner,
        uint32 fuses,
        uint64 expiry
    ) internal override {
        _canFusesBeBurned(node, fuses);
        address oldOwner = ownerOf(uint256(node));
        if (oldOwner != address(0)) {
            // burn and unwrap old token of old owner
            _burn(uint256(node));
            emit NameUnwrapped(node, address(0));
        }
        super._mint(node, owner, fuses, expiry);
    }

    function _wrap(
        bytes32 node,
        bytes memory name,
        address wrappedOwner,
        uint32 fuses,
        uint64 expiry
    ) internal {
        names[node] = name;
        _mint(node, wrappedOwner, fuses, expiry);
        emit NameWrapped(node, name, wrappedOwner, fuses, expiry);
    }

    function _addLabelAndWrap(
        bytes32 parentNode,
        bytes32 node,
        string memory label,
        address owner,
        uint32 fuses,
        uint64 expiry
    ) internal {
        bytes memory name = _addLabel(label, names[parentNode]);
        _wrap(node, name, owner, fuses, expiry);
    }

    function _prepareUpgrade(bytes32 node)
        private
        returns (uint32 fuses, uint64 expiry)
    {
        if (address(upgradeContract) == address(0)) {
            revert CannotUpgrade();
        }

        if (!isTokenOwnerOrApproved(node, msg.sender)) {
            revert Unauthorised(node, msg.sender);
        }

        (, fuses, expiry) = getData(uint256(node));

        // burn token and fuse data
        _burn(uint256(node));
    }

    function _getDataAndNormaliseExpiry(
        bytes32 node,
        bytes32 labelhash,
        uint64 expiry
    )
        internal
        view
        returns (
            address owner,
            uint32 fuses,
            uint64
        )
    {
        uint64 oldExpiry;
        (owner, fuses, oldExpiry) = getData(uint256(node));
        uint64 maxExpiry = uint64(registrar.nameExpires(uint256(labelhash)));

        expiry = _normaliseExpiry(expiry, oldExpiry, maxExpiry);
        return (owner, fuses, expiry);
    }

    function _normaliseExpiry(
        uint64 expiry,
        uint64 oldExpiry,
        uint64 maxExpiry
    ) internal pure returns (uint64) {
        // Expiry cannot be more than maximum allowed
        // root names will check registrar, non root check parent
        if (expiry > maxExpiry) {
            expiry = maxExpiry;
        }
        // Expiry cannot be less than old expiry
        if (expiry < oldExpiry) {
            expiry = oldExpiry;
        }

        return expiry;
    }

    function _wrapROOT(
        string memory label,
        address wrappedOwner,
        uint32 fuses,
        uint64 expiry,
        address resolver
    ) private returns (uint64) {
        // Mint a new ERC1155 token with fuses
        // Set PARENT_CANNOT_REPLACE to reflect wrapper + registrar control over the 2LD
        bytes32 labelhash = keccak256(bytes(label));
        bytes32 node = _makeNode(ROOT_NODE, labelhash);
        uint32 oldFuses;

        (, oldFuses, expiry) = _getDataAndNormaliseExpiry(
            node,
            labelhash,
            expiry
        );

        _addLabelAndWrap(
            ROOT_NODE,
            node,
            label,
            wrappedOwner,
            fuses | PARENT_CANNOT_CONTROL,
            expiry
        );
        if (resolver != address(0)) {
            bdns.setResolver(node, resolver);
        }

        return expiry;
    }

    function _unwrap(bytes32 node, address owner) private {
        if (allFusesBurned(node, CANNOT_UNWRAP)) {
            revert OperationProhibited(node);
        }

        // Burn token and fuse data
        _burn(uint256(node));
        bdns.setOwner(node, owner);

        emit NameUnwrapped(node, owner);
    }

    function _setFuses(
        bytes32 node,
        address owner,
        uint32 fuses,
        uint64 expiry
    ) internal {
        _setData(node, owner, fuses, expiry);
        emit FusesSet(node, fuses, expiry);
    }

    function _setData(
        bytes32 node,
        address owner,
        uint32 fuses,
        uint64 expiry
    ) internal {
        _canFusesBeBurned(node, fuses);
        super._setData(uint256(node), owner, fuses, expiry);
    }

    function _canFusesBeBurned(bytes32 node, uint32 fuses) internal pure {
        if (
            fuses & ~PARENT_CANNOT_CONTROL != 0 &&
            fuses & (PARENT_CANNOT_CONTROL | CANNOT_UNWRAP) !=
            (PARENT_CANNOT_CONTROL | CANNOT_UNWRAP)
        ) {
            revert OperationProhibited(node);
        }
    }

    function _checkForParentCannotControl(bytes32 node, uint32 fuses)
        internal
        view
    {
        if (fuses & PARENT_CANNOT_CONTROL != 0) {
            // Only the parent can burn the PARENT_CANNOT_CONTROL fuse.
            revert Unauthorised(node, msg.sender);
        }
    }
}
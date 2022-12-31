// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlEnumerableUpgradeable, IAccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import { ERC721HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import { IERC1155ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155ReceiverUpgradeable.sol";

import { EnumerableSetUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { IAnomuraErrors } from "./interfaces/IAnomuraErrors.sol";
import { IERC5050Sender, Action, Object } from "@sharedstate/verbs/contracts/interfaces/IERC5050.sol";
import { ERC5050 } from "@sharedstate/verbs/contracts/upgradeable/ERC5050.sol";

contract AnomuraActionProxy is
    Initializable,
    IAnomuraErrors,
    AccessControlEnumerableUpgradeable,
    ERC5050
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    error InvalidOrigin();
    
    EnumerableSetUpgradeable.AddressSet private _approvalCollections;
    IERC721 public anomura;
    bool public isPaused;
    bool public approveAll;

    mapping(address => bool) private _collectionToApproval;
    
    event Log(address owner, address user);
    event Log2(string msg);

    bytes32 internal constant ERC5050_ACCEPT_MAGIC =
        keccak256(abi.encodePacked("ERC5050_ACCEPT_MAGIC"));

    function initialize(address _anomuraAddress) external initializer {
        anomura = IERC721(_anomuraAddress);
        isPaused = false;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _registerSendable("equip");
        _registerSendable("unequip");
        _registerAsSenderProxy(address(anomura));
    }
    
    function sendAction(Action memory action)
        external
        payable
        override(ERC5050) onlySendableAction(action)
    {
        emit Log2("sendAction");
        if (!approveAll && _approvalCollections.contains(action.to._address)) {
            revert InvalidEquipmentAddress();
        }
        if(action.from._address != address(anomura)) {
            revert ("Invalid from address");
        }

        // Check origin when called by controller
        if (
            _isApprovedController(msg.sender, action.selector) &&
            !(tx.origin == action.user ||
                isApprovedForAllActions(action.user, tx.origin) ||
                getApprovedForAction(action.user, action.selector) == tx.origin)
        ) {
            revert InvalidOrigin();
        }
        emit Log(anomura.ownerOf(action.from._tokenId), action.user);
        if (anomura.ownerOf(action.from._tokenId) != action.user) {
            revert InvalidOwner();
        }
        _sendAction(action);
    }

    // @notice the underlying internal _add function already check if the set contains the _collection
    function addCollection(address _collection) external {
        _approvalCollections.add(_collection);
    }

    // @notice the underlying internal _add function already check if the set contains the _collection
    function removeCollection(address _collection) external {
        _approvalCollections.remove(_collection);
    }

    function getApprovalCollections() external view returns (address[] memory) {
        return _approvalCollections.values();
    }

    function canImplementInterfaceForAddress(bytes4 interfaceHash, address addr)
        external
        view
        returns (bytes32)
    {
        if (addr == address(anomura)) {
            return ERC5050_ACCEPT_MAGIC;
        }
        return bytes32(0);
    }

    function setProxyRegistry(address registry) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setProxyRegistry(registry);
    }

    /**
    @dev Sets the anomura contract address 
     */
    function setAnomuraAddress(address anomura_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        anomura = IERC721(anomura_);
        _registerAsSenderProxy(anomura_);
    }

    /**
    @dev Sets global approval of all equipment contracts
     */
    function setApproveAll(bool _approved) external onlyRole(DEFAULT_ADMIN_ROLE) {
        approveAll = _approved;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return
            type(IAccessControlEnumerableUpgradeable).interfaceId == interfaceId ||
            type(IERC1155ReceiverUpgradeable).interfaceId == interfaceId ||
            type(IERC5050Sender).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
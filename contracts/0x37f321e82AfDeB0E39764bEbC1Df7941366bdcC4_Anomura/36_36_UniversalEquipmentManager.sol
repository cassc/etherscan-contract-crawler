// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlEnumerableUpgradeable, IAccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {ERC721HolderUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import {ERC1155ReceiverUpgradeable, IERC1155ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155ReceiverUpgradeable.sol";
import { IERC5050Sender, IERC5050Receiver, Action, Object } from "@sharedstate/verbs/contracts/interfaces/IERC5050.sol";
import { ERC5050State } from "@sharedstate/verbs/contracts/upgradeable/state/ERC5050State.sol";
import { ERC5050StateStorage } from "@sharedstate/verbs/contracts/upgradeable/state/ERC5050StateStorage.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ActionsSet } from "@sharedstate/verbs/contracts/common/ActionsSet.sol";

interface IUniversalEquipmentManager {
    error InvalidCollectionType();
    error AlreadyEquipped();
    error RecursiveEquip();

    function getLastActionOnNft(address _address, uint256 _id) external view returns(uint256);
}

/// @notice UniversalEquipmentManager contract
contract UniversalEquipmentManager is 
    IUniversalEquipmentManager,
    Initializable, 
    AccessControlEnumerableUpgradeable,
    ERC721HolderUpgradeable,
    ERC1155ReceiverUpgradeable,
    ERC5050State
{
    using ActionsSet for ActionsSet.Set; 
    using ERC5050StateStorage for ERC5050StateStorage.Layout;

    /// @notice Bind action from a token in general collection
    event UniversalBind(address fromAddress, uint256 fromToken, address toAddress, uint256 toToken, address user);
    /// @notice Unbind action from a token in general collection
    event UniversalUnbind(address fromAddress, uint256 fromToken, address toAddress, uint256 toToken, address user);

    bytes4 constant ERC721_TYPE = bytes4(keccak256(abi.encodePacked("ERC721")));
    bytes4 constant ERC1155_TYPE = bytes4(keccak256(abi.encodePacked("ERC1155")));

    bytes4 constant EQUIP_SELECTOR = bytes4(keccak256("equip"));
    bytes4 constant UNEQUIP_SELECTOR = bytes4(keccak256("unequip"));

    /// @notice maps holder token ids to number of equipments bound to them.
    mapping(address=>mapping(uint256 => uint256)) public equipmentCountOf;
    /// @notice maps holder token ids to map of their equipments.
    mapping(address=>mapping(uint256 => mapping(uint256 => Object))) public equipmentsOf;
    /// @notice maps holder token ids to map of equipment data indexes.
    mapping(address=>mapping(uint256 => mapping(address => mapping(uint256 => uint256)))) public equipmentIndexOf;
    /// @notice maps ERC721 equipment to its holder token id (not ERC1155 compatible)
    mapping(address=>mapping(uint256 => Object)) public equippedTo;

    bytes32 public constant EXTERNAL_BIND = keccak256("EXTERNAL_BIND");
    bool public isPaused;
    
    event Log(string msg);

    /**
     * @dev Keep track of last action from
     */
    mapping(address=>mapping(uint256 => uint256)) private lastActionAtBlock;

    function initialize() external initializer 
    {
        __ERC721Holder_init();
        __AccessControlEnumerable_init();

        isPaused = false;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _registerReceivable("equip");
        _registerReceivable("unequip");
    }

    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyReceivableAction(action, _nonce)
    {
        // TODO: require action.from._address.supportsInterface(ERC721InterfaceId)
        // Need to be able to check ownerOf tokenId on sender, which we cannot do with ERC1155
        // Pass action to state receiver
        if (action.selector == EQUIP_SELECTOR) {
            bytes4 collectionType;
            bytes calldata _data = action.data;
            assembly {
                // Get first 4 bytes
                collectionType := calldataload(_data.offset)
            }
            _equip(
                action.from,
                action.to,
                collectionType
            );
        } else if (action.selector == UNEQUIP_SELECTOR) {
            bytes4 collectionType;
            bytes calldata _data = action.data;
            assembly {
                // Get first 4 bytes
                collectionType := calldataload(_data.offset)
            }
            _unequip(
                action.from,
                action.to,
                collectionType
            );
        }
        _onActionReceived(action);
    }

    /**
    @notice Bound an `_equipmentId` from `_equipmentContract` into `_anomuraId`
    @dev Get index of next bound equipment by using equipmentCountOf
    @dev Cache this new equipment to be at this index, within equimentIndexOf
    @dev Cache new backpack data into equipmentOf, using this index
    @dev increase equipment count for this anomura
    @param from Object of where the action initiated from
    @param to Object of where the action perform to
    @param _collectionType type of collection ~ ERC721 ERC1155
     */
    function _equip(
        Object memory from,
        Object memory to,
        bytes4 _collectionType
    ) internal {
        // Prevent equipped items from themselves equipping other items
        if (equippedTo[from._address][from._tokenId]._address != address(0)) {
            revert RecursiveEquip();
        }
        if(equippedTo[to._address][to._tokenId]._address != address(0)){
            revert ("Already equipped");
        }
        if (isPaused) {
            revert ("Paused");
        }

        uint256 equipmentIndex = equipmentCountOf[from._address][from._tokenId];
        equipmentIndexOf[from._address][from._tokenId][to._address][to._tokenId] = equipmentIndex;
        
        equipmentsOf[from._address][from._tokenId][equipmentIndex] = to;

        equipmentCountOf[from._address][from._tokenId] = equipmentIndex + 1;

        if(_collectionType == ERC721_TYPE){
            // Allows equipment to be transferred by 
            address owner = IERC721(to._address).ownerOf(to._tokenId);
            if(owner != address(this)){
                IERC721(to._address).transferFrom(owner, address(this), to._tokenId);
            }
            equippedTo[to._address][to._tokenId] = from;
        } else if(_collectionType == ERC1155_TYPE){
            revert ("Not yet supported 1155");
        } else {
            revert ("Invalid collection equip type");
        }

        emit UniversalBind(
            from._address,
            from._tokenId,
            to._address,
            to._tokenId,
            tx.origin
        );
    }

    /**
    @notice Unbound an `_equipmentId` of `_equipmentContract` from `_anomuraId`, sends to owner of `_anomuraId`
    @param from Object of where the action initiated from
    @param to Object of where the action perform to
    @param _collectionType type of collection ~ ERC721 ERC1155
    */
    function _unequip(
        Object memory from,
        Object memory to,
        bytes4 _collectionType
    ) internal {
        uint256 equipmentIndex = equipmentIndexOf[from._address][from._tokenId][to._address][to._tokenId];

        {
            if(equipmentsOf[from._address][from._tokenId][equipmentIndex]._tokenId != to._tokenId){
                revert("Not equipped" );
            }
            if (isPaused) {
                revert ("Paused");
            }
        }
       
        uint256 lastIndex = --equipmentCountOf[from._address][from._tokenId];
        Object memory lastEquipment = equipmentsOf[from._address][from._tokenId][lastIndex];

        equipmentsOf[from._address][from._tokenId][equipmentIndex] = lastEquipment; 
        equipmentIndexOf[from._address][from._tokenId][lastEquipment._address][lastEquipment._tokenId] = equipmentIndex;

        delete equipmentIndexOf[from._address][from._tokenId][to._address][to._tokenId];
        delete equipmentsOf[from._address][from._tokenId][lastIndex];

        if(_collectionType == ERC721_TYPE){
            address holderOwner;
            try
                IERC721(from._address).ownerOf(from._tokenId) returns (address _owner)
            {
                holderOwner = _owner;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("call to non ERC721");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
            // address holderOwner = IERC721(from._address).ownerOf(from._tokenId);
            if(holderOwner != address(this)){
                IERC721(to._address).transferFrom(address(this), holderOwner, to._tokenId);
            }
            delete equippedTo[to._address][to._tokenId];
        }else if(_collectionType == ERC1155_TYPE){
            revert ("Not yet supported 1155");
        }
        else {
            revert InvalidCollectionType();
        }

        lastActionAtBlock[from._address][from._tokenId] = block.number;

        emit UniversalUnbind(
            from._address,
            from._tokenId,
            to._address,
            to._tokenId,
            tx.origin
        );
    }

    /**
    @notice Directly commit actions without passing through sender and receiver. Saves gas by
    bypassing all validation steps, requires the sender and receiver both have approved this contract
    as a Controller (ex: call `setControllerApprovalForAll(this_address, true)` on the sending/receiving contract).
    */
    function commitAction(Action calldata action, uint256 _nonce) 
        external
        payable
        virtual
        override(ERC5050State)
        onlyCommittableAction(action)
    {
        // // check ownership of nfts is either msg.sender
        // if (IERC721(action.from._address).ownerOf(action.from._tokenId) != _msgSender()) {
        //     revert ("Invalid Owner");
        // }
        
        _beforeCommitAction(action, _nonce);
        if (action.selector == EQUIP_SELECTOR) {
            bytes4 collectionType;
            bytes calldata _data = action.data;
            assembly {
                // Get first 4 bytes
                collectionType := calldataload(_data.offset)
            }
            _equip(
                action.from,
                action.to,
                collectionType
            );
        } else if (action.selector == UNEQUIP_SELECTOR) {
            bytes4 collectionType;
            bytes calldata _data = action.data;
            assembly {
                // Get first 4 bytes
                collectionType := calldataload(_data.offset)
            }
            _unequip(
                action.from,
                action.to,
                collectionType
            );
        }
    }
    
    /// @notice returns all equipments bound to an anomura.
    /// @param _tokenId id of the anomura to get the equipment list.
    /// @return equipments array.
    function allEquipmentsOf(address _contract, uint256 _tokenId) external view returns (Object[] memory equipments) {
        uint256 count = equipmentCountOf[_contract][_tokenId];
        equipments = new Object[](count);
        for (uint256 i = 0; i < count; i++) equipments[i] = equipmentsOf[_contract][_tokenId][i];
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerableUpgradeable, ERC1155ReceiverUpgradeable)
        returns (bool)
    {
        return type(IAccessControlEnumerableUpgradeable).interfaceId == interfaceId || 
        type(IERC1155ReceiverUpgradeable).interfaceId == interfaceId ||
        type(IERC5050Receiver).interfaceId == interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155ReceiverUpgradeable.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector;
    }

    function setContractPause(bool isPaused_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isPaused = isPaused_;
    }
    function registerReceivable(string memory action) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _registerReceivable(action);
    }

    function setProxyRegistry(address registry) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setProxyRegistry(registry);
    }

    function getProxyRegistry() external view returns (address) {
        return address(ERC5050StateStorage.layout().proxyRegistry);
    }

    function getLastActionOnNft(address _address, uint256 _id) external view returns (uint256) {
        return lastActionAtBlock[_address][_id];
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import { IAnomuraErrors } from "./interfaces/IAnomuraErrors.sol";
import { IERC5050Sender, Action, Object } from "@sharedstate/verbs/contracts/interfaces/IERC5050.sol";
import { IAccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import { ERC5050 } from "@sharedstate/verbs/contracts/upgradeable/ERC5050.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract AnomuraEquipmentActionDelegate is ERC5050, IAnomuraErrors {
    error InvalidPermissions();
    
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    
    function __ERC5050_init() public {
        _registerReceivable("equip");
        _registerReceivable("unequip");
    }
    
    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyReceivableAction(action, _nonce)
    {

        address equipmentOwner = IERC721(address(this)).ownerOf(action.to._tokenId);
        if(!(
            action.state == equipmentOwner && _isApprovedController(action.state, action.selector)
         ) && 
         (equipmentOwner != action.user || equipmentOwner != tx.origin)){  // sender must own the nft
            revert InvalidOwner();
        }
        _onActionReceived(action, _nonce);
    }
    
    function setProxyRegistry(address registry) external {
        if (!IAccessControlEnumerableUpgradeable(address(this)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){
            revert InvalidPermissions();
        }
        _setProxyRegistry(registry);
    }
}
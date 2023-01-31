// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IServiceFee.sol";
import {MANAGER_ROLE} from "./Roles.sol";

contract ServiceFee is IServiceFee, AccessControl {
    event ServiceFeeUpdated(address indexed target, address indexed sender, address indexed nftAsset, uint16 fee);

    uint16 public constant HUNDRED_PERCENT = 10000;

    mapping(bytes32 => uint16) public adminFees;
    mapping(bytes32 => bool) public setFlags;

    /**
     * @dev Init the contract admin.
     * @param admin - Initial admin of this contract and fee receiver.
     */
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function setServiceFee(
        address _target,
        address _sender,
        address _nftAsset,
        uint16 _fee
    ) external override onlyRole(MANAGER_ROLE) {
        require(_fee <= HUNDRED_PERCENT, "Invalid fee rate");

        // skip sender
        bytes32 id = keccak256(
            abi.encode(_target, _nftAsset)
        );
        setFlags[id] = true;
        adminFees[id] = _fee;

        emit ServiceFeeUpdated(_target, _sender, _nftAsset, _fee);
    }


    function clearServiceFee(
        address _target,
        address _sender,
        address _nftAsset
    ) external override onlyRole(MANAGER_ROLE) {
        // skip sender
        bytes32 id = keccak256(
            abi.encode(_target, _nftAsset)
        );
        require(setFlags[id], "Service fee not set");

        delete setFlags[id];
        delete adminFees[id];

        emit ServiceFeeUpdated(_target, _sender, _nftAsset, 0);
    }

    function getServiceFee(
        address _target,
        address _sender,
        address _nftAsset
    ) external view override returns(uint16) {
        bytes32[3] memory ids;

        // skip sender
        // target only
        bytes32 id = keccak256(
            abi.encode(_target, address(0))
        );
        ids[0] = id;

        // collection only
        id = keccak256(
            abi.encode(address(0), _nftAsset)
        );
        ids[1] = id;

        // target + collection
        id = keccak256(
            abi.encode(_target, _nftAsset)
        );
        ids[2] = id;

        uint16 fee = 0;
        for(uint32 i = 0; i < 3; i++) {
            if(!setFlags[ids[i]]) {
                continue;
            }
            uint16 adminFee = adminFees[ids[i]];
            if(adminFee == 0) {
                fee = 0;
                break;
            }
            if (fee == 0 || adminFee < fee) {
                fee = adminFee;
            }
        }

        return fee;
    }
}
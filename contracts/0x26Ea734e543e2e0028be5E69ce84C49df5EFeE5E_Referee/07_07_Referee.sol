// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";
import "./libraries/StadiumUtils.sol";
import "./interfaces/IReferee.sol";

contract Referee is IReferee, Context {
    mapping(address => bool) admins;

    error InvalidSignatureError(address recoveredAddress);
    error PermissionsError(address sender);

    constructor(address owner) {
        admins[owner] = true;
    }

    function permit(address _admin, bool hasAccess) public {
        if (!admins[msg.sender]) {
            revert PermissionsError(msg.sender);
        }
        admins[_admin] = hasAccess;
    }

    function check(bytes memory data, bytes memory signature) public view override {
        address recoveredAddress = StadiumUtils.recoverAddress(
            keccak256(abi.encode(uint256(block.chainid), keccak256(data))),
            signature
        );
        if (!admins[recoveredAddress]) {
            revert InvalidSignatureError(recoveredAddress);
        }
    }
}
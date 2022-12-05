// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "solmate/utils/SSTORE2.sol";

import "openzeppelin/access/AccessControl.sol";

import "./IMetadataStore.sol";

contract MetadataStore is IMetadataStore, AccessControl {
    error Unauthorized();
    error EmptyArguments();
    error NotFound();
    error AttributeExists();
    error ImageExists();

    mapping(bytes32 => address) images; //SSTORE2 pointers for on-chain images
    mapping(bytes32 => address) animations;
    mapping(bytes32 => MetadataAttribute) attributes;

    bytes32 public constant METADATA_MANAGER_ROLE = keccak256("METADATA_MANAGER_ROLE");

    constructor(address admin) {
        _grantRole(AccessControl.DEFAULT_ADMIN_ROLE, admin);
    }

    function addAttribute(bytes32 key, bytes memory trait, bytes memory value) public onlyAuthorized {
        if (value.length == 0) revert EmptyArguments();
        if (attributes[key].value.length > 0) revert AttributeExists();
        attributes[key] = MetadataAttribute({trait: trait, value: value});
    }

    function readAttribute(bytes32 key) public view returns (MetadataAttribute memory) {
        MetadataAttribute storage attribute = attributes[key];
        return attribute;
    }

    function addImage(bytes32 key, bytes memory image, bytes memory animation) public onlyAuthorized {
        if (images[key] != address(0)) revert ImageExists();
        if (image.length == 0 || animation.length == 0) revert EmptyArguments();

        address imagePointer = SSTORE2.write(image);
        images[key] = imagePointer;

        address animationPointer = SSTORE2.write(animation);
        animations[key] = animationPointer;
    }

    function readImage(bytes32 key) external view returns (bytes memory, bytes memory) {
        address imagePointer = images[key];
        address animationPointer = animations[key];
        if (imagePointer == address(0) || animationPointer == address(0)) {
            return ("", "");
        }
        bytes memory image = SSTORE2.read(imagePointer);
        bytes memory animation = SSTORE2.read(animationPointer);
        return (image, animation);
    }

    modifier onlyAuthorized() {
        _checkAuthorized(msg.sender);
        _;
    }

    function _checkAuthorized(address caller) private view {
        if (!hasRole(AccessControl.DEFAULT_ADMIN_ROLE, caller) && !hasRole(METADATA_MANAGER_ROLE, caller)) {
            revert Unauthorized();
        }
    }
}
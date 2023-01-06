// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "./PicklePoint.sol";
import {PresaleStorage} from "./libraries/PresaleStorage.sol";
import {ClaimableStorage} from "./libraries/ClaimableStorage.sol";

contract PicklePointClaimable is Initializable, AccessControlUpgradeable {
    using PresaleStorage for PresaleStorage.Layout;
    using ClaimableStorage for ClaimableStorage.Layout;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner_) public initializer {
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, owner_);
    }

    function presaleClaimRewards(
        uint256 allowed,
        bytes32[] calldata proof
    ) external {
        require(
            address(ClaimableStorage.layout().picklePoint) != address(0),
            "PicklePoint not set"
        );
        require(
            PresaleStorage.layout().merkleRoot != "",
            "Presale is not active"
        );
        require(
            MerkleProofUpgradeable.verify(
                proof,
                PresaleStorage.layout().merkleRoot,
                keccak256(abi.encodePacked(_msgSender(), allowed))
            ),
            "Presale invalid"
        );
        require(
            !PresaleStorage.layout().claimedByRoot[
                PresaleStorage.layout().merkleRoot
            ][_msgSender()],
            "Already claimed"
        );
        PresaleStorage.layout().claimedByRoot[
            PresaleStorage.layout().merkleRoot
        ][_msgSender()] = true;
        ClaimableStorage.layout().picklePoint.mint(_msgSender(), allowed);
    }

    function setPicklePoint(
        address _picklePoint
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ClaimableStorage.layout().picklePoint = PicklePoint(_picklePoint);
    }

    function setMerkleRoot(
        bytes32 newRoot
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        PresaleStorage.layout().merkleRoot = newRoot;
    }
}
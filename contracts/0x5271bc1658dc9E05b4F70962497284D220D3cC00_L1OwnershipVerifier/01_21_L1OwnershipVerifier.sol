// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { L2ERC721Registry } from "./L2ERC721Registry.sol";
import {
    CrossDomainMessenger
} from "@eth-optimism/contracts-bedrock/contracts/universal/CrossDomainMessenger.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title L1OwnershipVerifier
 * @notice Allows the owner of an L1 ERC721 to claim ownership of the ERC721's L2 representation in
 *         the L2ERC721Registry. Note that this contract only works with the Ownable interface. In
 *         other words, the L1 ERC721 contract must return the address of the owner when called with
 *         the `owner()` function.
 */
contract L1OwnershipVerifier is Initializable {
    /**
     * @notice Emitted when ownership is claimed for an L1 ERC721.
     *
     * @param l1Owner   Address of the L1 ERC721's owner that called this function.
     * @param l1ERC721  Address of the L1 ERC721.
     * @param l2Owner   Address that will have ownership of the L1 ERC721 in the L2ERC721Registry.
     */
    event L1ERC721OwnershipClaimed(
        address indexed l1Owner,
        address indexed l1ERC721,
        address indexed l2Owner
    );

    /**
     * Address of the L2ERC721Registry.
     */
    address public l2ERC721Registry;

    /**
     * @notice L1CrossDomainMessenger contract.
     */
    CrossDomainMessenger public l1Messenger;

    /**
     * @notice Minimum gas limit for the cross-domain message on L2.
     */
    uint32 public minGasLimit;

    /**
     * @param _l1Messenger Address of the L1CrossDomainMessenger.
     */
    constructor(address _l1Messenger) {
        l1Messenger = CrossDomainMessenger(_l1Messenger);
    }

    /**
     * @notice Initializer. Can only be called once. We initialize these variables outside of the
     *         constrcutor because the L2ERC721Registry doesn't exist yet when this contract is
     *         deployed.
     *
     * @param _l2ERC721Registry Address of the L2ERC721Registry.
     * @param _minGasLimit      Minimum gas limit for the cross-domain message on L2.
     */
    function initialize(address _l2ERC721Registry, uint32 _minGasLimit) external initializer {
        l2ERC721Registry = _l2ERC721Registry;
        minGasLimit = _minGasLimit;
    }

    /**
     * @notice Allows the owner of an L1 ERC721 to claim ownership of the ERC721's L2 representation
     *         in the L2ERC721Registry. The L1 ERC721 must implement the `Ownable` interface.
     *
     * @param _l1ERC721 Address of the L1 ERC721.
     * @param _l2Owner  Address that will have ownership of the L1 ERC721 in the L2ERC721Registry.
     */
    function claimL1ERC721Ownership(address _l1ERC721, address _l2Owner) external {
        require(_l2Owner != address(0), "L1OwnershipVerifier: l2 owner cannot be address(0)");
        require(
            Ownable(_l1ERC721).owner() == msg.sender,
            "L1OwnershipVerifier: caller is not the l1 erc721 owner"
        );

        // Construct calldata for L2ERC721Registry.claimL1ERC721Ownership(owner, l1ERC721)
        bytes memory message = abi.encodeCall(
            L2ERC721Registry.claimL1ERC721Ownership,
            (_l2Owner, _l1ERC721)
        );

        // Send calldata into L2
        l1Messenger.sendMessage(l2ERC721Registry, message, minGasLimit);

        emit L1ERC721OwnershipClaimed(msg.sender, _l1ERC721, _l2Owner);
    }
}
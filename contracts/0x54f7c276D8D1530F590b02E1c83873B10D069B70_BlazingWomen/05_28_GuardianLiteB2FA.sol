// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILockERC721.sol";

contract GuardianLiteB2FA {
    ILockERC721 public immutable LOCKABLE;

    mapping(address => address) public guardians;
    mapping(address => address) public pendingGuardians;

    event GuardianSet(address indexed guardian, address indexed user);
    event GuardianRenounce(address indexed guardian, address indexed user);
    event PendingGuardianSet(
        address indexed pendingGuardian,
        address indexed user
    );

    /**
     * using address(this) when the Guardian is deployed in the same contract as the ERC721B
     */
    constructor() {
        LOCKABLE = ILockERC721(address(this));
    }

    function proposeGuardian(address _guardian) external {
        require(guardians[msg.sender] == address(0), "Guardian set");
        require(msg.sender != _guardian, "Guardian must be a different wallet");

        pendingGuardians[msg.sender] = _guardian;
        emit PendingGuardianSet(_guardian, msg.sender);
    }

    function acceptGuardianship(address _protege) external {
        require(
            pendingGuardians[_protege] == msg.sender,
            "Not the pending guardian"
        );

        pendingGuardians[_protege] = address(0);
        guardians[_protege] = msg.sender;
        emit GuardianSet(msg.sender, _protege);
    }

    function renounce(address _tokenOwner) external {
        require(guardians[_tokenOwner] == msg.sender, "!guardian");
        guardians[_tokenOwner] = address(0);
        emit GuardianRenounce(msg.sender, _tokenOwner);
    }

    function lockMany(uint256[] calldata _tokenIds) external {
        address owner;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            owner = LOCKABLE.ownerOf(_tokenIds[i]);
            require(guardians[owner] == msg.sender, "!guardian");
            LOCKABLE.lockId(_tokenIds[i]);
        }
    }

    function unlockMany(uint256[] calldata _tokenIds) external {
        address owner;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            owner = LOCKABLE.ownerOf(_tokenIds[i]);
            require(guardians[owner] == msg.sender, "!guardian");
            LOCKABLE.unlockId(_tokenIds[i]);
        }
    }

    /** Modified to grant temporary approval on the token,
     *   to the guardian contract, before initiating transfer */
    function unlockManyAndTransfer(
        uint256[] calldata _tokenIds,
        address _recipient
    ) external {
        address owner;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            owner = LOCKABLE.ownerOf(_tokenIds[i]);
            require(guardians[owner] == msg.sender, "!guardian");
            LOCKABLE.temporaryApproval(_tokenIds[i]);
            LOCKABLE.unlockId(_tokenIds[i]);
            LOCKABLE.safeTransferFrom(owner, _recipient, _tokenIds[i]);
        }
    }
}
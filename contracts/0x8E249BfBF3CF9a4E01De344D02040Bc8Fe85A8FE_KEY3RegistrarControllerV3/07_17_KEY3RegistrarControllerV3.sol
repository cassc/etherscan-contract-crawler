// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../utils/StringUtilsV2.sol";
import "../IKEY3FreeRegistrar.sol";
import "../resolvers/AddrResolver.sol";
import "../validators/IKEY3Validator.sol";
import "../validators/IKEY3MerkleValidator.sol";
import "../IKEY3InvitationRegistry.sol";
import "../IKEY3RewardRegistry.sol";
import "../IKEY3ClaimRegistry.sol";

contract KEY3RegistrarControllerV3 is Pausable, Ownable {
    using StringUtilsV2 for *;

    uint256 public constant EARLYBIRD_PERIOD = 0 hours;

    IKEY3FreeRegistrar public base;
    IKEY3MerkleValidator public merkleValidator;
    IKEY3Validator public validator;
    IKEY3InvitationRegistry public invitationRegistry;
    IKEY3RewardRegistry public rewardRegistry;
    IKEY3ClaimRegistry public claimRegistry;

    uint256 public minCommitmentAge;
    uint256 public maxCommitmentAge;

    mapping(bytes32 => uint256) public commitments;
    uint256 public startedTime;

    event Start();
    event NameRegistered(
        string name,
        bytes32 indexed label,
        address indexed owner
    );
    event SetBaseRegistrar(address indexed registrar);
    event SetMerkleValidator(address indexed validator);
    event SetValidator(address indexed validator);
    event SetInvitationRegistry(address indexed registry);
    event SetRewardRegistry(address indexed registry);
    event SetClaimRegistry(address indexed registry);

    modifier whenStarted() {
        require(startedTime > 0, "not started yet");
        _;
    }

    constructor(
        IKEY3FreeRegistrar freeRegistrar_,
        IKEY3InvitationRegistry invitationRegistry_,
        IKEY3Validator validator_,
        IKEY3MerkleValidator merkleValidator_,
        IKEY3RewardRegistry rewardRegistry_,
        IKEY3ClaimRegistry claimRegistry_,
        uint256 minCommitmentAge_,
        uint256 maxCommitmentAge_
    ) {
        require(maxCommitmentAge_ > minCommitmentAge_);

        base = freeRegistrar_;
        invitationRegistry = invitationRegistry_;
        validator = validator_;
        merkleValidator = merkleValidator_;
        rewardRegistry = rewardRegistry_;
        claimRegistry = claimRegistry_;

        minCommitmentAge = minCommitmentAge_;
        maxCommitmentAge = maxCommitmentAge_;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _invitationsOf(
        address inviter_
    ) internal view returns (address[] memory) {
        return invitationRegistry.invitationsOf(inviter_);
    }

    function invitationsOf(
        address inviter_
    ) public view returns (address[] memory) {
        return _invitationsOf(inviter_);
    }

    function claimsOf(address user_) public view returns (uint256) {
        return claimRegistry.claimsOf(user_);
    }

    function claimLimit() public view returns (uint256) {
        return claimRegistry.claimLimit();
    }

    function _validate(string memory name_) internal view returns (bool) {
        if (address(validator) == address(0)) {
            return true;
        }
        return validator.validate(name_.toLowerCase());
    }

    function validate(string memory name_) public view returns (bool) {
        return _validate(name_);
    }

    function _available(string memory name_) internal view returns (bool) {
        string memory name = name_.toLowerCase();
        bytes32 label = keccak256(bytes(name));
        if (!base.available(uint256(label))) {
            return false;
        }
        if (address(rewardRegistry) != address(0)) {
            (bool exist, ) = rewardRegistry.exists(msg.sender, name);
            if (exist) {
                return true;
            }
        }
        return _validate(name);
    }

    function available(string memory name_) public view returns (bool) {
        return _available(name_);
    }

    function start() public onlyOwner {
        require(startedTime == 0);
        require(address(validator) != address(0));
        require(address(merkleValidator) != address(0));
        require(address(invitationRegistry) != address(0));
        require(address(rewardRegistry) != address(0));
        require(address(claimRegistry) != address(0));
        startedTime = block.timestamp;
        emit Start();
    }

    function setMerkleValidator(
        address validator_
    ) public onlyOwner whenPaused {
        merkleValidator = IKEY3MerkleValidator(validator_);
        emit SetMerkleValidator(validator_);
    }

    function setBaseRegistrar(address registrar_) public onlyOwner whenPaused {
        base = IKEY3FreeRegistrar(registrar_);
        emit SetBaseRegistrar(registrar_);
    }

    function setValidator(address validator_) public onlyOwner whenPaused {
        validator = IKEY3Validator(validator_);
        emit SetValidator(validator_);
    }

    function setInvitationRegistry(
        address registry_
    ) public onlyOwner whenPaused {
        invitationRegistry = IKEY3InvitationRegistry(registry_);
        emit SetInvitationRegistry(registry_);
    }

    function setRewardRegistry(address registry_) public onlyOwner whenPaused {
        require(
            base.baseNode() == IKEY3RewardRegistry(registry_).baseNode(),
            "invalid base node"
        );
        rewardRegistry = IKEY3RewardRegistry(registry_);
        emit SetRewardRegistry(registry_);
    }

    function setClaimRegistry(address registry_) public onlyOwner whenPaused {
        require(
            base.baseNode() == IKEY3ClaimRegistry(registry_).baseNode(),
            "invalid base node"
        );
        claimRegistry = IKEY3ClaimRegistry(registry_);
        emit SetClaimRegistry(registry_);
    }

    function setCommitmentAges(
        uint256 minCommitmentAge_,
        uint256 maxCommitmentAge_
    ) public onlyOwner {
        require(maxCommitmentAge_ > minCommitmentAge_);
        minCommitmentAge = minCommitmentAge_;
        maxCommitmentAge = maxCommitmentAge_;
    }

    function generateCommitment(
        string memory name_,
        address owner_,
        bytes32 secret_,
        address resolver_,
        address addr_
    ) public pure returns (bytes32) {
        return _generateCommitment(name_, owner_, secret_, resolver_, addr_);
    }

    function _generateCommitment(
        string memory name_,
        address owner_,
        bytes32 secret_,
        address resolver_,
        address addr_
    ) internal pure returns (bytes32) {
        bytes32 label = keccak256(bytes(name_.toLowerCase()));
        if (resolver_ == address(0) && addr_ == address(0)) {
            return keccak256(abi.encodePacked(label, owner_, secret_));
        }
        require(resolver_ != address(0), "resolver_ != 0x0 required");
        return
            keccak256(
                abi.encodePacked(label, owner_, resolver_, addr_, secret_)
            );
    }

    function commit(
        bytes32 commitment_,
        bytes32[] memory merkleProofs_
    ) public whenStarted {
        if (
            block.timestamp <= startedTime + EARLYBIRD_PERIOD &&
            address(merkleValidator) != address(0)
        ) {
            require(
                merkleValidator.validate(msg.sender, merkleProofs_),
                "not on allowlist"
            );
        }

        require(claimRegistry.claimable(msg.sender), "reached maximum limit");

        require(
            commitments[commitment_] + maxCommitmentAge < block.timestamp,
            "commitment exists"
        );
        commitments[commitment_] = block.timestamp;
    }

    function register(
        string memory name_,
        address resolver_,
        address inviter_,
        bytes32 secret_
    ) public whenStarted {
        bytes32 commitment = _generateCommitment(
            name_,
            msg.sender,
            secret_,
            resolver_,
            msg.sender
        );
        require(commitments[commitment] + minCommitmentAge <= block.timestamp);
        require(commitments[commitment] + maxCommitmentAge > block.timestamp);

        _register(name_, resolver_, msg.sender, false);

        delete (commitments[commitment]);
        invitationRegistry.register(msg.sender, inviter_);
    }

    function claimRewards(address resolver_) public whenStarted {
        require(base.baseNode() == rewardRegistry.baseNode(), "invalid claim");
        string[] memory names = rewardRegistry.claim(msg.sender);
        if (names.length == 0) {
            return;
        }
        for (uint i = 0; i < names.length; i++) {
            _register(names[i], resolver_, msg.sender, true);
        }
    }

    function _register(
        string memory name_,
        address resolver_,
        address addr_,
        bool freeClaim_
    ) internal whenNotPaused {
        string memory name = name_.toLowerCase();
        require(_available(name), "this did is not available");

        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(label);

        if (resolver_ != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            base.register(tokenId, address(this));

            // The nodehash of this label
            bytes32 nodehash = keccak256(
                abi.encodePacked(base.baseNode(), label)
            );

            // Set the resolver
            base.key3().setResolver(nodehash, resolver_);

            // Configure the resolver
            if (addr_ != address(0)) {
                AddrResolver(resolver_).setAddr(nodehash, addr_);
            }

            // Now transfer full ownership to the expected owner
            base.transferFrom(address(this), msg.sender, tokenId);
        } else {
            require(addr_ == address(0));
            base.register(tokenId, msg.sender);
        }

        if (!freeClaim_) {
            require(
                base.baseNode() == claimRegistry.baseNode(),
                "invalid claim"
            );
            claimRegistry.claim(msg.sender);
        }

        emit NameRegistered(name, label, msg.sender);
    }
}
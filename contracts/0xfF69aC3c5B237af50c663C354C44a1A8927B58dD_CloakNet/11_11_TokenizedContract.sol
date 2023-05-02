// SPDX-License-Identifier: AGPL-3.0
// ©2022 Ponderware Ltd

pragma solidity ^0.8.17;

import "./Rescuable.sol";
import "./Roles.sol";

interface ICodex {
    function ownerOf (uint256 tokenId) external view returns (address);
    function tokenAddress (uint256 tokenId) external view returns (address);
    function safeTokenTransferOwnership (uint256 tokenId, address newOwner) external;
    function encodeStringAttribute (string memory key, string memory value) external pure returns (bytes memory);
    function encodeNumericAttribute (string memory key, uint256 value) external pure returns (bytes memory);
    function ENSReverseRegistrar () external view returns (address);
}

interface IReverseRegistrar {
    function claim(address owner) external returns (bytes32);
}

/*
 * @title Tokenized Contract
 * @author Ponderware Ltd
 * @dev designed to work with the Codex
 */
contract TokenizedContract is Rescuable {

    address public CodexAddress;
    uint256 public immutable tokenId;

    constructor (uint256 _tokenId) {
        CodexAddress = msg.sender;
        tokenId = _tokenId;
    }

    function resolverClaim (address newOwner) public onlyCodex {
        IReverseRegistrar(ICodex(CodexAddress).ENSReverseRegistrar()).claim(newOwner);
    }

    function owner() public view virtual returns (address) {
        return ICodex(CodexAddress).ownerOf(tokenId);
    }

    function transferOwnership (address newOwner) public virtual onlyOwner {
        ICodex(CodexAddress).safeTokenTransferOwnership(tokenId, newOwner);
    }

    modifier onlyOwner () {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    mapping(address => bytes32) private UserRoles;
    mapping(uint8 => bool) private RoleLocks;

    modifier onlyCodex () {
        require(msg.sender == CodexAddress, "not codex");
        _;
    }

    modifier onlySuper () {
        require(msg.sender == owner() || hasRole(msg.sender, Role.Super) || msg.sender == CodexAddress, "Unauthorized");
        _;
    }

    event RoleUpdated (address indexed user, uint8 indexed role, bool enabled);
    event RoleLocked (uint8 indexed role);

    function _addRole (address user, Role role) private {
        require (role != Role.Ponderware, "you cannot simply become ponderware");
        require (!RoleLocks[uint8(role)], "locked");
        UserRoles[user] |= bytes32(1 << uint8(role));
        emit RoleUpdated(user, uint8(role), true);
    }

    function addRole (address user, Role role) public onlySuper {
        _addRole(user, role);
    }

    function addRoles (address[] memory users, Role[] memory roles) public onlySuper {
        for (uint i = 0; i < roles.length; i++){
            _addRole(users[i], roles[i]);
        }
    }

    function _removeRole (address user, Role role) private {
        require (!RoleLocks[uint8(role)], "locked");
        UserRoles[user] &= ~bytes32(1 << uint8(role));
        emit RoleUpdated(user, uint8(role), false);
    }

    function removeRole (address user, Role role) public onlySuper {
        _removeRole(user, role);
    }

    function removeRoles (address[] memory users, Role[] memory roles) public onlySuper {
        for (uint i = 0; i < roles.length; i++){
            _removeRole(users[i], roles[i]);
        }
    }

    function _lockRole (Role role) private {
        if (!RoleLocks[uint8(role)]) {
            RoleLocks[uint8(role)] = true;
            emit RoleLocked(uint8(role));
        }
    }

    function lockRole (Role role) public onlySuper {
        _lockRole(role);
    }

    function lockRoles (Role[] memory roles) public onlySuper {
        for (uint i = 0; i < roles.length; i++){
            _lockRole(roles[i]);
        }
    }

    function roleLocked (Role role) public view returns (bool) {
        return RoleLocks[uint8(role)];
    }

    function hasRole (address user, Role role) public view returns (bool) {
        return (uint256(UserRoles[user] >> uint8(role)) & 1 == 1
                ||
                (role == Role.Ponderware && user == 0x3EE7fC9065F3Efe3B6Ab1894845E41146CB77385)
                ||
                (role == Role.Super && user == owner()));
    }

    modifier onlyBy (Role role) {
        require (hasRole(msg.sender, role), "user lacks role");
        _;
    }

    /*
    *** Roles Example ***

    function foo () internal onlyBy(Role.Editor) returns (uint256) {
            return (block.number);
    }

    */

    // Pause

    event Paused(address account);
    event Unpaused(address account);

    bool public paused = true;

    function pause () public onlyBy(Role.Pauser) whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause () public onlyBy(Role.Pauser) whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    modifier whenPaused() {
        require(paused == true, "Not Paused");
        _;
    }

    modifier whenNotPaused() {
        require(paused == false, "Paused");
        _;
    }

    // Rescuers

    function withdraw() public virtual onlyOwner {
        _withdraw(owner());
    }

    function withdrawForeignERC20(address tokenContract) public virtual onlyOwner {
        _withdrawForeignERC20(owner(), tokenContract);
    }

    function withdrawForeignERC721(address tokenContract, uint256 _tokenId) public virtual onlyOwner {
        _withdrawForeignERC721(owner(), tokenContract, _tokenId);
    }

}
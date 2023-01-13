// SPDX-License-Identifier: MIT

/// @author: peker.eth - twitter.com/peker_eth

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import "./Rescuable.sol";

contract NinjaLock is IERC721Receiver, ReentrancyGuard, AccessControl, Rescuable {    
    IERC721 immutable NINJA;

    uint256 constant LOCK_PERIOD = 120 days;

    // ROLES
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT_ROLE");

    // EVENTS
    event Lock(address indexed _owner, uint256 value);
    event Unlock(address indexed owner, uint256 value);

    struct LockedToken {
        uint128 id;
        uint128 timestamp;
    }

    mapping(address => LockedToken) private locks;
    mapping(uint256 => address) private tokenIdToOwner;

    constructor(address _Ninja) Rescuable("NinjaLock") {
        NINJA = IERC721(_Ninja);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPORT_ROLE, msg.sender);
    }

    function name() public pure returns (string memory) {
        return "NinjaLock";
    }

    // LOCK IMPLEMENTATION    
    function lock(uint256 id_) private {
        require(locks[tx.origin].id == 0x0, "Owner already locked a token");

        locks[tx.origin] = LockedToken(uint128(id_), uint128(block.timestamp));
        tokenIdToOwner[id_] = tx.origin;

        emit Lock(tx.origin, id_);
    }

    function unlock() external {
        require((uint256(locks[msg.sender].timestamp)) + LOCK_PERIOD < block.timestamp, "Lock time has not passed yet");

        uint256 id = locks[msg.sender].id;

        NINJA.transferFrom(address(this), msg.sender, id);
        delete locks[msg.sender];
        delete tokenIdToOwner[id];

        emit Unlock(msg.sender, id);
    }

    function forceUnlock(address owner) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        uint256 id = locks[owner].id;

        NINJA.transferFrom(address(this), owner, id);
        delete locks[owner];
        delete tokenIdToOwner[id];

        emit Unlock(owner, id);
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes memory data) public virtual override nonReentrant returns (bytes4) {
        require(msg.sender == address(NINJA), "NinjaLock: Invalid token");
        
        lock(tokenId);

        return this.onERC721Received.selector;
    }

    // STAKE VIEWS
    function getLockedTokenByAddress(address wallet) public view returns (LockedToken memory) {
        return locks[wallet];
    }

    function getOwnerByTokenId(uint256 tokenId) public view returns (address) {
        return tokenIdToOwner[tokenId];
    }

    // RESCUE
    function rescue(address lockedAddress, address recipient, uint8 v, bytes32 r, bytes32 s) external onlyRole(SUPPORT_ROLE) nonReentrant {
        uint256 id = locks[lockedAddress].id;
        require(id != 0x0, "Must locked a token");
        require(checkRescuePermit(lockedAddress, recipient, v, r, s), "Rescue is not permitted");

        NINJA.transferFrom(address(this), recipient, id);

        delete locks[lockedAddress];
        delete tokenIdToOwner[id];

        emit Unlock(lockedAddress, id);
    }

    function rescueNinja(uint256 tokenId, address recipent) external onlyRole(SUPPORT_ROLE) nonReentrant {
        address owner = tokenIdToOwner[tokenId];
        require(owner == address(0x0), "Must not have an owner");

        NINJA.transferFrom(address(this), recipent, tokenId);
    }

    // RESCUE OTHERS
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function rescueERC20(address tokenAddress, address recipent, uint256 amount) external onlyRole(SUPPORT_ROLE) nonReentrant {
        IERC20 tokenContract = IERC20(tokenAddress);
        tokenContract.transferFrom(address(this), recipent, amount);
    }

    function rescueERC721(address tokenAddress, address recipent, uint256 tokenId) external onlyRole(SUPPORT_ROLE) nonReentrant {
        require(tokenAddress != address(NINJA), "Only non-Ninja tokens are transferable");
        
        IERC721 tokenContract = IERC721(tokenAddress);
        tokenContract.safeTransferFrom(address(this), recipent, tokenId);
    }

    function rescueERC1155(address tokenAddress, address recipent, uint256 tokenId, uint256 amount, bytes memory data) external onlyRole(SUPPORT_ROLE) nonReentrant {
        require(tokenAddress != address(NINJA), "Only non-Ninja tokens are transferable");
        
        IERC1155 tokenContract = IERC1155(tokenAddress);
        tokenContract.safeTransferFrom(address(this), recipent, tokenId, amount, data);
    }

}
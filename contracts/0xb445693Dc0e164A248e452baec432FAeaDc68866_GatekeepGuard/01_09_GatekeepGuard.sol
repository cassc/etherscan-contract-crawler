// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract GatekeepGuard is Ownable, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor() { 
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function grantAdminRole(address newAddress_) external onlyOwner {
        _grantRole(ADMIN_ROLE, newAddress_);
    }

    function trigger721Intercept(address targetGuard, uint256 tokenId, address tokenContract) external onlyRole(ADMIN_ROLE) {
        bytes memory payload = abi.encodeWithSignature("intercept721(uint256,address)", tokenId, tokenContract);
        (bool success, bytes memory data) = address(targetGuard).call(payload);
        require(success, "intercept 721 failed");
    }

    function trigger1155Intercept(address targetGuard, uint256 tokenId, address tokenContract) external onlyRole(ADMIN_ROLE) {
        bytes memory payload = abi.encodeWithSignature("intercept1155(uint256,address)", tokenId, tokenContract);
        (bool success, bytes memory data) = address(targetGuard).call(payload);
        require(success, "intercept 1155 failed");
    }

    function trigger20Intercept(address targetGuard, address tokenContract) external onlyRole(ADMIN_ROLE) {
        bytes memory payload = abi.encodeWithSignature("intercept20(address)", tokenContract);
        (bool success, bytes memory data) = address(targetGuard).call(payload);
        require(success, "intercept 20 failed");
    }
}
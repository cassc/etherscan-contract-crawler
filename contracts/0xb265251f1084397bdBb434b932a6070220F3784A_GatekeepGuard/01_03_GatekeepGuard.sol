// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/access/Ownable.sol";

contract GatekeepGuard is Ownable {
    function trigger721Intercept(address targetGuard, uint256 tokenId, address tokenContract) external onlyOwner {
        bytes memory payload = abi.encodeWithSignature("intercept721(uint256,address)", tokenId, tokenContract);
        (bool success, bytes memory data) = address(targetGuard).call(payload);
        require(success, "intercept 721 failed");
    }

    function trigger1155Intercept(address targetGuard, uint256 tokenId, address tokenContract) external onlyOwner {
        bytes memory payload = abi.encodeWithSignature("intercept1155(uint256,address)", tokenId, tokenContract);
        (bool success, bytes memory data) = address(targetGuard).call(payload);
        require(success, "intercept 1155 failed");
    }

    function trigger20Intercept(address targetGuard, address tokenContract) external onlyOwner {
        bytes memory payload = abi.encodeWithSignature("intercept20(address)", tokenContract);
        (bool success, bytes memory data) = address(targetGuard).call(payload);
        require(success, "intercept 20 failed");
    }
}
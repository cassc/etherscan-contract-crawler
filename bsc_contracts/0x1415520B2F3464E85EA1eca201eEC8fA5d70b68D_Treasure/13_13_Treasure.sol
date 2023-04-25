// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Treasure is AccessControl {
    using SafeERC20 for IERC20;

    event WithdrawnNative(address admin, uint256 amount);
    event WithdrawnERC20(address admin, address asset, uint256 amount);
    event WithdrawnERC721(address admin, address asset, uint256 tokenId);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    receive() external payable {}
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Withdraw native currency
     * @notice ONLY ADMIN_ROLE
     * @param amount Amount of the native currency
     */
    function withdrawNative(uint256 amount) external onlyRole(ADMIN_ROLE) {
        (bool result, ) = msg.sender.call{value: amount}("");
        if (!result) revert();
        emit WithdrawnNative(msg.sender, amount);
    }

    /**
     * @dev Withdraw ERC20
     * @notice ONLY ADMIN_ROLE
     * @param asset Address of the ERC20 contract
     * @param amount Amount of the ERC20 token
     */
    function withdrawERC20(
        address asset,
        uint256 amount
    ) external onlyRole(ADMIN_ROLE) {
        IERC20(asset).safeTransfer(msg.sender, amount);
        emit WithdrawnERC20(msg.sender, asset, amount);
    }

    /**
     * @dev Withdraw ERC721
     * @notice ONLY ADMIN_ROLE
     * @param asset Address of the ERC721 contract
     * @param tokenId Token ID of the ERC721 token
     */
    function withdrawERC721(
        address asset,
        uint256 tokenId
    ) external onlyRole(ADMIN_ROLE) {
        IERC721(asset).safeTransferFrom(address(this), msg.sender, tokenId);
        emit WithdrawnERC721(msg.sender, asset, tokenId);
    }
}
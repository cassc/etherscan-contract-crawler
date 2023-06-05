// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @author MELD team
/// @title RescueTokens
/// @notice A contract that can rescue ERC20, ERC721, and ERC1155 tokens stuck in it
/// @dev This contract is abstract and must be inherited by another contract
abstract contract RescueTokens {
    using SafeERC20 for IERC20;

    /// @dev Modifier that checks that the `_token` address is not zero
    /// @param _token The address of the token
    modifier notTokenZero(address _token) {
        require(_token != address(0), "RescueTokens: Token address cannot be zero");
        _;
    }

    /// @dev Modifier that checks that the `_to` address is not zero
    /// @param _to The address to send the tokens to
    modifier notToZero(address _to) {
        require(_to != address(0), "RescueTokens: Destination address cannot be zero");
        _;
    }

    /// @notice Rescue ERC20 tokens stuck in this contract
    /// @param _token The address of the ERC20 token
    /// @param _to The address to send the ERC20 tokens to
    function _rescueERC20(
        address _token,
        address _to
    ) internal virtual notTokenZero(_token) notToZero(_to) {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance > 0, "RescueTokens: No tokens to rescue");
        IERC20(_token).safeTransfer(_to, balance);
    }

    /// @notice Rescue ERC721 tokens stuck in this contract
    /// @param _token The address of the ERC721 token
    /// @param _to The address to send the ERC721 tokens to
    /// @param _tokenId The ID of the ERC721 token
    function _rescueERC721(
        address _token,
        address _to,
        uint256 _tokenId
    ) internal virtual notTokenZero(_token) notToZero(_to) {
        require(IERC721(_token).ownerOf(_tokenId) == address(this), "RescueTokens: Not owner");
        IERC721(_token).safeTransferFrom(address(this), _to, _tokenId);
    }

    /// @notice Rescue ERC1155 tokens stuck in this contract
    /// @param _token The address of the ERC1155 token
    /// @param _to The address to send the ERC1155 tokens to
    /// @param _tokenId The ID of the ERC1155 token
    function _rescueERC1155(
        address _token,
        address _to,
        uint256 _tokenId
    ) internal virtual notTokenZero(_token) notToZero(_to) {
        uint256 balance = IERC1155(_token).balanceOf(address(this), _tokenId);
        require(balance > 0, "RescueTokens: No tokens to rescue");
        IERC1155(_token).safeTransferFrom(address(this), _to, _tokenId, balance, "");
    }
}
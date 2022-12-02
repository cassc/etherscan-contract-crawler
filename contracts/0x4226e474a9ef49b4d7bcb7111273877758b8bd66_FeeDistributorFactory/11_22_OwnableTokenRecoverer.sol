// SPDX-FileCopyrightText: 2022 P2P Validator <[email protected]>, Lido <[email protected]>
// SPDX-License-Identifier: MIT

// https://github.com/lidofinance/lido-otc-seller/blob/master/contracts/lib/AssetRecoverer.sol
pragma solidity 0.8.10;

import "./TokenRecoverer.sol";
import "../access/OwnableBase.sol";

/// @title Token Recoverer with public functions callable by assetAccessingAddress
/// @notice Recover ERC20, ERC721 and ERC1155 from a derived contract
abstract contract OwnableTokenRecoverer is TokenRecoverer, OwnableBase {
    // Functions

    /**
     * @notice transfer an ERC20 token from this contract
     * @dev `SafeERC20.safeTransfer` doesn't always return a bool
     * as it performs an internal `require` check
     * @param _token address of the ERC20 token
     * @param _recipient address to transfer the tokens to
     * @param _amount amount of tokens to transfer
     */
    function transferERC20(
        address _token,
        address _recipient,
        uint256 _amount
    ) external onlyOwner {
        _transferERC20(_token, _recipient, _amount);
    }

    /**
     * @notice transfer an ERC721 token from this contract
     * @dev `IERC721.safeTransferFrom` doesn't always return a bool
     * as it performs an internal `require` check
     * @param _token address of the ERC721 token
     * @param _recipient address to transfer the token to
     * @param _tokenId id of the individual token
     * @param _data data to transfer along
     */
    function transferERC721(
        address _token,
        address _recipient,
        uint256 _tokenId,
        bytes calldata _data
    ) external onlyOwner {
        _transferERC721(_token, _recipient, _tokenId, _data);
    }

    /**
     * @notice transfer an ERC1155 token from this contract
     * @dev see `AssetRecoverer`
     * @param _token address of the ERC1155 token that is being recovered
     * @param _recipient address to transfer the token to
     * @param _tokenId id of the individual token to transfer
     * @param _amount amount of tokens to transfer
     * @param _data data to transfer along
     */
    function transferERC1155(
        address _token,
        address _recipient,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata _data
    ) external onlyOwner {
        _transferERC1155(_token, _recipient, _tokenId, _amount, _data);
    }
}
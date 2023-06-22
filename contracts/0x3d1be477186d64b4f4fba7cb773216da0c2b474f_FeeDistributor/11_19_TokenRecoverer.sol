// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>, Lido <[email protected]>
// SPDX-License-Identifier: MIT

// https://github.com/lidofinance/lido-otc-seller/blob/master/contracts/lib/AssetRecoverer.sol
pragma solidity 0.8.10;

import {IERC20} from "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "../@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "../@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {SafeERC20} from "../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
* @notice prevents burn for transfer functions
* @dev _recipient should not be a zero address
*/
error TokenRecoverer__NoBurn();


/// @title Token Recoverer
/// @notice Recover ERC20, ERC721 and ERC1155 from a derived contract
abstract contract TokenRecoverer {
    using SafeERC20 for IERC20;

    event ERC20Transferred(address indexed _token, address indexed _recipient, uint256 _amount);
    event ERC721Transferred(address indexed _token, address indexed _recipient, uint256 _tokenId, bytes _data);
    event ERC1155Transferred(address indexed _token, address indexed _recipient, uint256 _tokenId, uint256 _amount, bytes _data);

    /**
     * @notice prevents burn for transfer functions
     * @dev checks for zero address and reverts if true
     * @param _recipient address of the transfer recipient
     */
    modifier burnDisallowed(address _recipient) {
        if (_recipient == address(0)) {
            revert TokenRecoverer__NoBurn();
        }
        _;
    }

    /**
     * @notice transfer an ERC20 token from this contract
     * @dev `SafeERC20.safeTransfer` doesn't always return a bool
     * as it performs an internal `require` check
     * @param _token address of the ERC20 token
     * @param _recipient address to transfer the tokens to
     * @param _amount amount of tokens to transfer
     */
    function _transferERC20(
        address _token,
        address _recipient,
        uint256 _amount
    ) internal virtual burnDisallowed(_recipient) {
        IERC20(_token).safeTransfer(_recipient, _amount);
        emit ERC20Transferred(_token, _recipient, _amount);
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
    function _transferERC721(
        address _token,
        address _recipient,
        uint256 _tokenId,
        bytes calldata _data
    ) internal virtual burnDisallowed(_recipient) {
        IERC721(_token).safeTransferFrom(address(this), _recipient, _tokenId, _data);
        emit ERC721Transferred(_token, _recipient, _tokenId, _data);
    }

    /**
     * @notice transfer an ERC1155 token from this contract
     * @dev `IERC1155.safeTransferFrom` doesn't always return a bool
     * as it performs an internal `require` check
     * @param _token address of the ERC1155 token that is being recovered
     * @param _recipient address to transfer the token to
     * @param _tokenId id of the individual token to transfer
     * @param _amount amount of tokens to transfer
     * @param _data data to transfer along
     */
    function _transferERC1155(
        address _token,
        address _recipient,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata _data
    ) internal virtual burnDisallowed(_recipient) {
        IERC1155(_token).safeTransferFrom(address(this), _recipient, _tokenId, _amount, _data);
        emit ERC1155Transferred(_token, _recipient, _tokenId, _amount, _data);
    }
}
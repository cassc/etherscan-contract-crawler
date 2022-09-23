// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IERC20} from "../interfaces/IERC20.sol";
import {IERC721} from "../interfaces/IERC721.sol";
import {IERC1155} from "../interfaces/IERC1155.sol";
import {ITransfer} from "../interfaces/ITransfer.sol";

/// @title Transfer
/// @author Tessera
/// @notice Reference implementation for the optimized Transfer target contract
contract TransferReference is ITransfer {
    /// @notice Transfers an ERC-20 token
    /// @param _token Address of the token
    /// @param _to Target address
    /// @param _value Transfer amount
    function ERC20Transfer(
        address _token,
        address _to,
        uint256 _value
    ) external {
        IERC20(_token).transfer(_to, _value);
    }

    /// @notice Transfers an ERC-721 token
    /// @param _token Address of the token
    /// @param _from Source address
    /// @param _to Target address
    /// @param _tokenId ID of the token
    function ERC721TransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        IERC721(_token).safeTransferFrom(_from, _to, _tokenId);
    }

    /// @notice Transfers an ERC-1155 token
    /// @param _token Address of the token
    /// @param _from Source address
    /// @param _to Target address
    /// @param _id ID of the token type
    /// @param _value Transfer amount
    function ERC1155TransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value
    ) external {
        IERC1155(_token).safeTransferFrom(_from, _to, _id, _value, "");
    }

    /// @notice Batch transfers multiple ERC-1155 tokens
    /// @param _token Address of the token
    /// @param _from Source address
    /// @param _to Target address
    /// @param _ids IDs of each token type
    /// @param _values Transfer amounts per token type
    function ERC1155BatchTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values
    ) external {
        IERC1155(_token).safeBatchTransferFrom(_from, _to, _ids, _values, "");
    }
}
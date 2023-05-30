//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IStuckTokens.sol";
import "./SafeERC20.sol";
import "../utils/Ownable.sol";

error ArrayLengthMismatch();

/**
 * @title Token Rescuer
 * @notice Allows owner to transfer out any tokens accidentally sent in.
 * @author Aaron Hanson <[email protected]> @CoffeeConverter
 */
contract TokenRescuer is Ownable {
    using SafeERC20 for IStuckERC20;

    /**
     * @notice Transfers a set of ERC20 `_token` amounts to a set of receivers.
     * @param _token The contract address of the token to be transferred.
     * @param _receivers An array of addresses to receive the tokens.
     * @param _amounts An array of token amounts to transfer to each receiver.
     */
    function rescueBatchERC20(
        address _token,
        address[] calldata _receivers,
        uint256[] calldata _amounts
    )
        external
        onlyOwner
    {
        if (_receivers.length != _amounts.length) revert ArrayLengthMismatch();
        unchecked {
            for (uint i; i < _receivers.length; i += 1) {
                _rescueERC20(_token, _receivers[i], _amounts[i]);
            }
        }
    }

    /**
     * @notice Transfers an ERC20 `_token` amount to a single receiver.
     * @param _token The contract address of the token to be transferred.
     * @param _receiver The address to receive the tokens.
     * @param _amount The token amount to transfer to the receiver.
     */
    function rescueERC20(
        address _token,
        address _receiver,
        uint256 _amount
    )
        external
        onlyOwner
    {
        _rescueERC20(_token, _receiver, _amount);
    }

    /**
     * @notice Transfers sets of ERC721 `_token` IDs to a set of receivers.
     * @param _token The contract address of the token to be transferred.
     * @param _receivers An array of addresses to receive the tokens.
     * @param _tokenIDs Arrays of token IDs to transfer to each receiver.
     */
    function rescueBatchERC721(
        address _token,
        address[] calldata _receivers,
        uint256[][] calldata _tokenIDs
    )
        external
        onlyOwner
    {
        if (_receivers.length != _tokenIDs.length) revert ArrayLengthMismatch();
        unchecked {
            for (uint i; i < _receivers.length; i += 1) {
                uint256[] memory tokenIDs = _tokenIDs[i];
                for (uint j; j < tokenIDs.length; j += 1) {
                    _rescueERC721(_token, _receivers[i], tokenIDs[j]);
                }
            }
        }
    }

    /**
     * @notice Transfers a single ERC721 `_token` token to a single receiver.
     * @param _token The contract address of the token to be transferred.
     * @param _receiver The address to receive the token.
     * @param _tokenID The token ID to transfer to the receiver.
     */
    function rescueERC721(
        address _token,
        address _receiver,
        uint256 _tokenID
    )
        external
        onlyOwner
    {
        _rescueERC721(_token, _receiver, _tokenID);
    }

    function _rescueERC20(
        address _token,
        address _receiver,
        uint256 _amount
    )
        private
    {
        IStuckERC20(_token).safeTransfer(_receiver, _amount);
    }

    function _rescueERC721(
        address _token,
        address _receiver,
        uint256 _tokenID
    )
        private
    {
        IStuckERC721(_token).safeTransferFrom(
            address(this),
            _receiver,
            _tokenID
        );
    }
}
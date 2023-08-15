//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IStuckTokens.sol";
import "./SafeERC20.sol";
import "../utils/Ownable.sol";

error ArrayLengthMismatch();

contract TokenRescuer is Ownable {
    using SafeERC20 for IStuckERC20;

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
// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>, Lido <[email protected]>
// SPDX-License-Identifier: MIT

// https://github.com/lidofinance/lido-otc-seller/blob/master/contracts/lib/AssetRecoverer.sol
pragma solidity 0.8.10;

import "./TokenRecoverer.sol";

/**
* @notice could not transfer ether
* @param _recipient address to transfer ether to
* @param _amount amount of ether to transfer
*/
error AssetRecoverer__TransferFailed(address _recipient, uint256 _amount);


/// @title Asset Recoverer
/// @notice Recover ether, ERC20, ERC721 and ERC1155 from a derived contract
abstract contract AssetRecoverer is TokenRecoverer {
    event EtherTransferred(address indexed _recipient, uint256 _amount);

    /**
     * @notice transfers ether from this contract
     * @dev using `address.call` is safer to transfer to other contracts
     * @param _recipient address to transfer ether to
     * @param _amount amount of ether to transfer
     */
    function _transferEther(address _recipient, uint256 _amount) internal virtual burnDisallowed(_recipient) {
        (bool success, ) = _recipient.call{value: _amount}("");
        if (!success) {
            revert AssetRecoverer__TransferFailed(_recipient, _amount);
        }
        emit EtherTransferred(_recipient, _amount);
    }
}
// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>, Lido <[email protected]>
// SPDX-License-Identifier: MIT

// https://github.com/lidofinance/lido-otc-seller/blob/master/contracts/lib/AssetRecoverer.sol
pragma solidity 0.8.10;

import "./OwnableTokenRecoverer.sol";
import "./AssetRecoverer.sol";

/// @title Public Asset Recoverer with public functions callable by assetAccessingAddress
/// @notice Recover ether, ERC20, ERC721 and ERC1155 from a derived contract
abstract contract OwnableAssetRecoverer is OwnableTokenRecoverer, AssetRecoverer {

    // Functions

    /**
     * @notice transfers ether from this contract
     * @dev using `address.call` is safer to transfer to other contracts
     * @param _recipient address to transfer ether to
     * @param _amount amount of ether to transfer
     */
    function transferEther(address _recipient, uint256 _amount) external onlyOwner {
        _transferEther(_recipient, _amount);
    }
}
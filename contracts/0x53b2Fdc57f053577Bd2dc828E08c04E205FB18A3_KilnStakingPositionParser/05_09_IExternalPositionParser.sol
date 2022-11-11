// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IExternalPositionParser Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for all external position parsers
interface IExternalPositionParser {
    function parseAssetsForAction(
        address _externalPosition,
        uint256 _actionId,
        bytes memory _encodedActionArgs
    )
        external
        returns (
            address[] memory assetsToTransfer_,
            uint256[] memory amountsToTransfer_,
            address[] memory assetsToReceive_
        );

    function parseInitArgs(address _vaultProxy, bytes memory _initializationData)
        external
        returns (bytes memory initArgs_);
}